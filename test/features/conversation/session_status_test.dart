import 'package:anuvaad/features/conversation/application/conversation_controller.dart';
import 'package:anuvaad/features/conversation/application/session_status.dart';
import 'package:anuvaad/features/conversation/domain/segment.dart';
import 'package:flutter_test/flutter_test.dart';

Segment _seg({
  SegmentStatus status = SegmentStatus.translated,
  SpeechStatus speech = SpeechStatus.played,
  Speaker speaker = Speaker.other,
}) =>
    Segment(
      id: 's$status$speech',
      seq: 1,
      speaker: speaker,
      sourceLanguage: 'hi-IN',
      targetLanguage: 'en-IN',
      startedAt: DateTime(2026, 11, 6),
      isFinal: true,
      status: status,
      speech: speech,
    );

void main() {
  test('nothing going on is ready', () {
    expect(sessionStatus(const ConversationState()), SessionStatus.ready);
  });

  test('ended wins over everything', () {
    final s = ConversationState(ended: true, listenMode: true, activeSpeaker: Speaker.other, segments: [_seg(speech: SpeechStatus.playing)]);
    expect(sessionStatus(s), SessionStatus.ended);
  });

  test('an active turn is listening for them and recording for me', () {
    expect(sessionStatus(const ConversationState(activeSpeaker: Speaker.other)), SessionStatus.listening);
    expect(sessionStatus(const ConversationState(activeSpeaker: Speaker.me, paused: true)), SessionStatus.recording);
  });

  test('a reply waiting for review is reviewing', () {
    final s = ConversationState(segments: [_seg(speech: SpeechStatus.awaitingReview), _seg(speech: SpeechStatus.playing)]);
    expect(sessionStatus(s), SessionStatus.reviewing);
  });

  test('a playing translation is speaking', () {
    expect(sessionStatus(ConversationState(segments: [_seg(speech: SpeechStatus.playing)])), SessionStatus.speaking);
  });

  test('translating or preparing a voice is translating', () {
    expect(sessionStatus(ConversationState(segments: [_seg(status: SegmentStatus.translating, speech: SpeechStatus.none)])),
        SessionStatus.translating);
    expect(sessionStatus(ConversationState(segments: [_seg(speech: SpeechStatus.preparing)])), SessionStatus.translating);
  });

  test('paused, then listen mode between turns', () {
    expect(sessionStatus(const ConversationState(paused: true)), SessionStatus.paused);
    expect(sessionStatus(const ConversationState(listenMode: true)), SessionStatus.listening);
  });
}
