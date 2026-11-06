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

/// Port for text-to-speech (spec §3.2 SpeechSynthPort); the Android adapter lives in `data/`.
abstract interface class SpeechSynthPort {
  Future<VoiceAvailability> availability(String locale);

  /// Writes speech for [text] in [locale] to the WAV file at [path].
  Future<void> synthesize({required String text, required String locale, required String path});

  /// Opens the engine's voice install screen (or TTS settings). Returns whether anything opened.
  Future<bool> openVoiceInstall(String locale);
}
