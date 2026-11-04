import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class UpdateInstallException implements Exception {
  const UpdateInstallException(this.message);
  final String message;

  @override
  String toString() => 'UpdateInstallException: $message';
}

/// Hands a verified APK to Android's package installer, which always asks the user to confirm.
abstract interface class ApkInstaller {
  /// Whether "Install unknown apps" is allowed for Anuvaad.
  Future<bool> canInstallPackages();

  /// Opens the system setting for "Install unknown apps"; true if allowed on return.
  Future<bool> openInstallPermissionSettings();

  Future<void> install(File apk);
}

class AndroidApkInstaller implements ApkInstaller {
  static const _channel = MethodChannel('app.anuvaad/installer');

  @override
  Future<bool> canInstallPackages() => Permission.requestInstallPackages.isGranted;

  @override
  Future<bool> openInstallPermissionSettings() async => (await Permission.requestInstallPackages.request()).isGranted;

  @override
  Future<void> install(File apk) async {
    try {
      await _channel.invokeMethod<void>('installApk', {'path': apk.path});
    } on PlatformException catch (e) {
      throw UpdateInstallException(e.message ?? e.code);
    }
  }
}

final apkInstallerProvider = Provider<ApkInstaller>((ref) => AndroidApkInstaller());
