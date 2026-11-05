import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:anuvaad/app/bootstrap.dart';
import 'package:anuvaad/core/settings/settings_providers.dart';
import 'package:anuvaad/features/app_update/application/update_controller.dart';
import 'package:anuvaad/features/app_update/data/apk_installer.dart';
import 'package:anuvaad/features/app_update/data/update_downloader.dart';
import 'package:anuvaad/features/app_update/data/update_repository.dart';
import 'package:anuvaad/features/app_update/domain/release_info.dart';
import 'package:anuvaad/features/app_update/domain/update_decision.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockRepository extends Mock implements UpdateRepository {}

class _MockDownloader extends Mock implements UpdateDownloader {}

class _MockInstaller extends Mock implements ApkInstaller {}

ReleaseInfo _release({int build = 2, bool mandatory = false, int minSupportedBuild = 1}) => ReleaseInfo(
      schema: 1,
      version: '0.1.$build',
      build: build,
      publishedAt: DateTime.utc(2026, 11, 12),
      mandatory: mandatory,
      minSupportedBuild: minSupportedBuild,
      notes: const ReleaseNotes(whatsNew: ['Release notes history'], fixed: []),
      assets: [
        ApkAsset(
          abi: 'arm64-v8a',
          file: 'anuvaad-0.1.$build-arm64-v8a.apk',
          url: Uri.parse('https://example.com/anuvaad-0.1.$build-arm64-v8a.apk'),
          size: 200,
          sha256: 'a' * 64,
        ),
      ],
      releaseUrl: Uri.parse('https://example.com/v0.1.$build'),
    );

