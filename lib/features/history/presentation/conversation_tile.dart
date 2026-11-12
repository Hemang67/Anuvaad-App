import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/anuvaad_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/transcript_text.dart';
import '../domain/saved_conversation.dart';

/// A saved conversation in a list (History, and Home's recent conversations): when, how long, which languages,
/// and its first line.
class ConversationTile extends StatelessWidget {
  const ConversationTile({super.key, required this.conversation, required this.languageName, required this.onTap});

  final SavedConversation conversation;
  final String Function(String code) languageName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    final lines = TranscriptLine.fromSaved(conversation.segments);
    final first = conversation.segments.isEmpty ? null : conversation.segments.first;
    final minutes = conversationMinutes(conversation.startedAt, conversation.endedAt);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('d MMM yyyy · HH:mm', l10n.localeName).format(conversation.startedAt),
                      style: TextStyle(color: tokens.muted, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: tokens.soft, borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      l10n.historyMinutesChip(minutes),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: tokens.blue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                languagePairLabel(conversation.myLanguage, lines, languageName),
                style: TextStyle(fontWeight: FontWeight.w800, color: tokens.ink),
              ),
              if (first != null) ...[
                const SizedBox(height: 4),
                Text(first.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: tokens.ink)),
                if (first.translation case final translation?)
                  Text(translation, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: tokens.muted)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
