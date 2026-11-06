import 'package:anuvaad/features/conversation/data/android_speech_recognizer.dart';
import 'package:anuvaad/features/conversation/domain/speech_recognition.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _methods = MethodChannel('app.anuvaad/speech');
const _events = EventChannel('app.anuvaad/speech/events');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    messenger.setMockMethodCallHandler(_methods, (call) async {
      calls.add(call);
      return call.method == 'isAvailable' ? true : null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(_methods, null);
    messenger.setMockStreamHandler(_events, null);
  });

  void emit(List<Object?> maps) {
    messenger.setMockStreamHandler(
      _events,
      MockStreamHandler.inline(onListen: (arguments, sink) {
        for (final map in maps) {
          sink.success(map);
        }
        sink.endOfStream();
      }),
    );
  }

  test('start sends the locale; stop and cancel reach the platform', () async {
    final recognizer = AndroidSpeechRecognizer();
    await recognizer.start('gu-IN');
    await recognizer.stop();
    await recognizer.cancel();
    expect(calls.map((c) => c.method), ['start', 'stop', 'cancel']);
    expect(calls.first.arguments, {'locale': 'gu-IN'});
  });

  test('maps every event type', () async {
    emit([
      {'type': 'ready'},
      {'type': 'partial', 'text': 'आप'},
      {'type': 'final', 'text': 'आप आज'},
      {'type': 'endOfSpeech'},
      {'type': 'error', 'code': 'languageUnavailable'},
    ]);
    final events = await AndroidSpeechRecognizer().events.toList();
    expect(events, hasLength(5));
    expect(events[0], isA<RecognitionReady>());
    expect(events[1], isA<PartialResult>().having((e) => e.text, 'text', 'आप'));
    expect(events[2], isA<FinalResult>().having((e) => e.text, 'text', 'आप आज'));
    expect(events[3], isA<EndOfSpeech>());
    expect(events[4], isA<RecognitionError>().having((e) => e.code, 'code', RecognitionErrorCode.languageUnavailable));
  });

  test('unknown error codes and unknown event types are safe', () async {
    emit([
      {'type': 'error', 'code': 'weird'},
      {'type': 'mystery'},
      'not a map',
      {'type': 'partial'},
    ]);
    final events = await AndroidSpeechRecognizer().events.toList();
    expect(events, hasLength(1));
    expect(events.single, isA<RecognitionError>().having((e) => e.code, 'code', RecognitionErrorCode.unknown));
  });

  test('isAvailable returns the platform answer and false on PlatformException', () async {
    expect(await AndroidSpeechRecognizer().isAvailable(), isTrue);
    messenger.setMockMethodCallHandler(_methods, (call) async => throw PlatformException(code: 'boom'));
    expect(await AndroidSpeechRecognizer().isAvailable(), isFalse);
  });

  test('every error code name round-trips', () {
    for (final code in RecognitionErrorCode.values) {
      expect(recognitionErrorCodeFromName(code.name), code);
    }
  });

  test('start sends detectAmong only when given', () async {
    final recognizer = AndroidSpeechRecognizer();
    await recognizer.start('hi-IN');
    await recognizer.start('hi-IN', detectAmong: const ['hi-IN', 'gu-IN']);
    expect(calls[0].arguments, {'locale': 'hi-IN'});
    expect(calls[1].arguments, {
      'locale': 'hi-IN',
      'detectAmong': ['hi-IN', 'gu-IN'],
    });
  });

  test('parses speechStart, level and languageDetected', () async {
    emit([
      {'type': 'speechStart'},
      {'type': 'level', 'value': 0.42},
      {'type': 'level', 'value': 3},
      {'type': 'languageDetected', 'locale': 'gu-IN', 'confidence': 2},
      {'type': 'languageDetected', 'locale': 'hi-IN', 'confidence': 9},
      {'type': 'languageDetected', 'confidence': 2},
    ]);
    final events = await AndroidSpeechRecognizer().events.toList();
    expect(events, hasLength(5));
    expect(events[0], isA<SpeechStarted>());
    expect(events[1], isA<SoundLevel>().having((e) => e.level, 'level', 0.42));
    expect(events[2], isA<SoundLevel>().having((e) => e.level, 'level', 1.0), reason: 'clamped to 0..1');
    expect(
      events[3],
      isA<LanguageDetected>()
          .having((e) => e.locale, 'locale', 'gu-IN')
          .having((e) => e.confidence, 'confidence', LanguageConfidence.confident),
    );
    expect(events[4], isA<LanguageDetected>().having((e) => e.confidence, 'confidence', LanguageConfidence.unknown));
  });

  test('supportsLanguageDetection is false when the platform says so or the plugin is missing', () async {
    messenger.setMockMethodCallHandler(_methods, (call) async => call.method == 'supportsLanguageDetection' ? true : null);
    expect(await AndroidSpeechRecognizer().supportsLanguageDetection(), isTrue);
    messenger.setMockMethodCallHandler(_methods, (call) async => false);
    expect(await AndroidSpeechRecognizer().supportsLanguageDetection(), isFalse);
    messenger.setMockMethodCallHandler(_methods, (call) async => throw PlatformException(code: 'boom'));
    expect(await AndroidSpeechRecognizer().supportsLanguageDetection(), isFalse);
    messenger.setMockMethodCallHandler(_methods, null);
    expect(await AndroidSpeechRecognizer().supportsLanguageDetection(), isFalse);
  });
}
