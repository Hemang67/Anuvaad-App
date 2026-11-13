import '../../../l10n/app_localizations.dart';
import '../domain/conversation_service.dart';
import '../domain/segment.dart';
import 'conversation_controller.dart';
import 'session_status.dart';

/// The ongoing-conversation notification for [s]: what is happening, the languages, the latest translation (shown
/// only where the phone allows private notification content), and the buttons that make sense right now.
SessionNotification sessionNotificationFor(
  ConversationState s, {
  required AppLocalizations l10n,
  required String myName,
  required String? otherName,
}) {
  final status = sessionStatus(s);
  final other = otherName ?? l10n.languagesAutoDetect;
  final inPerson = s.mode != ConversationMode.meeting;
  final reviewing = s.segments.any((x) => x.speech == SpeechStatus.awaitingReview);
  String? latest;
  for (final segment in s.segments) {
    latest = segment.translation?.text ?? latest;
  }
  return SessionNotification(
    title: switch (status) {
      SessionStatus.listening => otherName == null ? l10n.notifListening : l10n.notifListeningTo(otherName),
      SessionStatus.recording => l10n.notifYourTurn,
      SessionStatus.choosingLanguage => l10n.notifChooseLanguage,
      SessionStatus.translating => l10n.notifTranslating,
      SessionStatus.speaking => l10n.notifSpeaking,
      SessionStatus.reviewing => l10n.notifReviewing,
      SessionStatus.paused || SessionStatus.ended => l10n.notifPaused,
      SessionStatus.ready => l10n.notifReady,
    },
    text: inPerson ? '$myName ↔ $other' : l10n.notifMeeting(other),
    privateText: latest,
    actions: [
      if (reviewing) ...[
        SessionAction(SessionCommand.playReply, l10n.reviewPlay),
        SessionAction(SessionCommand.discardReply, l10n.reviewDiscard),
      ] else if (s.activeSpeaker == Speaker.me)
        SessionAction(SessionCommand.finishReply, l10n.notifDone)
      else if (s.listenMode && !s.paused) ...[
        if (inPerson) SessionAction(SessionCommand.speak, l10n.conversationSpeak),
        SessionAction(SessionCommand.pause, l10n.conversationPause),
      ] else ...[
        SessionAction(SessionCommand.listen, l10n.conversationListen),
        if (inPerson) SessionAction(SessionCommand.speak, l10n.conversationSpeak),
      ],
      SessionAction(SessionCommand.end, l10n.notifEnd),
    ],
    // Only while something is happening; waiting for the user (their language, a reply to review) needs no processor.
    active: const {SessionStatus.listening, SessionStatus.recording, SessionStatus.translating, SessionStatus.speaking}
        .contains(status),
  );
}
