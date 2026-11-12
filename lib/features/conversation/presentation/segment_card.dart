import 'package:flutter/material.dart';

import '../../../app/theme/anuvaad_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../application/output_router.dart';
import '../domain/segment.dart';
import '../domain/translation.dart';

/// One utterance: who spoke, what was heard (live, then final) and its translation.
class SegmentCard extends StatelessWidget {
  const SegmentCard({
    super.key,
    required this.segment,
    required this.languageName,
    required this.onRetry,
    required this.onReplay,
    required this.onInstallVoice,
    this.unclearChoices = const [],
    this.onConfirmLanguage,
    this.onEditReply,
    this.onPlayReply,
    this.onDiscardReply,
  });

  final Segment segment;

  /// Display name for a registry code, e.g. 'Hindi'.
  final String Function(String code) languageName;
  final VoidCallback onRetry;
  final VoidCallback onReplay;
  final VoidCallback onInstallVoice;

  /// Languages offered when the card's language is unclear.
  final List<({String code, String name})> unclearChoices;
  final ValueChanged<String>? onConfirmLanguage;

  /// Review my reply before playing.
  final ValueChanged<String>? onEditReply;
  final VoidCallback? onPlayReply;
  final VoidCallback? onDiscardReply;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final mine = segment.speaker == Speaker.me;
    final language = languageName(segment.sourceLanguage).toUpperCase();

    final heard = segment.text.isEmpty && !segment.isFinal ? l10n.conversationListening : segment.text;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: 0.9,
        child: Card(
          color: mine ? tokens.soft : tokens.card,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mine
                      ? l10n.conversationYouLabel(language)
                      : segment.detected
                          ? l10n.conversationOtherLabelDetected(language)
                          : l10n.conversationOtherLabel(language),
                  style: textTheme.labelSmall?.copyWith(color: tokens.muted, fontWeight: FontWeight.w700, letterSpacing: 1.1),
                ),
                const SizedBox(height: 6),
                Text(
                  heard,
                  style: segment.isFinal
                      ? textTheme.bodyLarge?.copyWith(color: tokens.ink)
                      : textTheme.bodyLarge?.copyWith(color: tokens.muted, fontStyle: FontStyle.italic),
                ),
                if (segment.status != SegmentStatus.listening) ...[
                  Divider(height: 20, color: tokens.line),
                  ..._outcome(context, l10n, tokens, textTheme),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The spoken half: Playing…, or the device it played on with Replay, or the missing-voice line.
  Future<void> _edit(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final text = await showDialog<String>(
      context: context,
      builder: (dialog) => _EditReplyDialog(initial: segment.text, title: l10n.reviewEditTitle, action: l10n.reviewTranslateAgain),
    );
    if (text != null && text.trim().isNotEmpty) onEditReply?.call(text);
  }

  List<Widget> _speech(BuildContext context, AppLocalizations l10n, AnuvaadColors tokens) {
    final muted = TextStyle(color: tokens.muted, fontSize: 13);
    switch (segment.speech) {
      case SpeechStatus.awaitingReview:
        return [
          const SizedBox(height: 8),
          Text(l10n.reviewHint, style: muted),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 4,
              children: [
                TextButton(
                  key: Key('discard-${segment.id}'),
                  onPressed: onDiscardReply,
                  child: Text(l10n.reviewDiscard),
                ),
                TextButton.icon(
                  key: Key('edit-${segment.id}'),
                  onPressed: onEditReply == null ? null : () => _edit(context),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l10n.reviewEdit),
                ),
                FilledButton.tonalIcon(
                  key: Key('play-${segment.id}'),
                  onPressed: onPlayReply,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l10n.reviewPlay),
                ),
              ],
            ),
          ),
        ];
      case SpeechStatus.preparing:
        return const [];
      case SpeechStatus.playing:
        return [
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.volume_up, size: 16, color: tokens.blue),
            const SizedBox(width: 6),
            Text(l10n.conversationPlaying, style: muted),
          ]),
        ];
      case SpeechStatus.noVoice:
        return [
          const SizedBox(height: 8),
          Text(l10n.conversationNoVoice(languageName(segment.targetLanguage)), style: muted),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              alignment: WrapAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onInstallVoice,
                  icon: const Icon(Icons.download_outlined),
                  label: Text(l10n.conversationInstallVoice),
                ),
                // After installing the voice in Android's settings, this speaks it.
                TextButton.icon(
                  key: Key('replay-${segment.id}'),
                  onPressed: onReplay,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l10n.conversationReplay),
                ),
              ],
            ),
          ),
        ];
      case SpeechStatus.none || SpeechStatus.played || SpeechStatus.failed:
        final output = segment.output;
        return [
          const SizedBox(height: 4),
          Row(children: [
            if (output != null)
              Expanded(child: Text(l10n.conversationOutput(outputLabel(output, l10n)), style: muted))
            else
              const Spacer(),
            TextButton.icon(
              key: Key('replay-${segment.id}'),
              onPressed: onReplay,
              icon: const Icon(Icons.play_arrow),
              label: Text(l10n.conversationReplay),
            ),
          ]),
        ];
    }
  }

  List<Widget> _outcome(BuildContext context, AppLocalizations l10n, AnuvaadColors tokens, TextTheme textTheme) {
    switch (segment.status) {
      case SegmentStatus.translating:
        return [Text(l10n.conversationTranslating, style: TextStyle(color: tokens.muted))];
      case SegmentStatus.translated:
        final translation = segment.translation!;
        return [
          Text(translation.text, style: textTheme.titleMedium?.copyWith(color: tokens.ink, fontWeight: FontWeight.w600)),
          ..._speech(context, l10n, tokens),
          if (translation.provenance == TranslationProvenance.offline) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: tokens.bg, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, size: 14, color: tokens.muted),
                  const SizedBox(width: 4),
                  Text(l10n.conversationOfflineLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tokens.muted)),
                ],
              ),
            ),
          ],
        ];
      case SegmentStatus.failed:
        return [
          Text(
            segment.offlineNotReady ? l10n.translationOfflineNotReady : l10n.translationFailed,
            style: TextStyle(color: tokens.muted),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: Text(l10n.conversationRetry)),
          ),
        ];
      case SegmentStatus.unclear:
        return [
          Text(l10n.conversationLanguageUnclear, style: TextStyle(color: tokens.ink, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final choice in unclearChoices)
                ChoiceChip(
                  key: Key('unclear-${choice.code}'),
                  label: Text(choice.name),
                  selected: false,
                  onSelected: (_) => onConfirmLanguage?.call(choice.code),
                ),
            ],
          ),
        ];
      case SegmentStatus.listening:
        return const [];
    }
  }
}

/// Owns its text controller, so it lives until the dialog's closing animation is over.
class _EditReplyDialog extends StatefulWidget {
  const _EditReplyDialog({required this.initial, required this.title, required this.action});

  final String initial;
  final String title;
  final String action;

  @override
  State<_EditReplyDialog> createState() => _EditReplyDialogState();
}

class _EditReplyDialogState extends State<_EditReplyDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        content: TextField(controller: _controller, autofocus: true, maxLines: null),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(onPressed: () => Navigator.of(context).pop(_controller.text), child: Text(widget.action)),
        ],
      );
}
