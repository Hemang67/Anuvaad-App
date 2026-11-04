// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'release_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReleaseNotes _$ReleaseNotesFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_ReleaseNotes', json, ($checkedConvert) {
      final val = _ReleaseNotes(
        whatsNew: $checkedConvert(
          'whatsNew',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        fixed: $checkedConvert(
          'fixed',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ReleaseNotesToJson(_ReleaseNotes instance) =>
    <String, dynamic>{'whatsNew': instance.whatsNew, 'fixed': instance.fixed};

_ApkAsset _$ApkAssetFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_ApkAsset', json, ($checkedConvert) {
      final val = _ApkAsset(
        abi: $checkedConvert('abi', (v) => v as String),
        file: $checkedConvert('file', (v) => v as String),
        url: $checkedConvert('url', (v) => Uri.parse(v as String)),
        size: $checkedConvert('size', (v) => (v as num).toInt()),
        sha256: $checkedConvert('sha256', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ApkAssetToJson(_ApkAsset instance) => <String, dynamic>{
  'abi': instance.abi,
  'file': instance.file,
  'url': instance.url.toString(),
  'size': instance.size,
  'sha256': instance.sha256,
};

_ReleaseInfo _$ReleaseInfoFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_ReleaseInfo',
  json,
  ($checkedConvert) {
    final val = _ReleaseInfo(
      schema: $checkedConvert('schema', (v) => (v as num).toInt()),
      version: $checkedConvert('version', (v) => v as String),
      build: $checkedConvert('build', (v) => (v as num).toInt()),
      publishedAt: $checkedConvert(
        'publishedAt',
        (v) => DateTime.parse(v as String),
      ),
      mandatory: $checkedConvert('mandatory', (v) => v as bool),
      minSupportedBuild: $checkedConvert(
        'minSupportedBuild',
        (v) => (v as num).toInt(),
      ),
      notes: $checkedConvert(
        'notes',
        (v) => ReleaseNotes.fromJson(v as Map<String, dynamic>),
      ),
      assets: $checkedConvert(
        'assets',
        (v) => (v as List<dynamic>)
            .map((e) => ApkAsset.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      releaseUrl: $checkedConvert('releaseUrl', (v) => Uri.parse(v as String)),
    );
    return val;
  },
);

Map<String, dynamic> _$ReleaseInfoToJson(_ReleaseInfo instance) =>
    <String, dynamic>{
      'schema': instance.schema,
      'version': instance.version,
      'build': instance.build,
      'publishedAt': instance.publishedAt.toIso8601String(),
      'mandatory': instance.mandatory,
      'minSupportedBuild': instance.minSupportedBuild,
      'notes': instance.notes.toJson(),
      'assets': instance.assets.map((e) => e.toJson()).toList(),
      'releaseUrl': instance.releaseUrl.toString(),
    };
