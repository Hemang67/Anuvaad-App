import 'dart:convert';
import 'dart:io';

import 'package:anuvaad/features/app_update/domain/release_info.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/release/changelog.dart';
import '../../tool/release/manifest.dart';
import '../../tool/release/prepare_release.dart';

const _abis = ['arm64-v8a', 'armeabi-v7a', 'x86_64', 'universal'];

ChangelogEntry _entry({int build = 2, int minSupportedBuild = 1}) => ChangelogEntry(
      version: '0.1.1',
      build: build,
      date: DateTime.utc(2026, 11, 12),
      mandatory: false,
      minSupportedBuild: minSupportedBuild,
      whatsNew: const ['Release notes history in Settings.'],
      fixed: const [],
      notesMarkdown: "### What's new\n- Release notes history in Settings.\n",
    );

void main() {
  test('manifest round-trips through the app parser', () {
    final manifest = buildReleaseManifest(
      entry: _entry(),
      publishedAt: DateTime.utc(2026, 11, 12, 10),
      apks: [
        for (final abi in _abis.reversed) ApkFileInfo(abi: abi, file: 'anuvaad-0.1.1-$abi.apk', size: 1000, sha256: 'c' * 64),
      ],
    );
    expect(manifest['publishedAt'], '2026-11-12T10:00:00Z');
    expect((manifest['assets']! as List<Object?>).map((a) => (a! as Map<String, Object?>)['abi']), _abis);

    final withUrls = jsonDecode(jsonEncode(manifest)) as Map<String, Object?>;
    withUrls['assets'] = [
      for (final a in (withUrls['assets']! as List<Object?>).cast<Map<String, Object?>>())
        {...a, 'url': 'https://github.com/o/r/releases/download/v0.1.1/${a['file']}'},
    ];
    withUrls['releaseUrl'] = 'https://github.com/o/r/releases/tag/v0.1.1';
    final info = parseReleaseInfo(withUrls);
    expect(info.build, 2);
    expect(info.notes.whatsNew, ['Release notes history in Settings.']);
  });

  test('rejects a min supported build above the build', () {
    expect(
      () => buildReleaseManifest(entry: _entry(build: 2, minSupportedBuild: 3), publishedAt: DateTime.utc(2026), apks: const []),
      throwsStateError,
    );
  });

  group('prepareRelease', () {
    late Directory root;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('anuvaad_release_');
      File('${root.path}/pubspec.yaml').writeAsStringSync('name: anuvaad\nversion: 0.1.1+2\n');
      File('${root.path}/CHANGELOG.md').writeAsStringSync(
        "# Changelog\n\n## 0.1.1 (2) — 2026-11-12\n### What's new\n- Release notes history in Settings.\n",
      );
      Directory('${root.path}/build/release/apks').createSync(recursive: true);
    });
    tearDown(() => root.delete(recursive: true));

    void writeApks(List<String> abis) {
      for (final abi in abis) {
        File('${root.path}/build/release/apks/anuvaad-0.1.1-$abi.apk').writeAsStringSync('apk for $abi');
      }
    }

    const args = ['--version', '0.1.1', '--apk-dir', 'build/release/apks', '--out', 'build/release'];

    test('writes release.json and notes.md with real checksums', () async {
      writeApks(_abis);
      final code = await prepareRelease(args, root: root, now: () => DateTime.utc(2026, 11, 12, 10));
      expect(code, 0);

      final manifest = jsonDecode(File('${root.path}/build/release/release.json').readAsStringSync()) as Map<String, Object?>;
      final arm = (manifest['assets']! as List<Object?>).cast<Map<String, Object?>>().first;
      expect(arm['file'], 'anuvaad-0.1.1-arm64-v8a.apk');
      expect(arm['sha256'], sha256.convert(utf8.encode('apk for arm64-v8a')).toString());
      expect(arm['size'], 'apk for arm64-v8a'.length);
      expect(manifest['publishedAt'], '2026-11-12T10:00:00Z');
      expect(File('${root.path}/build/release/notes.md').readAsStringSync(),
          "### What's new\n- Release notes history in Settings.\n");
    });

    test('fails without writing anything when an APK is missing', () async {
      writeApks(_abis.take(3).toList());
      final code = await prepareRelease(args, root: root, now: DateTime.now);
      expect(code, isNot(0));
      expect(File('${root.path}/build/release/release.json').existsSync(), isFalse);
    });

    test('fails when pubspec does not match the CHANGELOG build', () async {
      writeApks(_abis);
      File('${root.path}/pubspec.yaml').writeAsStringSync('name: anuvaad\nversion: 0.1.1+3\n');
      expect(await prepareRelease(args, root: root, now: DateTime.now), isNot(0));
    });
  });
}
