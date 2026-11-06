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

  /// Starts one listening turn in [locale], e.g. `hi-IN`.
  Future<void> start(String locale);

  /// Stops listening; the final result arrives as an event.
  Future<void> stop();

  /// Stops listening and discards the turn.
  Future<void> cancel();
}
