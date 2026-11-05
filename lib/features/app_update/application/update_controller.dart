import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap.dart';
import '../../../core/settings/settings_providers.dart';
import '../../../core/settings/settings_repository.dart';
import '../data/apk_installer.dart';
import '../data/update_downloader.dart';
import '../data/update_repository.dart';
import '../domain/release_info.dart';
import '../domain/update_decision.dart';
import 'update_state.dart';

export 'update_state.dart';

final deviceAbisProvider = FutureProvider<List<String>>(
  (ref) async => (await DeviceInfoPlugin().androidInfo).supportedAbis,
);

final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Whether the app is on screen; Android blocks activity starts (the installer) from the background.
final appIsForegroundProvider = Provider<bool Function()>((ref) => () {
      final state = WidgetsBinding.instance.lifecycleState;
      return state == null || state == AppLifecycleState.resumed;
    });

final updateControllerProvider = NotifierProvider<UpdateController, UpdateState>(UpdateController.new);

/// Checks GitHub-published releases and walks the user through download,
/// verification and Android's install confirmation (design §12.3).
class UpdateController extends Notifier<UpdateState> {
  static const resumeInterval = Duration(hours: 6);

  bool _launchChecked = false;
  bool _working = false;
  Future<void>? _inFlight;
  final Set<int> _dismissedBuilds = {};

  @override
  UpdateState build() => const UpdateIdle();

  SettingsRepository get _settings => ref.read(settingsRepositoryProvider);
  int get _currentBuild => int.tryParse(ref.read(packageInfoProvider).buildNumber) ?? 0;
  DateTime _now() => ref.read(clockProvider)();

  Future<void> check(UpdateTrigger trigger) async {
    final manual = trigger == UpdateTrigger.manual;
    switch (trigger) {
      case UpdateTrigger.launch:
        if (_launchChecked) return;
        _launchChecked = true;
      case UpdateTrigger.resume:
        final last = _settings.lastUpdateCheck;
        if (last != null && _now().difference(last) < resumeInterval) return;
      case UpdateTrigger.manual:
        break;
    }
    // Automatic checks never interrupt something already on screen.
    if (!manual && state is! UpdateIdle && state is! UpdateUpToDate) return;
    if (_working) return;
    // A check already running (e.g. launch, then a quick resume) is shared, never duplicated.
    final running = _inFlight;
    if (running != null) return running;
    final check = _runCheck(manual);
    _inFlight = check;
    try {
      await check;
    } finally {
      _inFlight = null;
    }
  }

  Future<void> _runCheck(bool manual) async {
    if (manual) state = const UpdateChecking();
    try {
      final latest = await ref.read(updateRepositoryProvider).fetchLatest();
      final abis = await ref.read(deviceAbisProvider.future);
      final decision = decideUpdate(currentBuild: _currentBuild, deviceAbis: abis, latest: latest);
      await _settings.setLastUpdateCheck(_now());
      if (decision.kind == UpdateKind.none) {
        state = manual ? const UpdateUpToDate() : const UpdateIdle();
      } else if (decision.kind == UpdateKind.optional && !manual && _dismissedBuilds.contains(decision.release!.build)) {
        state = const UpdateIdle();
      } else {
        state = UpdateAvailable(decision);
      }
    } on Object {
      state = manual ? const UpdateFailed(null, UpdateFailure.checkFailed) : const UpdateIdle();
    }
  }

  Future<void> startUpdate() async {
    final current = state;
    if (current is UpdateReadyToInstall) {
      await _installNow(current);
      return;
    }
    final decision = switch (current) {
      UpdateAvailable(:final decision) || UpdateInstallNotCompleted(:final decision) => decision,
      UpdateFailed(decision: final UpdateDecision decision) => decision,
      _ => null,
    };
    if (decision == null || _working) return;
    _working = true;
    try {
      if (!await ref.read(apkInstallerProvider).canInstallPackages()) {
        state = UpdateNeedsPermission(decision);
        return;
      }
      await _downloadAndInstall(decision);
    } finally {
      _working = false;
    }
  }

