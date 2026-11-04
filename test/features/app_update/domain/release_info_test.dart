import 'dart:convert';
import 'dart:io';

import 'package:anuvaad/features/app_update/domain/release_info.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> fixture() =>
    jsonDecode(File('test/fixtures/release_0_1_1.json').readAsStringSync()) as Map<String, Object?>;

Map<String, Object?> withAsset0(Map<String, Object?> json, String key, Object? value) {
  final assets = (json['assets']! as List<Object?>).cast<Map<String, Object?>>();
  assets[0] = {...assets[0], key: value};
  return {...json, 'assets': assets};
}

void main() {
  test('parses the contract fixture', () {
    final info = parseReleaseInfo(fixture());
    expect(info.version, '0.1.1');
    expect(info.build, 2);
    expect(info.publishedAt, DateTime.utc(2026, 11, 12, 10));
    expect(info.mandatory, isFalse);
    expect(info.minSupportedBuild, 1);
    expect(info.notes.whatsNew, ['Release notes history in Settings.']);
    expect(info.assets.map((a) => a.abi), ['arm64-v8a', 'armeabi-v7a', 'x86_64', 'universal']);
    expect(info.assets.first.url.toString(),
        'https://github.com/test/anuvaad-app/releases/download/v0.1.1/anuvaad-0.1.1-arm64-v8a.apk');
    expect(info.assets.first.sha256, '673611a97e40493b3f7ca1074b145668f2183308d8c28e29d273a1012544bc19');
    expect(info.releaseUrl.toString(), 'https://github.com/test/anuvaad-app/releases/tag/v0.1.1');
  });

  final invalidCases = <String, Map<String, Object?> Function(Map<String, Object?>)>{
    'schema 2': (j) => {...j, 'schema': 2},
    'version without three numbers': (j) => {...j, 'version': 'v1'},
    'build 0': (j) => {...j, 'build': 0, 'minSupportedBuild': 0},
    'minSupportedBuild above build': (j) => {...j, 'minSupportedBuild': 3},
    'missing assets': (j) => {...j}..remove('assets'),
    'empty assets': (j) => {...j, 'assets': <Object?>[]},
    'unknown abi': (j) => withAsset0(j, 'abi', 'mips'),
    'file not an apk': (j) => withAsset0(j, 'file', 'anuvaad.zip'),
    'size 0': (j) => withAsset0(j, 'size', 0),
    'short sha256': (j) => withAsset0(j, 'sha256', 'abc'),
    'uppercase sha256': (j) => withAsset0(j, 'sha256', '673611A97E40493B3F7CA1074B145668F2183308D8C28E29D273A1012544BC19'),
    'http url': (j) => withAsset0(j, 'url', 'http://example.com/a.apk'),
    'no notes at all': (j) => {...j, 'notes': {'whatsNew': <Object?>[], 'fixed': <Object?>[]}},
    'blank note': (j) => {...j, 'notes': {'whatsNew': ['  '], 'fixed': <Object?>[]}},
    'note of the wrong type': (j) => {...j, 'notes': {'whatsNew': [42], 'fixed': <Object?>[]}},
    'bad publishedAt': (j) => {...j, 'publishedAt': 'yesterday'},
  };
  invalidCases.forEach((name, mutate) {
    test('rejects $name', () => expect(() => parseReleaseInfo(mutate(fixture())), throwsFormatException));
  });

  test('round-trips through JSON for the pending-update record', () {
    final info = parseReleaseInfo(fixture());
    final again = parseReleaseInfo(jsonDecode(jsonEncode(info.toJson())) as Map<String, Object?>);
    expect(again, info);
  });
}
