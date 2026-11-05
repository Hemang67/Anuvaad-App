// Builds release.json and notes.md for a tagged release.
//
// Usage: dart run tool/release/prepare_release.dart --version 0.1.0 \
//          --apk-dir build/release/apks --out build/release [--root .]
// Expects anuvaad-<version>-<abi>.apk for every ABI in releaseAbis.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'changelog.dart';
import 'manifest.dart';

Future<void> main(List<String> args) async {
  final root = Directory(_option(args, '--root') ?? '.');
  exitCode = await prepareRelease(args, root: root, now: DateTime.now);
}

Future<int> prepareRelease(List<String> args, {required Directory root, required DateTime Function() now}) async {
  final version = _option(args, '--version');
  final apkDir = _option(args, '--apk-dir');
  final outDir = _option(args, '--out');
  if (version == null || apkDir == null || outDir == null) {
    stderr.writeln('usage: prepare_release.dart --version X.Y.Z --apk-dir DIR --out DIR [--root DIR]');
    return 64;
  }
  try {
    final entry = parseChangelogEntry(File('${root.path}/CHANGELOG.md').readAsStringSync(), version);
    verifyPubspecVersion(File('${root.path}/pubspec.yaml').readAsStringSync(), version: version, build: entry.build);

    final apks = <ApkFileInfo>[];
    final missing = <String>[];
    for (final abi in releaseAbis) {
      final name = 'anuvaad-$version-$abi.apk';
      final file = File('${root.path}/$apkDir/$name');
      if (!file.existsSync()) {
        missing.add(name);
        continue;
      }
      final digest = await sha256.bind(file.openRead()).first;
      apks.add(ApkFileInfo(abi: abi, file: name, size: file.lengthSync(), sha256: digest.toString()));
    }
    if (missing.isNotEmpty) throw StateError('Missing APKs in $apkDir: ${missing.join(', ')}');

    final manifest = buildReleaseManifest(entry: entry, publishedAt: now(), apks: apks);
    final out = Directory('${root.path}/$outDir')..createSync(recursive: true);
    File('${out.path}/release.json').writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(manifest)}\n');
    File('${out.path}/notes.md').writeAsStringSync(entry.notesMarkdown);
    stdout.writeln('Prepared Anuvaad $version (build ${entry.build}) with ${apks.length} APKs');
    return 0;
  } on FormatException catch (e) {
    stderr.writeln('CHANGELOG error: ${e.message}');
    return 1;
  } on StateError catch (e) {
    stderr.writeln('Release error: ${e.message}');
    return 1;
  } on FileSystemException catch (e) {
    stderr.writeln('File error: ${e.message} ${e.path ?? ''}');
    return 1;
  }
}

String? _option(List<String> args, String name) {
  final index = args.indexOf(name);
  return index >= 0 && index + 1 < args.length ? args[index + 1] : null;
}
