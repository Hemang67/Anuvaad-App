import 'dart:io';

import '../domain/update_decision.dart';

enum UpdateTrigger { launch, resume, manual }

enum UpdateFailure { checkFailed, downloadFailed, integrityFailed, permissionDenied, installFailed }

sealed class UpdateState {
  const UpdateState();
}

final class UpdateIdle extends UpdateState {
  const UpdateIdle();
}

final class UpdateChecking extends UpdateState {
  const UpdateChecking();
}

/// Only after a manual check.
final class UpdateUpToDate extends UpdateState {
  const UpdateUpToDate();
}

final class UpdateAvailable extends UpdateState {
  const UpdateAvailable(this.decision);
  final UpdateDecision decision;
}

final class UpdateDownloading extends UpdateState {
  const UpdateDownloading(this.decision, {required this.received, required this.total});
  final UpdateDecision decision;
  final int received;
  final int total;
}

final class UpdateVerifying extends UpdateState {
  const UpdateVerifying(this.decision);
  final UpdateDecision decision;
}

final class UpdateNeedsPermission extends UpdateState {
  const UpdateNeedsPermission(this.decision);
  final UpdateDecision decision;
}

/// Verified and waiting for the app to return to the foreground before opening the installer.
final class UpdateReadyToInstall extends UpdateState {
  const UpdateReadyToInstall(this.decision, this.apk);
  final UpdateDecision decision;
  final File apk;
}

final class UpdateInstalling extends UpdateState {
  const UpdateInstalling(this.decision);
  final UpdateDecision decision;
}

final class UpdateInstallNotCompleted extends UpdateState {
  const UpdateInstallNotCompleted(this.decision);
  final UpdateDecision decision;
}

final class UpdateFailed extends UpdateState {
  const UpdateFailed(this.decision, this.failure);
  final UpdateDecision? decision;
  final UpdateFailure failure;
}

/// The decision a state carries, if any.
UpdateDecision? decisionOf(UpdateState state) => switch (state) {
      UpdateAvailable(:final decision) ||
      UpdateDownloading(:final decision) ||
      UpdateVerifying(:final decision) ||
      UpdateNeedsPermission(:final decision) ||
      UpdateReadyToInstall(:final decision) ||
      UpdateInstalling(:final decision) ||
      UpdateInstallNotCompleted(:final decision) =>
        decision,
      UpdateFailed(:final decision) => decision,
      UpdateIdle() || UpdateChecking() || UpdateUpToDate() => null,
    };
