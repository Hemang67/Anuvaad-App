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
      'speechStart' => const SpeechStarted(),
      'level' when raw['value'] is num => SoundLevel((raw['value'] as num).toDouble().clamp(0.0, 1.0)),
      'languageDetected' when raw['locale'] is String =>
        LanguageDetected(raw['locale'] as String, _confidence(raw['confidence'])),
      'error' => RecognitionError(recognitionErrorCodeFromName(raw['code'])),
      _ => null,
    };
  }

  /// Android's LANGUAGE_DETECTION_CONFIDENCE_LEVEL_* values 0..3.
  static LanguageConfidence _confidence(Object? raw) => switch (raw) {
        1 => LanguageConfidence.notConfident,
        2 => LanguageConfidence.confident,
        3 => LanguageConfidence.highlyConfident,
        _ => LanguageConfidence.unknown,
      };

  @override
  Future<bool> supportsLanguageDetection() async {
    try {
      return await _methods.invokeMethod<bool>('supportsLanguageDetection') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
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
  Future<void> start(String locale, {List<String> detectAmong = const []}) => _methods.invokeMethod<void>('start', {
        'locale': locale,
        if (detectAmong.isNotEmpty) 'detectAmong': detectAmong,
      });

  @override
  Future<void> stop() => _methods.invokeMethod<void>('stop');

  @override
  Future<void> cancel() => _methods.invokeMethod<void>('cancel');
}

final speechRecognizerProvider = Provider<SpeechRecognizerPort>((ref) => AndroidSpeechRecognizer());
