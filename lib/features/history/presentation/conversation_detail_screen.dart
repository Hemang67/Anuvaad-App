import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/bootstrap.dart';
import '../../../app/theme/anuvaad_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/transcript_sharer.dart';
import '../../../shared/transcript_text.dart';
import '../../conversation/domain/segment.dart';
import '../../conversation/domain/translation.dart';
import '../application/history_providers.dart';
import '../domain/saved_conversation.dart';

/// One saved conversation (spec §5-08): both languages line by line, with Copy, Share and Delete.
class ConversationDetailScreen extends ConsumerWidget {
  const ConversationDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    final registry = ref.watch(languageRegistryProvider);
    String name(String code) => registry.byCode(code)?.displayName ?? code;
    final conversation = ref.watch(savedConversationProvider(id)).value;

    String text(SavedConversation c) => transcriptText(
          lines: TranscriptLine.fromSaved(c.segments),
          myLanguage: c.myLanguage,
          languageName: name,
          l10n: l10n,
          startedAt: c.startedAt,
          endedAt: c.endedAt,
        );

    return Scaffold(
      key: const Key('conversation-detail-screen'),
      appBar: AppBar(
        title: Text(l10n.historyDetailTitle),
        actions: [
          if (conversation != null) ...[
            IconButton(
              tooltip: l10n.historyCopy,
              icon: const Icon(Icons.copy_outlined),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await Clipboard.setData(ClipboardData(text: text(conversation)));
                messenger
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(l10n.summaryCopied)));
              },
            ),
            IconButton(
              tooltip: l10n.historyShare,
              icon: const Icon(Icons.share_outlined),
              onPressed: () => ref.read(transcriptSharerProvider).shareText(
                    text(conversation),
                    fileName: 'anuvaad-${DateFormat('yyyy-MM-dd-HHmm').format(conversation.startedAt)}.txt',
                  ),
            ),
            IconButton(
              tooltip: l10n.historyDelete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(context, ref),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: conversation == null
            ? Center(child: Text(l10n.historyNotFound, style: TextStyle(color: tokens.muted)))
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _Header(conversation: conversation, languageName: name),
                  const SizedBox(height: 12),
                  for (final segment in conversation.segments) _Line(segment: segment, languageName: name),
                ],
              ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.historyDeleteTitle),
        content: Text(l10n.historyDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(MaterialLocalizations.of(dialog).cancelButtonLabel),
          ),
          FilledButton(onPressed: () => Navigator.of(dialog).pop(true), child: Text(l10n.historyDelete)),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(historyRepositoryProvider).delete(id);
    await ref.read(transcriptSharerProvider).clearShared();
    invalidateHistory(ref);
    if (context.mounted) context.pop();
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.conversation, required this.languageName});

  final SavedConversation conversation;
  final String Function(String code) languageName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    final minutes = conversationMinutes(conversation.startedAt, conversation.endedAt);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              languagePairLabel(conversation.myLanguage, TranscriptLine.fromSaved(conversation.segments), languageName),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: tokens.ink),
            ),
            const SizedBox(height: 4),
            Text(
              '${DateFormat('d MMM yyyy · HH:mm', l10n.localeName).format(conversation.startedAt)} · '
              '${l10n.summaryMinutes(minutes)} · '
              '${conversation.mode == ConversationMode.meeting ? l10n.modeMeeting : l10n.modeInPerson}',
              style: TextStyle(color: tokens.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.segment, required this.languageName});

  final SavedSegment segment;
  final String Function(String code) languageName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    final mine = segment.speaker == Speaker.me;
    final language = languageName(segment.sourceLanguage).toUpperCase();
    final time = DateFormat('HH:mm:ss', l10n.localeName).format(segment.at);
    final translation = segment.translation;
    return Card(
      color: mine ? tokens.soft : tokens.card,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mine ? l10n.historyLineYou(language, time) : l10n.historyLineOther(language, time),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: tokens.muted, fontWeight: FontWeight.w700, letterSpacing: 1.1),
            ),
            const SizedBox(height: 6),
            Text(segment.text, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: tokens.ink)),
            Divider(height: 18, color: tokens.line),
            if (translation != null) ...[
              Text(translation, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: tokens.ink, fontWeight: FontWeight.w600)),
              if (segment.provenance == TranslationProvenance.offline)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(l10n.conversationOfflineLabel, style: TextStyle(fontSize: 11, color: tokens.muted, fontWeight: FontWeight.w700)),
                ),
            ] else
              Text(
                segment.unclear ? l10n.transcriptUnclear : l10n.transcriptNotTranslated,
                style: TextStyle(color: tokens.muted, fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
    );
  }
}
