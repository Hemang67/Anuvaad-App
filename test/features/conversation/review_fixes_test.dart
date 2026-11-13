import 'dart:async';

import 'package:anuvaad/core/permissions/microphone_permission.dart';
import 'package:anuvaad/features/conversation/application/conversation_controller.dart';
import 'package:anuvaad/features/conversation/domain/audio_output.dart';
import 'package:anuvaad/features/conversation/domain/segment.dart';
import 'package:anuvaad/features/conversation/domain/speech_recognition.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/conversation_fakes.dart';
import '../../helpers/conversation_harness.dart';

/// isAvailable() waits for [gate] (a slow platform round trip); stops failing after [failLimit] starts.
class _GatedRecognizer extends FakeSpeechRecognizer {
  Completer<void>? gate;
  int failLimit = 1 << 30;

  @override
  Future<bool> isAvailable() async {
    final g = gate;
    if (g != null) await g.future;
    return available;
  }

  @override
  Future<void> start(String locale, {List<String> detectAmong = const []}) async {
    if (started.length >= failLimit) failOnStart = null;
    await super.start(locale, detectAmong: detectAmong);
  }
}

/// A permission prompt the user takes [delay] to answer (the clock moves meanwhile).
class _SlowPermission extends FakeMicrophonePermission {
  _SlowPermission(this.onAsk) : super(current: MicPermission.denied);
  final void Function() onAsk;