  /// The user tapped "Open settings" to allow installs; continue if they did.
  Future<void> grantPermissionAndContinue() async {
    final current = state;
    if (current is! UpdateNeedsPermission || _working) return;
    _working = true;
    try {
      final granted = await ref.read(apkInstallerProvider).openInstallPermissionSettings();
      if (!granted) {
        state = UpdateFailed(current.decision, UpdateFailure.permissionDenied);
        return;
      }
      await _downloadAndInstall(current.decision);
    } finally {
      _working = false;
    }
  }

  /// "Later": hides an optional update for the rest of this app run. Mandatory updates stay.
  void later() {
    final decision = decisionOf(state);
    if (decision == null || decision.kind != UpdateKind.optional || _working) return;
    _dismissedBuilds.add(decision.release!.build);
    state = const UpdateIdle();
  }

  Future<void> onResumed() async {
    final current = state;
    if (current is UpdateReadyToInstall) {
      if (ref.read(appIsForegroundProvider)()) await _installNow(current);
      return;
    }
    if (current is UpdateInstalling) {
      final pending = _pendingRelease();
      if (pending != null && pending.build > _currentBuild) state = UpdateInstallNotCompleted(current.decision);
    }
    await check(UpdateTrigger.resume);
  }

  /// The release just installed (shown once as "What's new"), or null.
  ReleaseInfo? consumeJustUpdatedRelease() {
    final settings = _settings;
    final current = _currentBuild;
    final pending = _pendingRelease();
    if (pending != null && pending.build <= current) unawaited(settings.setPendingUpdateJson(null));
    // Downloaded APKs are kept only while a newer build is still waiting to be installed.
    if (pending == null || pending.build <= current) unawaited(ref.read(updateDownloaderProvider).clear());
    if (settings.lastSeenBuild != current) unawaited(settings.setLastSeenBuild(current));
    return pending != null && pending.build == current ? pending : null;
  }

  Future<void> _downloadAndInstall(UpdateDecision decision) async {
    final asset = decision.asset!;
    state = UpdateDownloading(decision, received: 0, total: asset.size);
    final File apk;
    try {
      apk = await ref.read(updateDownloaderProvider).download(
        asset,
        onProgress: (received, total) => state = received >= total
            ? UpdateVerifying(decision)
            : UpdateDownloading(decision, received: received, total: total),
      );
    } on UpdateIntegrityException {
      state = UpdateFailed(decision, UpdateFailure.integrityFailed);
      return;
    } on Object {
      // UpdateDownloadException or anything unexpected: never leave the dialog stuck.
      state = UpdateFailed(decision, UpdateFailure.downloadFailed);
      return;
    }
    await _settings.setPendingUpdateJson(jsonEncode(decision.release!.toJson()));
    if (!ref.read(appIsForegroundProvider)()) {
      state = UpdateReadyToInstall(decision, apk);
      return;
    }
    await _install(decision, apk);
  }

  Future<void> _installNow(UpdateReadyToInstall ready) async {
    if (_working) return;
    _working = true;
    try {
      await _install(ready.decision, ready.apk);
    } finally {
      _working = false;
    }
  }

  Future<void> _install(UpdateDecision decision, File apk) async {
    try {
      await ref.read(apkInstallerProvider).install(apk);
      state = UpdateInstalling(decision);
    } on Object {
      state = UpdateFailed(decision, UpdateFailure.installFailed);
    }
  }

  ReleaseInfo? _pendingRelease() {
    final raw = _settings.pendingUpdateJson;
    if (raw == null) return null;
    try {
      return parseReleaseInfo(jsonDecode(raw) as Map<String, Object?>);
    } on Object {
      return null;
    }
  }
}
