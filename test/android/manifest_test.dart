import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('saved conversations and the latency log are kept out of Android backups (I3)', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, contains('android:dataExtractionRules="@xml/data_extraction_rules"'));
    final rules = File('android/app/src/main/res/xml/data_extraction_rules.xml').readAsStringSync();
    expect(rules, contains('<cloud-backup>'));
    expect(rules, contains('<device-transfer>'));
    for (final domain in ['file', 'database', 'sharedpref', 'root']) {
      expect(RegExp('<exclude domain="$domain" path="\\."').allMatches(rules).length, 2,
          reason: '$domain is excluded from both cloud backup and device transfer');
    }
  });

  test('the conversation service may keep the microphone with the screen off, and nothing else', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    for (final permission in ['FOREGROUND_SERVICE', 'FOREGROUND_SERVICE_MICROPHONE', 'POST_NOTIFICATIONS', 'WAKE_LOCK']) {
      expect(manifest, contains('<uses-permission android:name="android.permission.$permission" />'));
    }
    final service = RegExp(r'<service[^>]*ConversationService[^>]*>', dotAll: true).stringMatch(manifest);
    expect(service, isNotNull);
    expect(service, contains('android:foregroundServiceType="microphone"'));
    expect(service, contains('android:exported="false"'));
    expect(manifest, isNot(contains('FOREGROUND_SERVICE_LOCATION')));
    expect(manifest, isNot(contains('FOREGROUND_SERVICE_CAMERA')));
  });
}