void main() {
  late _MockRepository repo;
  late _MockDownloader downloader;
  late _MockInstaller installer;
  late SharedPreferences prefs;
  late DateTime now;
  late bool foreground;
  final apk = File('/cache/updates/anuvaad-0.1.2-arm64-v8a.apk');

  setUpAll(() {
    registerFallbackValue(_release().assets.first);
    registerFallbackValue(File(''));
  });

  setUp(() async {
    repo = _MockRepository();
    downloader = _MockDownloader();
    installer = _MockInstaller();
    now = DateTime.utc(2026, 11, 20, 9);
    foreground = true;
    when(() => downloader.clear()).thenAnswer((_) async {});
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    when(() => installer.canInstallPackages()).thenAnswer((_) async => true);
    when(() => installer.install(any())).thenAnswer((_) async {});
    when(() => downloader.download(any(), onProgress: any(named: 'onProgress'), cancelToken: any(named: 'cancelToken')))
        .thenAnswer((invocation) async {
      final onProgress = invocation.namedArguments[#onProgress] as void Function(int, int);
      onProgress(100, 200);
      onProgress(200, 200);
      return apk;
    });
  });

  ProviderContainer container({String build = '1'}) {
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      packageInfoProvider.overrideWithValue(
        PackageInfo(appName: 'Anuvaad', packageName: 'app.anuvaad', version: '0.1.$build', buildNumber: build),
      ),
      deviceAbisProvider.overrideWith((ref) async => ['arm64-v8a', 'armeabi-v7a']),
      clockProvider.overrideWithValue(() => now),
      appIsForegroundProvider.overrideWithValue(() => foreground),
      updateRepositoryProvider.overrideWithValue(repo),
      updateDownloaderProvider.overrideWithValue(downloader),
      apkInstallerProvider.overrideWithValue(installer),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  UpdateController controller(ProviderContainer c) => c.read(updateControllerProvider.notifier);

  test('launch check shows Available for a newer build', () async {
    when(() => repo.fetchLatest()).thenAnswer((_) async => _release(build: 2));
    final c = container();
    await controller(c).check(UpdateTrigger.launch);
    final state = c.read(updateControllerProvider);
    expect(state, isA<UpdateAvailable>());
    expect((state as UpdateAvailable).decision.kind, UpdateKind.optional);
    expect(SettingsRepositoryHarness(prefs).lastUpdateCheck, now);
  });

  test('launch check runs only once per process', () async {
    when(() => repo.fetchLatest()).thenAnswer((_) async => null);
    final c = container();
    await controller(c).check(UpdateTrigger.launch);
    await controller(c).check(UpdateTrigger.launch);
    verify(() => repo.fetchLatest()).called(1);
  });

  test('resume check skipped within 6 hours', () async {
    when(() => repo.fetchLatest()).thenAnswer((_) async => null);
    final c = container();
    await prefs.setString('last_update_check', now.subtract(const Duration(hours: 5)).toIso8601String());
    await controller(c).check(UpdateTrigger.resume);
    verifyNever(() => repo.fetchLatest());

    await prefs.setString('last_update_check', now.subtract(const Duration(hours: 7)).toIso8601String());
    await controller(c).check(UpdateTrigger.resume);
    verify(() => repo.fetchLatest()).called(1);
  });

  test('manual check with no update gives UpToDate', () async {
    when(() => repo.fetchLatest()).thenAnswer((_) async => _release(build: 1));
    final c = container();
    await controller(c).check(UpdateTrigger.manual);
    expect(c.read(updateControllerProvider), isA<UpdateUpToDate>());
  });

  test('launch failure stays Idle; manual failure gives Failed(checkFailed)', () async {
    when(() => repo.fetchLatest()).thenThrow(const UpdateCheckException('offline'));
    final c = container();
    await controller(c).check(UpdateTrigger.launch);
    expect(c.read(updateControllerProvider), isA<UpdateIdle>());
    expect(prefs.getString('last_update_check'), isNull);

    await controller(c).check(UpdateTrigger.manual);
    final state = c.read(updateControllerProvider) as UpdateFailed;
    expect(state.failure, UpdateFailure.checkFailed);
    expect(state.decision, isNull);
  });

  test('Later hides the same optional build for this process; manual check shows it again', () async {
    when(() => repo.fetchLatest()).thenAnswer((_) async => _release(build: 2));
    final c = container();
    await controller(c).check(UpdateTrigger.launch);
    controller(c).later();
    expect(c.read(updateControllerProvider), isA<UpdateIdle>());

    now = now.add(const Duration(hours: 7));
    await controller(c).check(UpdateTrigger.resume);
    expect(c.read(updateControllerProvider), isA<UpdateIdle>());

    await controller(c).check(UpdateTrigger.manual);
    expect(c.read(updateControllerProvider), isA<UpdateAvailable>());
  });

  test('mandatory update cannot be dismissed', () async {
    when(() => repo.fetchLatest()).thenAnswer((_) async => _release(build: 3, minSupportedBuild: 2));
    final c = container();
    await controller(c).check(UpdateTrigger.launch);
    controller(c).later();
    final state = c.read(updateControllerProvider) as UpdateAvailable;
    expect(state.decision.kind, UpdateKind.mandatory);
  });

  test('happy path downloads, records the pending release and opens the installer', () async {
    when(() => repo.fetchLatest()).thenAnswer((_) async => _release(build: 2));
    final c = container();
    final seen = <Type>[];
    c.listen(updateControllerProvider, (_, next) => seen.add(next.runtimeType), fireImmediately: false);
    await controller(c).check(UpdateTrigger.launch);
    await controller(c).startUpdate();

    expect(seen, containsAllInOrder([UpdateAvailable, UpdateDownloading, UpdateVerifying, UpdateInstalling]));
    verify(() => installer.install(apk)).called(1);
    final pending = jsonDecode(prefs.getString('pending_update')!) as Map<String, Object?>;
    expect(pending['build'], 2);
  });

  test('startUpdate without install permission asks via NeedsPermission and does not auto-request', () async {
    when(() => repo.fetchLatest()).thenAnswer((_) async => _release(build: 2));
    when(() => installer.canInstallPackages()).thenAnswer((_) async => false);
    final c = container();
    await controller(c).check(UpdateTrigger.launch);
    await controller(c).startUpdate();
    expect(c.read(updateControllerProvider), isA<UpdateNeedsPermission>());
    verifyNever(() => installer.openInstallPermissionSettings());
    verifyNever(() => downloader.download(any(), onProgress: any(named: 'onProgress'), cancelToken: any(named: 'cancelToken')));
  });

  test('granted permission continues to download and install', () async {
    when(() => repo.fetchLatest()).thenAnswer((_) async => _release(build: 2));
    when(() => installer.canInstallPackages()).thenAnswer((_) async => false);
    when(() => installer.openInstallPermissionSettings()).thenAnswer((_) async => true);
    final c = container();
    await controller(c).check(UpdateTrigger.launch);
    await controller(c).startUpdate();
    await controller(c).grantPermissionAndContinue();
    expect(c.read(updateControllerProvider), isA<UpdateInstalling>());
    verify(() => installer.install(apk)).called(1);
  });

  test('denied permission gives Failed(permissionDenied)', () async {
    when(() => repo.fetchLatest()).thenAnswer((_) async => _release(build: 2));
    when(() => installer.canInstallPackages()).thenAnswer((_) async => false);
    when(() => installer.openInstallPermissionSettings()).thenAnswer((_) async => false);
    final c = container();
    await controller(c).check(UpdateTrigger.launch);
    await controller(c).startUpdate();
    await controller(c).grantPermissionAndContinue();
    final state = c.read(updateControllerProvider) as UpdateFailed;
    expect(state.failure, UpdateFailure.permissionDenied);
    expect(state.decision, isNotNull);
  });

  test('startUpdate is single-flight', () async {
    when(() => repo.fetchLatest()).thenAnswer((_) async => _release(build: 2));
    final c = container();
    await controller(c).check(UpdateTrigger.launch);
    await Future.wait([controller(c).startUpdate(), controller(c).startUpdate()]);
    verify(() => downloader.download(any(), onProgress: any(named: 'onProgress'), cancelToken: any(named: 'cancelToken')))
        .called(1);
  });

  test('integrity failure gives Failed(integrityFailed) and never installs', () async {
    when(() => repo.fetchLatest()).thenAnswer((_) async => _release(build: 2));
    when(() => downloader.download(any(), onProgress: any(named: 'onProgress'), cancelToken: any(named: 'cancelToken')))
        .thenThrow(const UpdateIntegrityException('bad checksum'));
    final c = container();
    await controller(c).check(UpdateTrigger.launch);
    await controller(c).startUpdate();
    expect((c.read(updateControllerProvider) as UpdateFailed).failure, UpdateFailure.integrityFailed);
    verifyNever(() => installer.install(any()));
  });

  test('download and installer failures are reported', () async {
    when(() => repo.fetchLatest()).thenAnswer((_) async => _release(build: 2));
    when(() => downloader.download(any(), onProgress: any(named: 'onProgress'), cancelToken: any(named: 'cancelToken')))
        .thenThrow(const UpdateDownloadException('offline'));
    final c = container();
    await controller(c).check(UpdateTrigger.launch);
    await controller(c).startUpdate();
    expect((c.read(updateControllerProvider) as UpdateFailed).failure, UpdateFailure.downloadFailed);

    when(() => downloader.download(any(), onProgress: any(named: 'onProgress'), cancelToken: any(named: 'cancelToken')))
        .thenAnswer((_) async => apk);
    when(() => installer.install(any())).thenThrow(const UpdateInstallException('no installer'));
    await controller(c).startUpdate();
    expect((c.read(updateControllerProvider) as UpdateFailed).failure, UpdateFailure.installFailed);
  });

  test('resume after install attempt with unchanged build gives InstallNotCompleted', () async {
    when(() => repo.fetchLatest()).thenAnswer((_) async => _release(build: 2));
    final c = container();
    await controller(c).check(UpdateTrigger.launch);
    await controller(c).startUpdate();
    expect(c.read(updateControllerProvider), isA<UpdateInstalling>());

    await controller(c).onResumed();
    expect(c.read(updateControllerProvider), isA<UpdateInstallNotCompleted>());
  });

  test('first launch after update returns the release exactly once', () async {
    await prefs.setString('pending_update', jsonEncode(_release(build: 2).toJson()));
    await prefs.setInt('last_seen_build', 1);
    final c = container(build: '2');
    final release = controller(c).consumeJustUpdatedRelease();
    expect(release!.version, '0.1.2');
    expect(controller(c).consumeJustUpdatedRelease(), isNull);
    expect(prefs.getInt('last_seen_build'), 2);
    expect(prefs.getString('pending_update'), isNull);
  });

  test('a fresh install records its build without showing What is new', () async {
    final c = container(build: '1');
    expect(controller(c).consumeJustUpdatedRelease(), isNull);
    expect(prefs.getInt('last_seen_build'), 1);
  });

  test('a resume check while the launch check is running reuses it', () async {
    final pending = Completer<ReleaseInfo?>();
    when(() => repo.fetchLatest()).thenAnswer((_) => pending.future);
    final c = container();
    final launch = controller(c).check(UpdateTrigger.launch);
    final resume = controller(c).check(UpdateTrigger.resume);
    pending.complete(_release(build: 2));
    await Future.wait([launch, resume]);
    verify(() => repo.fetchLatest()).called(1);
    expect(c.read(updateControllerProvider), isA<UpdateAvailable>());
  });

  test('an unexpected download error ends in Failed(downloadFailed), never a stuck dialog', () async {
    when(() => repo.fetchLatest()).thenAnswer((_) async => _release(build: 2));
    when(() => downloader.download(any(), onProgress: any(named: 'onProgress'), cancelToken: any(named: 'cancelToken')))
        .thenThrow(StateError('cache directory unavailable'));
    final c = container();
    await controller(c).check(UpdateTrigger.launch);
    await controller(c).startUpdate();
    expect((c.read(updateControllerProvider) as UpdateFailed).failure, UpdateFailure.downloadFailed);
  });

  test('an unexpected installer error ends in Failed(installFailed)', () async {
    when(() => repo.fetchLatest()).thenAnswer((_) async => _release(build: 2));
    when(() => installer.install(any())).thenThrow(MissingPluginException('no installer channel'));
    final c = container();
    await controller(c).check(UpdateTrigger.launch);
    await controller(c).startUpdate();
    expect((c.read(updateControllerProvider) as UpdateFailed).failure, UpdateFailure.installFailed);
  });

  test('a download that finishes in the background waits for the app to return before opening the installer', () async {
    when(() => repo.fetchLatest()).thenAnswer((_) async => _release(build: 2));
    final c = container();
    await controller(c).check(UpdateTrigger.launch);
    foreground = false;
    await controller(c).startUpdate();
    expect(c.read(updateControllerProvider), isA<UpdateReadyToInstall>());
    verifyNever(() => installer.install(any()));

    foreground = true;
    await controller(c).onResumed();
    verify(() => installer.install(apk)).called(1);
    expect(c.read(updateControllerProvider), isA<UpdateInstalling>());
  });

  test('first launch after an update clears downloaded APKs', () async {
    await prefs.setString('pending_update', jsonEncode(_release(build: 2).toJson()));
    final c = container(build: '2');
    controller(c).consumeJustUpdatedRelease();
    await pumpEventQueue();
    verify(() => downloader.clear()).called(1);
  });

  test('a pending newer build keeps its downloaded APK for a retry', () async {
    await prefs.setString('pending_update', jsonEncode(_release(build: 3).toJson()));
    final c = container(build: '2');
    controller(c).consumeJustUpdatedRelease();
    await pumpEventQueue();
    verifyNever(() => downloader.clear());
  });
}

/// Reads persisted values the same way the app does.
class SettingsRepositoryHarness {
  SettingsRepositoryHarness(this.prefs);
  final SharedPreferences prefs;
  DateTime? get lastUpdateCheck {
    final raw = prefs.getString('last_update_check');
    return raw == null ? null : DateTime.parse(raw);
  }
}
