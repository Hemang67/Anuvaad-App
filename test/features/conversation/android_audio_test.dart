import 'package:anuvaad/features/conversation/data/android_audio.dart';
import 'package:anuvaad/features/conversation/domain/audio_output.dart';
import 'package:anuvaad/features/conversation/domain/voice.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _methods = MethodChannel('app.anuvaad/audio');
const _events = EventChannel('app.anuvaad/audio/events');

const _speaker = {'id': 2, 'kind': 'speaker', 'name': ''};
const _buds = {'id': 9, 'kind': 'bluetooth', 'name': 'Galaxy Buds'};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;
  late Object? Function(MethodCall call) answer;

  setUp(() {
    calls = [];
    answer = (_) => null;
    messenger.setMockMethodCallHandler(_methods, (call) async {
      calls.add(call);
      return answer(call);
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

  test('voiceAvailability maps the three answers', () async {
    final audio = AndroidAudio();
    for (final (raw, expected) in [
      ('available', VoiceAvailability.available),
      ('needsDownload', VoiceAvailability.needsDownload),
      ('unsupported', VoiceAvailability.unsupported),
      ('weird', VoiceAvailability.unsupported),
    ]) {
      answer = (_) => raw;
      expect(await audio.availability('gu-IN'), expected, reason: raw);
    }
    expect(calls.first.method, 'voiceAvailability');
    expect(calls.first.arguments, {'locale': 'gu-IN'});
  });

  test('synthesize sends text, locale and path; voiceMissing becomes VoiceMissing', () async {
    final audio = AndroidAudio();
    await audio.synthesize(text: 'नमस्ते', locale: 'hi-IN', path: '/cache/tts/s1.wav');
    expect(calls.single.method, 'synthesize');
    expect(calls.single.arguments, {'text': 'नमस्ते', 'locale': 'hi-IN', 'path': '/cache/tts/s1.wav', 'rate': 1.0});

    answer = (_) => throw PlatformException(code: 'voiceMissing');
    await expectLater(
      audio.synthesize(text: 'x', locale: 'gu-IN', path: '/p'),
      throwsA(isA<VoiceMissing>().having((e) => e.locale, 'locale', 'gu-IN')),
    );
    answer = (_) => throw PlatformException(code: 'synthesisFailed');
    await expectLater(audio.synthesize(text: 'x', locale: 'gu-IN', path: '/p'), throwsA(isA<SynthesisFailed>()));
  });

  test("voiceAvailability's platform error becomes SynthesisFailed, for the service to treat as no voice", () async {
    answer = (_) => throw PlatformException(code: 'synthesisFailed', message: 'Speech engine unavailable');
    await expectLater(AndroidAudio().availability('gu-IN'), throwsA(isA<SynthesisFailed>()));
  });

  test('openVoiceInstall returns the platform answer', () async {
    answer = (_) => true;
    expect(await AndroidAudio().openVoiceInstall('gu-IN'), isTrue);
    expect(calls.single.arguments, {'locale': 'gu-IN'});
  });

  test('outputs parses kinds and skips unknown kinds', () async {
    answer = (_) => [_speaker, _buds, {'id': 4, 'kind': 'hdmi', 'name': 'TV'}, 'junk'];
    final outputs = await AndroidAudio().outputs();
    expect(outputs, [
      const AudioOutput(id: 2, kind: OutputKind.speaker, name: ''),
      const AudioOutput(id: 9, kind: OutputKind.bluetooth, name: 'Galaxy Buds'),
    ]);
    expect(outputs.last.name, 'Galaxy Buds');
  });

  test('play and stop send the contract arguments', () async {
    final audio = AndroidAudio();
    await audio.play(path: '/cache/tts/s1.wav', deviceId: 9, playbackId: 's1');
    await audio.play(path: '/cache/tts/s2.wav', deviceId: null, playbackId: 's2');
    await audio.stop();
    expect(calls.map((c) => c.method), ['play', 'play', 'stop']);
    expect(calls[0].arguments, {'path': '/cache/tts/s1.wav', 'deviceId': 9, 'playbackId': 's1'});
    expect(calls[1].arguments, {'path': '/cache/tts/s2.wav', 'deviceId': null, 'playbackId': 's2'});
  });

  test('maps every event type', () async {
    emit([
      {'type': 'outputs', 'outputs': [_speaker, _buds]},
      {'type': 'started', 'playbackId': 's1', 'routed': _buds},
      {'type': 'completed', 'playbackId': 's1'},
      {'type': 'failed', 'playbackId': 's2', 'code': '1:-1004'},
      {'type': 'focusLost', 'playbackId': 's3'},
      {'type': 'started', 'playbackId': 's4'}, // no routed device: ignored
      {'type': 'mystery'},
      'not a map',
    ]);
    final events = await AndroidAudio().events.toList();
    expect(events, hasLength(5));
    expect(events[0], isA<OutputsChanged>().having((e) => e.outputs.map((o) => o.id), 'ids', [2, 9]));
    expect(events[1], isA<PlaybackStarted>().having((e) => e.playbackId, 'id', 's1').having((e) => e.routed.name, 'routed', 'Galaxy Buds'));
    expect(events[2], isA<PlaybackCompleted>().having((e) => e.playbackId, 'id', 's1'));
    expect(events[3], isA<PlaybackFailed>().having((e) => e.code, 'code', '1:-1004'));
    expect(events[4], isA<PlaybackFocusLost>().having((e) => e.playbackId, 'id', 's3'));
  });

  test('playTestTone returns the routed output', () async {
    answer = (_) => _speaker;
    final routed = await AndroidAudio().playTestTone(deviceId: 2);
    expect(routed, const AudioOutput(id: 2, kind: OutputKind.speaker, name: ''));
    expect(calls.single.arguments, {'deviceId': 2});
  });

  test('synthesize sends rate and voice', () async {
    await AndroidAudio().synthesize(text: 'x', locale: 'gu-IN', path: '/p', rate: 1.25, voice: 'gu-in-x-guf-local');
    expect(calls.single.arguments, {'text': 'x', 'locale': 'gu-IN', 'path': '/p', 'rate': 1.25, 'voice': 'gu-in-x-guf-local'});
  });

  test('voices parses the platform list, and an error is no voices', () async {
    answer = (_) => [
          {'name': 'hi-in-x-hia-local', 'network': false, 'installed': true},
          {'name': 'hi-in-x-hie-network', 'network': true, 'installed': true},
          {'name': 'broken'},
        ];
    final voices = await AndroidAudio().voices('hi-IN');
    expect(calls.single.method, 'voices');
    expect(calls.single.arguments, {'locale': 'hi-IN'});
    expect(voices.map((v) => v.name), ['hi-in-x-hia-local', 'hi-in-x-hie-network']);
    expect(voices.first.network, isFalse);
    expect(voices.last.network, isTrue);
    expect(voices.first.installed, isTrue);

    answer = (_) => throw PlatformException(code: 'synthesisFailed');
    expect(await AndroidAudio().voices('hi-IN'), isEmpty);
  });
}
