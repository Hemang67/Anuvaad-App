import 'package:anuvaad/core/permissions/microphone_permission.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _channel = MethodChannel('flutter.baseflow.com/permissions/methods');
const _microphone = 7; // Permission.microphone

// permission_handler status codes: denied 0, granted 1, restricted 2, limited 3, permanentlyDenied 4, provisional 5.
const _expected = {
  0: MicPermission.denied,
  1: MicPermission.granted,
  2: MicPermission.permanentlyDenied,
  3: MicPermission.granted,
  4: MicPermission.permanentlyDenied,
  5: MicPermission.denied,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;
  late int platformStatus;

  setUp(() {
    calls = [];
    messenger.setMockMethodCallHandler(_channel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'checkPermissionStatus' => platformStatus,
        'requestPermissions' => {_microphone: platformStatus},
        'openAppSettings' => true,
        _ => null,
      };
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(_channel, null));

  test('maps each PermissionStatus to MicPermission for status and request', () async {
    final permission = PermissionHandlerMicrophone();
    for (final MapEntry(key: code, value: expected) in _expected.entries) {
      platformStatus = code;
      expect(await permission.status(), expected, reason: 'status $code');
      expect(await permission.request(), expected, reason: 'request $code');
    }
    expect(calls.where((c) => c.method == 'checkPermissionStatus').first.arguments, _microphone);
    expect(calls.where((c) => c.method == 'requestPermissions').first.arguments, [_microphone]);
  });

  test('openSettings opens the app settings', () async {
    expect(await PermissionHandlerMicrophone().openSettings(), isTrue);
    expect(calls.single.method, 'openAppSettings');
  });
}
