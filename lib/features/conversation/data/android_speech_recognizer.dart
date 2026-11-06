import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/speech_recognition.dart';

/// Android's SpeechRecognizer through `SpeechRecognitionPlugin.kt`.
class AndroidSpeechRecognizer implements SpeechRecognizerPort {
  static const _methods = MethodChannel('app.anuvaad/speech');
  static const _eventChannel = EventChannel('app.anuvaad/speech/events');

  Stream<RecognitionEvent>? _events;

  @override
  Stream<RecognitionEvent> get events => _events ??= _eventChannel
      .receiveBroadcastStream()
      .map(_parse)
      .where((event) => event != null)
      .cast<RecognitionEvent>();

  static RecognitionEvent? _parse(Object? raw) {
    if (raw is! Map) return null;
    final text = raw['text'];
    return switch (raw['type']) {
      'ready' => const RecognitionReady(),
      'partial' when text is String => PartialResult(text),
      'final' when text is String => FinalResult(text),
      'endOfSpeech' => const EndOfSpeech(),
      'error' => RecognitionError(recognitionErrorCodeFromName(raw['code'])),
      _ => null,
    };
  }

  @override
  Future<bool> isAvailable() async {
    try {
      return await _methods.invokeMethod<bool>('isAvailable') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<void> start(String locale) => _methods.invokeMethod<void>('start', {'locale': locale});

  @override
  Future<void> stop() => _methods.invokeMethod<void>('stop');

  @override
  Future<void> cancel() => _methods.invokeMethod<void>('cancel');
}

final speechRecognizerProvider = Provider<SpeechRecognizerPort>((ref) => AndroidSpeechRecognizer());
