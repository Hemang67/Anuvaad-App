import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/anuvaad_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/transcript_text.dart';
import '../application/conversation_controller.dart';

/// After End (spec §3.1 step 6): duration, languages, turns, and what to do with the transcript.
Future<void> showSessionSummary(
  BuildContext context, {
  required ConversationState state,
  required String myLanguage,
  required String Function(String code) languageName,
  required VoidCallback onDone,
}) {
  final lines = TranscriptLine.fromSegments(state.segments);
  final started = state.sessionStartedAt ?? state.sessionEndedAt ?? DateTime.now();
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) {
      final l10n = AppLocalizations.of(sheet);
      final tokens = Theme.of(sheet).extension<AnuvaadColors>()!;
      final muted = TextStyle(color: tokens.muted);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.summaryTitle,
                style: Theme.of(sheet).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: tokens.ink),
              ),
              const SizedBox(height: 8),
              Text(languagePairLabel(myLanguage, lines, languageName), style: TextStyle(color: tokens.ink, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 12,
                children: [
                  Text(l10n.summaryMinutes(conversationMinutes(started, state.sessionEndedAt)), style: muted),
                  Text(l10n.summaryTurns(lines.length), style: muted),
                ],
              ),
              const SizedBox(height: 16),
              if (lines.isNotEmpty)
                Consumer(
                  builder: (context, ref, _) {
                    final saved = ref.watch(conversationControllerProvider.select((s) => s.savedToHistory));
                    if (saved) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: tokens.green, size: 20),
                            const SizedBox(width: 6),
                            Text(l10n.summarySaved, style: TextStyle(color: tokens.ink, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: FilledButton.tonalIcon(
                        onPressed: () => ref.read(conversationControllerProvider.notifier).saveToHistory(),
                        icon: const Icon(Icons.bookmark_add_outlined),
                        label: Text(l10n.summarySave),
                      ),
                    );
                  },
                ),
              OutlinedButton.icon(
                onPressed: lines.isEmpty
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await Clipboard.setData(ClipboardData(
                          text: transcriptText(
                            lines: lines,
                            myLanguage: myLanguage,
                            languageName: languageName,
                            l10n: l10n,
                            startedAt: started,
                            endedAt: state.sessionEndedAt,
                          ),
                        ));
                        messenger
                          ..hideCurrentSnackBar()
                          ..showSnackBar(SnackBar(content: Text(l10n.summaryCopied)));
                      },
                icon: const Icon(Icons.copy_outlined),
                label: Text(l10n.summaryCopy),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () {
                  Navigator.of(sheet).pop();
                  onDone();
                },
                child: Text(l10n.summaryDone),
              ),
            ],
          ),
        ),
      );
    },
  );
}
