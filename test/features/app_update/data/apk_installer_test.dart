import 'dart:io';

import 'package:anuvaad/features/app_update/data/apk_installer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('app.anuvaad/installer');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('install sends the APK path over app.anuvaad/installer', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });

    await AndroidApkInstaller().install(File('/data/user/0/app.anuvaad/cache/updates/a.apk'));

    expect(calls.single.method, 'installApk');
    expect(calls.single.arguments, {'path': '/data/user/0/app.anuvaad/cache/updates/a.apk'});
  });

  test('PlatformException becomes UpdateInstallException', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'install_failed', message: 'No activity found to handle Intent');
    });

    await expectLater(
      AndroidApkInstaller().install(File('/cache/updates/a.apk')),
      throwsA(isA<UpdateInstallException>().having((e) => e.message, 'message', 'No activity found to handle Intent')),
    );
  });
}
