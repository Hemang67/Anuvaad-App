import 'package:anuvaad/features/conversation/domain/segment.dart';
import 'package:anuvaad/features/conversation/domain/translation.dart';
import 'package:anuvaad/features/history/domain/saved_conversation.dart';

/// A saved English ↔ Hindi conversation: the other person's line (translated), my reply (not translated) and,
/// with [unclear], a line whose language was never confirmed.
SavedConversation savedConversation(
  String id,
  DateTime startedAt, {
  String text = 'नमस्ते',
  String? translation = 'Hello',
  bool unclear = false,
  TranslationProvenance provenance = TranslationProvenance.online,
}) =>
    SavedConversation(
      id: id,
      startedAt: startedAt,
      endedAt: startedAt.add(const Duration(minutes: 3)),
      myLanguage: 'en-IN',
      otherLanguages: const ['hi-IN'],
      mode: ConversationMode.inPerson,
      segments: [
        SavedSegment(
          id: '$id-1',
          seq: 1,
          speaker: Speaker.other,
          sourceLanguage: 'hi-IN',
          targetLanguage: 'en-IN',
          text: text,
          translation: translation,
          provenance: translation == null ? null : provenance,
          at: startedAt.add(const Duration(seconds: 5)),
        ),
        SavedSegment(
          id: '$id-2',
          seq: 2,
          speaker: Speaker.me,
          sourceLanguage: 'en-IN',
          targetLanguage: 'hi-IN',
          text: 'Fine, thanks',
          at: startedAt.add(const Duration(seconds: 20)),
        ),
        if (unclear)
          SavedSegment(
            id: '$id-3',
            seq: 3,
            speaker: Speaker.other,
            sourceLanguage: 'hi-IN',
            targetLanguage: 'en-IN',
            text: 'કેમ છો',
            unclear: true,
            at: startedAt.add(const Duration(seconds: 40)),
          ),
      ],
    );
