import 'changelog.dart';

/// ABIs in the order release.json lists them.
const releaseAbis = ['arm64-v8a', 'armeabi-v7a', 'x86_64', 'universal'];

class ApkFileInfo {
  const ApkFileInfo({required this.abi, required this.file, required this.size, required this.sha256});
  final String abi;
  final String file;
  final int size;
  final String sha256;
}

/// The release.json document (shared contract, without download URLs).
Map<String, Object?> buildReleaseManifest({
  required ChangelogEntry entry,
  required DateTime publishedAt,
  required List<ApkFileInfo> apks,
}) {
  if (entry.minSupportedBuild < 1 || entry.minSupportedBuild > entry.build) {
    throw StateError('Min supported build ${entry.minSupportedBuild} must be between 1 and ${entry.build}');
  }
  final ordered = [...apks]..sort((a, b) => releaseAbis.indexOf(a.abi).compareTo(releaseAbis.indexOf(b.abi)));
  return {
    'schema': 1,
    'version': entry.version,
    'build': entry.build,
    'publishedAt': publishedAt.toUtc().toIso8601String().replaceFirst(RegExp(r'\.\d+Z$'), 'Z'),
    'mandatory': entry.mandatory,
    'minSupportedBuild': entry.minSupportedBuild,
    'notes': {'whatsNew': entry.whatsNew, 'fixed': entry.fixed},
    'assets': [
      for (final apk in ordered) {'abi': apk.abi, 'file': apk.file, 'size': apk.size, 'sha256': apk.sha256},
    ],
  };
}
