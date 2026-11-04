import 'package:freezed_annotation/freezed_annotation.dart';

part 'release_info.freezed.dart';
part 'release_info.g.dart';

/// ABIs a release may ship an APK for (shared contract).
const supportedApkAbis = {'arm64-v8a', 'armeabi-v7a', 'x86_64', 'universal'};

@freezed
abstract class ReleaseNotes with _$ReleaseNotes {
  const factory ReleaseNotes({required List<String> whatsNew, required List<String> fixed}) = _ReleaseNotes;

  factory ReleaseNotes.fromJson(Map<String, dynamic> json) => _$ReleaseNotesFromJson(json);
}

@freezed
abstract class ApkAsset with _$ApkAsset {
  const factory ApkAsset({
    required String abi,
    required String file,
    required Uri url,
    required int size,
    required String sha256,
  }) = _ApkAsset;

  factory ApkAsset.fromJson(Map<String, dynamic> json) => _$ApkAssetFromJson(json);
}

/// `release.json` plus download URLs: the ReleaseInfo of the shared contract.
@freezed
abstract class ReleaseInfo with _$ReleaseInfo {
  const factory ReleaseInfo({
    required int schema,
    required String version,
    required int build,
    required DateTime publishedAt,
    required bool mandatory,
    required int minSupportedBuild,
    required ReleaseNotes notes,
    required List<ApkAsset> assets,
    required Uri releaseUrl,
  }) = _ReleaseInfo;

  factory ReleaseInfo.fromJson(Map<String, dynamic> json) => _$ReleaseInfoFromJson(json);
}

final _version = RegExp(r'^\d+\.\d+\.\d+$');
final _sha256 = RegExp(r'^[0-9a-f]{64}$');

/// Parses and validates ReleaseInfo JSON; any contract violation is a [FormatException].
ReleaseInfo parseReleaseInfo(Map<String, Object?> json) {
  final ReleaseInfo info;
  try {
    info = ReleaseInfo.fromJson(json);
  } on CheckedFromJsonException catch (e) {
    throw FormatException('Invalid release info: ${e.key ?? e.className}: ${e.message ?? e.innerError}');
  } on Object catch (e) {
    throw FormatException('Invalid release info: $e');
  }

  void check(bool ok, String problem) {
    if (!ok) throw FormatException('Invalid release info: $problem');
  }

  check(info.schema == 1, 'schema must be 1');
  check(_version.hasMatch(info.version), 'version must be X.Y.Z');
  check(info.build >= 1, 'build must be at least 1');
  check(info.minSupportedBuild >= 1 && info.minSupportedBuild <= info.build, 'minSupportedBuild must be between 1 and build');
  check(info.assets.isNotEmpty, 'assets must not be empty');
  for (final asset in info.assets) {
    check(supportedApkAbis.contains(asset.abi), 'unknown abi ${asset.abi}');
    check(asset.file.endsWith('.apk'), 'asset file must be an .apk');
    check(asset.size > 0, 'asset size must be positive');
    check(_sha256.hasMatch(asset.sha256), 'sha256 must be 64 lowercase hex characters');
    check(asset.url.scheme == 'https', 'asset url must be https');
  }
  final notes = [...info.notes.whatsNew, ...info.notes.fixed];
  check(notes.isNotEmpty, 'release notes must not be empty');
  check(notes.every((n) => n.trim().isNotEmpty), 'release notes must not be blank');
  return info;
}
