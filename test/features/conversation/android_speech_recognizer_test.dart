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
}
