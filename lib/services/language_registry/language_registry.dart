import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';

import 'language.dart';

abstract interface class LanguageRegistry {
  /// Built-in languages in display order (en-IN, hi-IN, gu-IN).
  List<Language> get coreLanguages;

  /// Catalogue entries that are not released yet.
  List<Language> get plannedLanguages;

  Language? byCode(String code);

  bool canTranslate(String sourceCode, String targetCode);
}

const _coreIndexPath = 'assets/languages/core/index.json';
const _catalogPath = 'assets/languages/catalog.json';

/// Registry backed by the bundled JSON manifests.
class AssetLanguageRegistry implements LanguageRegistry {
  AssetLanguageRegistry._(this.coreLanguages, this.plannedLanguages);

  @override
  final List<Language> coreLanguages;

  @override
  final List<Language> plannedLanguages;

  static Future<AssetLanguageRegistry> load(AssetBundle bundle) async {
    final index = await _readJson(bundle, _coreIndexPath);
    final codes = _field<List<Object?>>(index, 'core', _coreIndexPath);
    final core = <Language>[];
    for (final code in codes) {
      final path = 'assets/languages/core/$code.json';
      core.add(_parseManifest(await _readJson(bundle, path), path));
    }
    final catalog = await _readJson(bundle, _catalogPath);
    final planned = <Language>[
      for (final entry in _field<List<Object?>>(catalog, 'languages', _catalogPath))
        _parseCatalogEntry(entry, _catalogPath),
    ].where((l) => l.installation == LanguageInstallation.notReleased).toList(growable: false);
    return AssetLanguageRegistry._(List.unmodifiable(core), List.unmodifiable(planned));
  }

  @override
  Language? byCode(String code) {
    for (final language in [...coreLanguages, ...plannedLanguages]) {
      if (language.code == code) return language;
    }
    return null;
  }

  @override
  bool canTranslate(String sourceCode, String targetCode) {
    if (sourceCode == targetCode) return false;
    final source = byCode(sourceCode);
    final target = byCode(targetCode);
    if (source == null || target == null) return false;
    return source.capabilities.translationInput && target.capabilities.translationOutput;
  }
}

/// The user's language on first run, from the device locale.
String defaultMyLanguage(Locale deviceLocale) => switch (deviceLocale.languageCode) {
      'gu' => 'gu-IN',
      'hi' => 'hi-IN',
      _ => 'en-IN',
    };

Future<Map<String, Object?>> _readJson(AssetBundle bundle, String path) async {
  try {
    final decoded = jsonDecode(await bundle.loadString(path));
    if (decoded is! Map<String, Object?>) throw const FormatException('not a JSON object');
    return decoded;
  } on FormatException catch (e) {
    throw FormatException('Invalid language manifest: $path (${e.message})');
  }
}

T _field<T>(Map<String, Object?> json, String key, String path) {
  final value = json[key];
  if (value is! T) throw FormatException('Invalid language manifest: $path (field "$key")');
  return value;
}

Language _parseManifest(Map<String, Object?> json, String path) {
  try {
    return Language(
      code: _field<String>(json, 'languageCode', path),
      displayName: _field<String>(json, 'displayName', path),
      nativeName: _field<String>(json, 'nativeName', path),
      shortLabel: _field<String>(json, 'shortLabel', path),
      version: _field<String>(json, 'version', path),
      installation: parseInstallation(json['installationType']),
      capabilities: LanguageCapabilities.fromJson(_field<Map<String, Object?>>(json, 'capabilities', path)),
    );
  } on FormatException catch (e) {
    throw e.message.startsWith('Invalid language manifest') ? e : FormatException('Invalid language manifest: $path (${e.message})');
  }
}

Language _parseCatalogEntry(Object? raw, String path) {
  if (raw is! Map<String, Object?>) throw FormatException('Invalid language manifest: $path (entry)');
  final input = _field<bool>(raw, 'input', path);
  final output = _field<bool>(raw, 'output', path);
  final code = _field<String>(raw, 'code', path);
  return Language(
    code: code,
    displayName: _field<String>(raw, 'name', path),
    nativeName: _field<String>(raw, 'nativeName', path),
    shortLabel: code.substring(0, 2).toUpperCase(),
    version: '',
    installation: parseInstallation(raw['installation']),
    capabilities: LanguageCapabilities(
      speechRecognition: input,
      languageIdentification: input,
      translationInput: input,
      translationOutput: output,
      textToSpeech: output,
      offlineSpeechRecognition: false,
      offlineTranslation: false,
      offlineTextToSpeech: false,
    ),
  );
}
