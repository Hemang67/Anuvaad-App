import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

enum MicPermission {
  granted,

  /// Not granted yet; asking may show Android's dialog.
  denied,

  /// Asking won't show a dialog any more; only the app's system settings can change it.
  permanentlyDenied,
}

/// The microphone runtime permission, asked just in time (first Listen or Speak).
abstract interface class MicrophonePermission {
  Future<MicPermission> status();
  Future<MicPermission> request();
  Future<bool> openSettings();
}

class PermissionHandlerMicrophone implements MicrophonePermission {
  // On Android a status check never says "permanently denied"; only a request does (immediately, no dialog).
  static MicPermission _map(PermissionStatus status) => switch (status) {
        PermissionStatus.granted || PermissionStatus.limited => MicPermission.granted,
        PermissionStatus.permanentlyDenied || PermissionStatus.restricted => MicPermission.permanentlyDenied,
        PermissionStatus.denied || PermissionStatus.provisional => MicPermission.denied,
      };

  @override
  Future<MicPermission> status() async => _map(await Permission.microphone.status);

  @override
  Future<MicPermission> request() async => _map(await Permission.microphone.request());

  @override
  Future<bool> openSettings() => openAppSettings();
}

final microphonePermissionProvider = Provider<MicrophonePermission>((ref) => PermissionHandlerMicrophone());
