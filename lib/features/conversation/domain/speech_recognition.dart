/// What the phone's speech recognizer reports during one listening turn.
sealed class RecognitionEvent {
  const RecognitionEvent();
}

/// The microphone is open and listening.
class RecognitionReady extends RecognitionEvent {
  const RecognitionReady();
}

/// Live text while the person is still speaking.
class PartialResult extends RecognitionEvent {
  const PartialResult(this.text);
  final String text;
}

/// The recognizer's final text for this turn.
class FinalResult extends RecognitionEvent {
  const FinalResult(this.text);
  final String text;
}

/// The recognizer heard the start of speech (for latency timing).
class SpeechStarted extends RecognitionEvent {
  const SpeechStarted();
}

/// Microphone loudness, 0 (silence) to 1, a few times a second while listening (drives the waveform).
class SoundLevel extends RecognitionEvent {
  const SoundLevel(this.level);
  final double level;
}

/// How sure Android's recognizer is about a detected language (Android 14+).
enum LanguageConfidence { unknown, notConfident, confident, highlyConfident }

/// The recognizer's guess at the spoken language, among the ones it was allowed to detect.
class LanguageDetected extends RecognitionEvent {
  const LanguageDetected(this.locale, this.confidence);
  final String locale;
  final LanguageConfidence confidence;
}

/// The person stopped speaking; a final result or an error follows.
class EndOfSpeech extends RecognitionEvent {
  const EndOfSpeech();
}

class RecognitionError extends RecognitionEvent {
  const RecognitionError(this.code);
  final RecognitionErrorCode code;
}

enum RecognitionErrorCode {
  noMatch,
  speechTimeout,
  network,
  audio,
  server,
  client,
  permission,
  busy,
  languageUnsupported,
  languageUnavailable,
  unknown,
}

RecognitionErrorCode recognitionErrorCodeFromName(Object? name) =>
    RecognitionErrorCode.values.firstWhere((c) => c.name == name, orElse: () => RecognitionErrorCode.unknown);

/// Port for speech recognition; the Android adapter lives in `data/`.
abstract interface class SpeechRecognizerPort {
  Stream<RecognitionEvent> get events;

  /// Whether the phone has a speech recognition service at all.
  Future<bool> isAvailable();

  /// Whether the recognizer can detect the spoken language (Android 14 and later).
  Future<bool> supportsLanguageDetection();

  /// Starts one listening turn in [locale], e.g. `hi-IN`. With [detectAmong], the recognizer also detects which of
  /// those languages is spoken (and may switch to it), reporting [LanguageDetected].
  Future<void> start(String locale, {List<String> detectAmong = const []});

  /// Stops listening; the final result arrives as an event.
  Future<void> stop();

  /// Stops listening and discards the turn.
  Future<void> cancel();
}