  @override
  Future<MicPermission> request() async {
    onAsk();
    current = MicPermission.granted;
    return MicPermission.granted;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final h = ConversationHarness();
  late _GatedRecognizer r;

  setUp(() async {
    await h.setUp();
    r = _GatedRecognizer();
    h.recognizer = r;
    h.rebuild();
  });
  tearDown(() => h.tearDown());

  group('the microphone never opens after Pause, End or the background (I1)', () {
    test('End while a Listen turn is still starting', () async {
      r.gate = Completer<void>();
      final listening = h.controller.startListening();
      await h.flush();
      await h.controller.endSession();
      r.gate!.complete();
      await listening;
      await h.flush();
      expect(h.starts, 0);
    });

    test('End during the automatic re-arm after playback', () async {
      await h.controller.startListening();
      final id = await h.say('नमस्ते');
      r.gate = Completer<void>();
      await h.playThrough(id);
      await h.controller.endSession();
      r.gate!.complete();
      await h.flush();
      expect(h.starts, 1);
    });

    test('Pause during the automatic re-arm', () async {
      await h.controller.startListening();
      final id = await h.say('नमस्ते');
      r.gate = Completer<void>();
      await h.playThrough(id);
      await h.controller.pause();
      r.gate!.complete();
      await h.flush();
      expect(h.starts, 1);
    });
  });

  test('a recognizer that reports silence instantly does not loop (I6)', () async {
    r.failOnStart = RecognitionErrorCode.noMatch;
    r.failLimit = 50;
    await h.controller.startListening();
    for (var i = 0; i < 20; i++) {
      await h.flush();
    }
    expect(h.starts, lessThan(5));
    expect(h.state.paused, isTrue);
    expect(h.state.notice, ConversationNotice.generic);
  });

  test('Speak while the other person is mid-sentence keeps and translates their words (I4)', () async {
    await h.controller.startListening();
    final theirs = h.activeId;
    r.emit(const PartialResult('नमस्ते आप कैसे'));
    await h.flush();
    final speaking = h.controller.startSpeaking();
    await h.flush();
    expect(r.stops, 1, reason: 'their turn is finished, not thrown away');
    r.emit(const FinalResult('नमस्ते आप कैसे हैं'));
    await speaking;
    await h.flush();
    expect(h.seg(theirs).text, 'नमस्ते आप कैसे हैं');
    expect(h.seg(theirs).status, SegmentStatus.translated);
    expect(h.recognizer.started.last, 'en-IN');
  });

  test('Speak keeps their partial words even if the final result never comes (I4)', () async {
    await h.controller.startListening();
    final theirs = h.activeId;
    r.emit(const PartialResult('नमस्ते आप'));
    await h.flush();
    await h.controller.startSpeaking();
    await h.flush();
    expect(h.seg(theirs).text, 'नमस्ते आप');
    expect(h.seg(theirs).isFinal, isTrue);
    expect(h.recognizer.started.last, 'en-IN');
  });

  test('noMatch after partial words keeps them and Listen mode carries on (I5)', () async {
    await h.controller.startListening();
    final id = h.activeId;
    r.emit(const PartialResult('हाँ'));
    await h.flush();
    r.emit(const RecognitionError(RecognitionErrorCode.noMatch));
    await h.flush();
    expect(h.seg(id).isFinal, isTrue);
    expect(h.state.notice, isNull);
    expect(h.state.listenMode, isTrue);
  });

  test('time spent answering the microphone prompt is not counted as silence', () async {
    h.mic = _SlowPermission(() => h.now = h.now.add(const Duration(seconds: 40)));
    h.rebuild();
    await h.controller.startListening();
    h.now = h.now.add(const Duration(seconds: 30));
    r.emit(const RecognitionError(RecognitionErrorCode.speechTimeout));
    await h.flush();
    expect(h.state.listenMode, isTrue, reason: '30 s of listening is not a minute of silence');
    expect(h.state.notice, isNull);
  });

  test('a reviewed reply records no stages that include the review time (I7)', () async {
    await h.prefs.setBool('review_reply', true);
    h.rebuild();
    await h.controller.startSpeaking();
    final id = await h.say('Hello');
    h.now = h.now.add(const Duration(seconds: 20));
    await h.controller.playReply(id);
    h.audio.emit(PlaybackStarted(id, fakeSpeaker));
    await h.flush();
    final sample = (await h.latency.samples()).single;
    expect(sample.translationMs, isNotNull);
    expect(sample.synthesisMs, isNull);
    expect(sample.playbackStartMs, isNull);
    expect(sample.speechEndToAudioMs, isNull);
  });

  test('a playback longer than the watchdog is not cut off once it has started (M1)', () async {
    h.watchdog = const Duration(milliseconds: 300);
    h.rebuild();
    await h.controller.startListening();
    final id = await h.say('a very long sentence');
    h.audio.emit(PlaybackStarted(id, fakeSpeaker));
    await h.flush();
    final before = h.audio.calls.length;
    await Future<void>.delayed(const Duration(milliseconds: 450));
    await h.flush();
    expect(h.audio.calls.sublist(before), isNot(contains('stop')));
    expect(h.seg(id).speech, SpeechStatus.playing);
  });

  test('a translation that lands after Done is still saved (I10)', () async {
    await h.prefs.setBool('save_history', true);
    h.rebuild();
    await h.controller.startListening();
    final id = h.activeId;
    final gate = h.cloud.gates[id] = Completer<void>();
    r.emit(const FinalResult('नमस्ते'));
    await h.flush();
    await h.controller.endSession();
    h.close();
    gate.complete();
    await h.flush();
    expect((await h.history.list()).single.segments.single.translation, 'EN:नमस्ते');
    h.container = h.build();
  });

  test('an edited reply whose retranslation fails no longer blocks Listen mode (M2)', () async {
    await h.prefs.setBool('review_reply', true);
    h.rebuild();
    await h.controller.startListening();
    await h.controller.startSpeaking();
    final id = await h.say('Hello');
    h.cloud.error = StateError('down');
    h.offline.error = StateError('no model');
    await h.controller.editReply(id, 'Hello there');
    await h.flush();
    expect(h.seg(id).status, SegmentStatus.failed);
    expect(h.seg(id).speech, isNot(SpeechStatus.awaitingReview));
    expect(h.recognizer.started.last, 'hi-IN', reason: 'listening resumed');
  });

  testWidgets('with history on, going to the background keeps what was said (I8)', (tester) async {
    await tester.runAsync(() async {
      await h.prefs.setBool('save_history', true);
      h.rebuild();
      await h.controller.startListening();
      await h.say('नमस्ते');
    });
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.runAsync(h.flush);
    final saved = await tester.runAsync(() => h.history.list());
    expect(saved!.single.segments.single.translation, 'EN:नमस्ते');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  group('automatic detection (M3, M7)', () {
    setUp(() async {
      h.other = 'auto';
      r.detectionSupported = true;
      h.rebuild();
    });

    test('Change mid-turn never relabels text heard by the old-language recognizer', () async {
      await h.controller.startListening();
      expect(h.recognizer.started, ['hi-IN']);
      h.controller.chooseOtherLanguage('gu-IN');
      final id = await h.say('आप कहाँ जा रहे हैं');
      expect(h.seg(id).sourceLanguage, 'hi-IN');
      expect(h.cloud.requests.single.sourceLanguage, 'hi-IN');
      expect(h.state.otherLanguageOverride, 'gu-IN', reason: 'the language the user picked stays for the next turn');
    });

    test('a language picked with Change is not overridden by detection', () async {
      h.controller.chooseOtherLanguage('gu-IN');
      await h.controller.startListening();
      expect(h.recognizer.started, ['gu-IN']);
      expect(r.startDetectAmong, isEmpty);
    });

    test('a meeting in an explicit language does not detect', () async {
      await h.controller.startMeeting('gu-IN');
      expect(h.recognizer.started, ['gu-IN']);
      expect(r.startDetectAmong, isEmpty);
    });
  });
}
