import 'dart:async';

import 'package:anuvaad/features/conversation/domain/audio_output.dart';
import 'package:anuvaad/features/conversation/domain/speech_recognition.dart';
import 'package:anuvaad/features/conversation/domain/voice.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/conversation_fakes.dart';
import '../../helpers/conversation_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final h = ConversationHarness();

  setUp(() => h.setUp());
  tearDown(() => h.tearDown());

  /// Lets everything already started finish at the current time, then moves the clock to [ms] after 10:00.
  Future<void> at(int ms) async {
    await h.flush();
    h.now = DateTime(2026, 11, 6, 10).add(Duration(milliseconds: ms));
  }

  test('a spoken translation records every stage', () async {
    await h.controller.startListening();
    final id = h.activeId;
    h.cloud.gates[id] = Completer<void>();
    h.synth.gates['EN:नमस्ते'] = Completer<void>();

    await at(1000);
    h.recognizer.emit(const SpeechStarted());
    await at(1400);
    h.recognizer.emit(const PartialResult('नम'));
    await at(3000);
    h.recognizer.emit(const EndOfSpeech());
    await at(3700);
    h.recognizer.emit(const FinalResult('नमस्ते'));
    await at(4500);
    h.cloud.gates[id]!.complete();
    await at(4800);
    h.synth.gates['EN:नमस्ते']!.complete();
    await at(4900);
    h.audio.emit(PlaybackStarted(id, fakeBuds));
    await h.flush();

    final sample = (await h.latency.samples()).single;
    expect(sample.pair, 'hi-IN→en-IN');
    expect(sample.onsetToFirstPartialMs, 400);
    expect(sample.speechEndToFinalMs, 700);
    expect(sample.translationMs, 800);
    expect(sample.synthesisMs, 300);
    expect(sample.playbackStartMs, 100);
    expect(sample.speechEndToAudioMs, 1900);
    expect(sample.output, OutputKind.bluetooth);
    expect(sample.provider, 'cloudflare');

    h.audio.emit(PlaybackCompleted(id));
    await h.flush();
    await h.controller.replay(id);
    h.audio.emit(PlaybackStarted(id, fakeBuds));
    await h.flush();
    expect(await h.latency.samples(), hasLength(1), reason: 'a replay is not a new measurement');
  });

  test('a translation that is not spoken still records its stages', () async {
    await h.controller.startSpeaking();
    h.synth.availabilityByLocale['hi-IN'] = VoiceAvailability.needsDownload;
    await h.say('Hello');
    final sample = (await h.latency.samples()).single;
    expect(sample.pair, 'en-IN→hi-IN');
    expect(sample.translationMs, isNotNull);
    expect(sample.speechEndToAudioMs, isNull);
  });
}
