import '../domain/segment.dart';
import 'conversation_controller.dart';

/// What the live screen shows at the top: the one thing the session is doing now.
enum SessionStatus { ready, listening, recording, choosingLanguage, translating, speaking, reviewing, paused, ended }

/// First match wins: ended, an active turn, a card waiting for its language, a reply under review, playback, translation work, paused, Listen mode.
SessionStatus sessionStatus(ConversationState s) {
  if (s.ended) return SessionStatus.ended;
  if (s.activeSpeaker == Speaker.other) return SessionStatus.listening;
  if (s.activeSpeaker == Speaker.me) return SessionStatus.recording;
  if (s.segments.any((x) => x.status == SegmentStatus.unclear)) return SessionStatus.choosingLanguage;
  if (s.segments.any((x) => x.speech == SpeechStatus.awaitingReview)) return SessionStatus.reviewing;
  if (s.segments.any((x) => x.speech == SpeechStatus.playing)) return SessionStatus.speaking;
  if (s.segments.any((x) => x.status == SegmentStatus.translating || x.speech == SpeechStatus.preparing)) {
    return SessionStatus.translating;
  }
  // Listen mode is waiting for the user to say which language they speak: the microphone is closed.
  if (s.notice == ConversationNotice.chooseOtherLanguage) return SessionStatus.choosingLanguage;
  if (s.paused) return SessionStatus.paused;
  if (s.listenMode) return SessionStatus.listening;
  return SessionStatus.ready;
}
