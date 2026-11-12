/// Whether the phone can speak a language.
enum VoiceAvailability {
  available,

  /// The engine knows the language but its voice data isn't on the phone.
  needsDownload,
  unsupported,
}

/// No usable voice for [locale] on this phone.
class VoiceMissing implements Exception {
  const VoiceMissing(this.locale);

  final String locale;

  @override
  String toString() => 'VoiceMissing($locale)';
}

/// The engine failed to write the audio file.
class SynthesisFailed implements Exception {
  const SynthesisFailed(this.code);

  final String code;

  @override
  String toString() => 'SynthesisFailed($code)';
}

/// One of the speech engine's voices for a language. Engine names ("hi-in-x-hia-local") aren't shown to people.
class VoiceOption {
  const VoiceOption({required this.name, required this.network, required this.installed});

  final String name;

  /// Spoken by Google's servers rather than on the phone.
  final bool network;

  /// Its data is on the phone (or it needs none).
  final bool installed;
}

/// Port for text-to-speech (spec §3.2 SpeechSynthPort); the Android adapter lives in `data/`.
abstract interface class SpeechSynthPort {
  Future<VoiceAvailability> availability(String locale);

  /// The engine's voices for [locale]: on-phone voices first.
  Future<List<VoiceOption>> voices(String locale);

  /// Writes speech for [text] in [locale] to the WAV file at [path], at [rate] (1.0 normal) in [voice] (null: the
  /// engine's default for the language).
  Future<void> synthesize({
    required String text,
    required String locale,
    required String path,
    double rate = 1.0,
    String? voice,
  });

  /// Opens the engine's voice install screen (or TTS settings). Returns whether anything opened.
  Future<bool> openVoiceInstall(String locale);
}
