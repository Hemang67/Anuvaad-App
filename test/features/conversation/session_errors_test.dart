import 'package:anuvaad/features/conversation/application/conversation_controller.dart';
import 'package:anuvaad/features/conversation/domain/audio_output.dart';
import 'package:anuvaad/features/conversation/domain/segment.dart';
import 'package:anuvaad/features/conversation/domain/speech_recognition.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/conversation_fakes.dart';
import '../../helpers/conversation_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final h = ConversationHarness();

  setUp(() => h.setUp());
  tearDown(() => h.tearDown());

  void expectPaused(ConversationNotice notice) {
    expect(h.state.notice, notice);
    expect(h.state.paused, isTrue);
    expect(h.state.listenMode, isFalse);
  }

  test('a recognizer that fails at once pauses the session instead of looping', () async {
    h.recognizer.failOnStart = RecognitionErrorCode.busy;
    await h.controller.startListening();
    await h.flush();
    await h.flush();
    expect(h.starts, 1);
    expectPaused(ConversationNotice.busy);
  });

  test('network error during Listen mode pauses with the network notice', () async {
    await h.controller.startListening();
    h.recognizer.emit(const RecognitionError(RecognitionErrorCode.network));
    await h.flush();
    expect(h.starts, 1);
    expectPaused(ConversationNotice.network);
  });

  test('microphone permission revoked mid-session pauses with Allow', () async {
    await h.controller.startListening();
    h.recognizer.emit(const RecognitionError(RecognitionErrorCode.permission));
    await h.flush();
    expect(h.starts, 1);
    expectPaused(ConversationNotice.micDenied);
  });

  test('an error after some words keeps them, and still pauses', () async {
    await h.controller.startListening();
    final id = h.activeId;
    h.recognizer.emit(const PartialResult('नमस्ते आप'));
    h.recognizer.emit(const RecognitionError(RecognitionErrorCode.server));
    await h.flush();
    expect(h.seg(id).text, 'नमस्ते आप');
    expect(h.seg(id).isFinal, isTrue);
    expectPaused(ConversationNotice.network);
    await h.playThrough(id);
    expect(h.starts, 1);
  });

  test('a call or alarm during playback pauses the session', () async {
    await h.controller.startListening();
    final id = await h.say('नमस्ते');
    h.audio.emit(PlaybackStarted(id, fakeSpeaker));
    h.audio.emit(PlaybackFocusLost(id));
    await h.flush();
    expect(h.seg(id).speech, SpeechStatus.played);
    expectPaused(ConversationNotice.pausedForInterruption);
    expect(h.starts, 1);
  });

  test("earphones disconnecting doesn't pause the session", () async {
    h.audio.connected = [fakeSpeaker, fakeBuds];
    await h.controller.startListening();
    final id = await h.say('नमस्ते');
    h.audio.emit(PlaybackStarted(id, fakeBuds));
    await h.flush();
    h.audio.setOutputs([fakeSpeaker]);
    await h.flush();
    expect(h.state.notice, ConversationNotice.earphonesDisconnected);
    h.audio.emit(PlaybackCompleted(id));
    await h.flush();
    expect(h.state.listenMode, isTrue);
    expect(h.starts, 2);
    expect(h.state.notice, ConversationNotice.earphonesDisconnected, reason: 'listening again keeps the notice');
  });
}
