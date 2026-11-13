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
}
