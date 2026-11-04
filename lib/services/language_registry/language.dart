/// Where a language stands in the registry.
enum LanguageInstallation { builtin, installed, available, notReleased }

LanguageInstallation parseInstallation(Object? raw) => switch (raw) {
      'builtin' => LanguageInstallation.builtin,
      'installed' => LanguageInstallation.installed,
      'available' => LanguageInstallation.available,
      'not_released' => LanguageInstallation.notReleased,
      _ => throw FormatException('Unknown installation type: $raw'),
    };

/// Per-stage capabilities, named exactly as in spec §7.1.
class LanguageCapabilities {
  const LanguageCapabilities({
    required this.speechRecognition,
    required this.languageIdentification,
    required this.translationInput,
    required this.translationOutput,
    required this.textToSpeech,
    required this.offlineSpeechRecognition,
    required this.offlineTranslation,
    required this.offlineTextToSpeech,
  });

  factory LanguageCapabilities.fromJson(Map<String, Object?> json) {
    bool flag(String key) {
      final value = json[key];
      if (value is! bool) throw FormatException('Capability "$key" must be true or false');
      return value;
    }

    return LanguageCapabilities(
      speechRecognition: flag('speechRecognition'),
      languageIdentification: flag('languageIdentification'),
      translationInput: flag('translationInput'),
      translationOutput: flag('translationOutput'),
      textToSpeech: flag('textToSpeech'),
      offlineSpeechRecognition: flag('offlineSpeechRecognition'),
      offlineTranslation: flag('offlineTranslation'),
      offlineTextToSpeech: flag('offlineTextToSpeech'),
    );
  }

  final bool speechRecognition;
  final bool languageIdentification;
  final bool translationInput;
  final bool translationOutput;
  final bool textToSpeech;
  final bool offlineSpeechRecognition;
  final bool offlineTranslation;
  final bool offlineTextToSpeech;
}

class Language {
  const Language({
    required this.code,
    required this.displayName,
    required this.nativeName,
    required this.shortLabel,
    required this.version,
    required this.installation,
    required this.capabilities,
  });

  final String code;
  final String displayName;
  final String nativeName;
  final String shortLabel;
  final String version;
  final LanguageInstallation installation;
  final LanguageCapabilities capabilities;

  bool get isCore => installation == LanguageInstallation.builtin;

  /// e.g. 'ગુજરાતી · Gujarati'
  String get nativeFirstLabel => '$nativeName · $displayName';

  /// e.g. 'Gujarati · ગુજરાતી'
  String get nameFirstLabel => '$displayName · $nativeName';
}
