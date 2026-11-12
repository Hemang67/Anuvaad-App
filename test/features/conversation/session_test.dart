import 'dart:async';

import 'package:anuvaad/features/conversation/application/conversation_controller.dart';
import 'package:anuvaad/features/conversation/application/mic_level.dart';
import 'package:anuvaad/features/conversation/domain/audio_output.dart';
import 'package:anuvaad/features/conversation/domain/segment.dart';
import 'package:anuvaad/features/conversation/domain/speech_recognition.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/conversation_fakes.dart';
import '../../helpers/conversation_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final h = ConversationHarness();

  setUp(() => h.setUp());
  tearDown(() => h.tearDown());

  int indexOf(List<String> log, bool Function(String) test, [int from = 0]) {
    for (var i = from; i < log.length; i++) {
      if (test(log[i])) return i;
    }
    return -1;
  }

  test('startListening re-arms after the translation has played', () async {
    final log = <String>[];
    h.audio.sharedLog = log;
    h.recognizer.sharedLog = log;
    await h.controller.startListening();
    expect(h.state.listenMode, isTrue);
    expect(h.starts, 1);

    final id = await h.say('नमस्ते');
    expect(log.where((e) => e.startsWith('play:')), ['play:$id:${fakeSpeaker.id}']);
    await h.playThrough(id);
    expect(h.starts, 2);
    final play = indexOf(log, (e) => e.startsWith('play:'));
    expect(indexOf(log, (e) => e.startsWith('start:'), play + 1), greaterThan(play));
    expect(h.state.segments.last.isFinal, isFalse, reason: 'a fresh listening card');
  });

  test('continuous listening waits for playback to finish before listening again', () async {
    await h.controller.startListening();
    final id = await h.say('नमस्ते');
    h.audio.emit(PlaybackStarted(id, fakeSpeaker));
    await h.flush();
    expect(h.starts, 1, reason: 'the microphone never opens over playback');
    expect(h.seg(id).speech, SpeechStatus.playing);

    h.audio.emit(PlaybackCompleted(id));
    await h.flush();
    expect(h.starts, 2);
  });

  test('a playback that never reports completion stops blocking listening after 30 seconds', () async {
    h.watchdog = const Duration(milliseconds: 20);
    h.rebuild();
    await h.controller.startListening();
    final id = await h.say('नमस्ते');
    expect(h.starts, 1);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    await h.flush();
    expect(h.seg(id).speech, SpeechStatus.played);
    expect(h.starts, 2);
  });

  test('silence re-arms quietly, and a minute of silence pauses with a notice', () async {
    await h.controller.startListening();
    h.recognizer.emit(const RecognitionError(RecognitionErrorCode.noMatch));
    await h.flush();
    expect(h.state.notice, isNull);
    expect(h.starts, 2);
    expect(h.state.listenMode, isTrue);

    h.now = h.now.add(const Duration(seconds: 61));
    h.recognizer.emit(const RecognitionError(RecognitionErrorCode.speechTimeout));
    await h.flush();
    expect(h.state.notice, ConversationNotice.pausedForSilence);
    expect(h.state.listenMode, isFalse);
    expect(h.state.paused, isTrue);
    expect(h.starts, 2);
    expect(h.state.segments, isEmpty, reason: 'empty listening cards are dropped');
  });

  test('pause stops the microphone and playback before returning', () async {
    await h.controller.startListening();
    final id = await h.say('नमस्ते');
    h.audio.emit(PlaybackStarted(id, fakeSpeaker));
    await h.flush();

    await h.controller.pause();
    expect(h.audio.calls.last, 'stop');
    expect(h.seg(id).speech, SpeechStatus.played);
    expect(h.state.paused, isTrue);
    expect(h.state.listenMode, isFalse);

    h.audio.emit(PlaybackCompleted(id)); // late
    await h.flush();
    expect(h.starts, 1);
  });

  test('pause during a listening turn cancels it and drops the empty card', () async {
    await h.controller.startListening();
    await h.controller.pause();
    expect(h.recognizer.cancels, 1);
    expect(h.state.activeSpeaker, isNull);
    expect(h.state.segments, isEmpty);
    await h.flush();
    expect(h.starts, 1);
  });

  test('speaking during Listen mode returns to listening after the reply plays', () async {
    await h.controller.startListening();
    await h.controller.startSpeaking();
    expect(h.recognizer.cancels, 1, reason: 'the waiting Listen turn makes way');
    expect(h.recognizer.started, ['hi-IN', 'en-IN']);
    expect(h.state.activeSpeaker, Speaker.me);

    final reply = await h.say('Hello');
    expect(h.starts, 2);
    await h.playThrough(reply);
    expect(h.recognizer.started, ['hi-IN', 'en-IN', 'hi-IN']);
  });

  test('End stops everything and never re-arms', () async {
    await h.controller.startListening();
    final id = await h.say('नमस्ते');
    h.audio.emit(PlaybackStarted(id, fakeSpeaker));
    await h.flush();

    h.now = h.now.add(const Duration(minutes: 3));
    await h.controller.endSession();
    expect(h.state.ended, isTrue);
    expect(h.state.sessionEndedAt, h.now);
    expect(h.state.sessionStartedAt, DateTime(2026, 11, 6, 10));
    expect(h.audio.calls.last, 'stop');

    h.audio.emit(PlaybackCompleted(id));
    await h.flush();
    expect(h.starts, 1);
    await h.controller.startListening();
    expect(h.starts, 1, reason: 'an ended session stays ended');
  });

  test('End during a listening turn cancels the recognizer', () async {
    await h.controller.startListening();
    await h.controller.endSession();
    expect(h.recognizer.cancels, 1);
    expect(h.state.activeSpeaker, isNull);
  });

  testWidgets('going to the background pauses the session', (tester) async {
    await tester.runAsync(() => h.controller.startListening());
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.runAsync(h.flush);
    expect(h.state.paused, isTrue);
    expect(h.state.listenMode, isFalse);
    expect(h.recognizer.cancels, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.runAsync(h.flush);
    expect(h.starts, 1, reason: 'coming back does not reopen the microphone by itself');
  });

  test('a translation arriving while paused is shown but not spoken', () async {
    await h.controller.startListening();
    final id = h.activeId;
    h.cloud.gates[id] = Completer<void>();
    h.recognizer.emit(const FinalResult('नमस्ते'));
    await h.flush();
    await h.controller.pause();
    h.cloud.gates[id]!.complete();
    await h.flush();
    expect(h.seg(id).status, SegmentStatus.translated);
    expect(h.seg(id).speech, SpeechStatus.none);
    expect(h.audio.calls.where((c) => c.startsWith('play:')), isEmpty);
  });

  test('Replay during continuous listening makes way for playback, then listens again', () async {
    await h.controller.startListening();
    final first = await h.say('नमस्ते');
    await h.playThrough(first);
    expect(h.starts, 2);

    await h.controller.replay(first);
    await h.flush();
    expect(h.recognizer.cancels, 1);
    expect(h.audio.calls.where((c) => c.startsWith('play:$first')), hasLength(2));
    await h.playThrough(first);
    expect(h.starts, 3);
  });

  test('the mic level follows the recognizer while listening and drops to zero after', () async {
    await h.controller.startListening();
    h.recognizer.emit(const SoundLevel(0.5));
    await h.flush();
    expect(h.container.read(micLevelProvider), 0.5);
    await h.say('नमस्ते');
    expect(h.container.read(micLevelProvider), 0);
  });

  test('the session starts with its first turn', () async {
    expect(h.state.sessionStartedAt, isNull);
    await h.controller.startListening();
    expect(h.state.sessionStartedAt, h.now);
  });

  test('pause keeps words already heard: they are translated, not spoken', () async {
    await h.controller.startListening();
    final id = h.activeId;
    h.recognizer.emit(const PartialResult('नमस्ते आप'));
    await h.flush();
    await h.controller.pause();
    expect(h.recognizer.stops, 1, reason: 'stop, not cancel, so the final result arrives');
    expect(h.recognizer.cancels, 0);
    h.recognizer.emit(const FinalResult('नमस्ते आप कैसे हैं'));
    await h.flush();
    expect(h.seg(id).status, SegmentStatus.translated);
    expect(h.seg(id).speech, SpeechStatus.none);
    expect(h.audio.calls.where((c) => c.startsWith('play:')), isEmpty);
    expect(h.starts, 1);
  });
}
