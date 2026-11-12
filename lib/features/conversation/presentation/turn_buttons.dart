import 'package:flutter/material.dart';

import '../../../app/theme/anuvaad_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../application/conversation_controller.dart';
import '../domain/segment.dart';

/// Listen ↔ Pause (left) and Speak ↔ Stop (right), with End conversation below once something has started.
/// After End, a Summary button reopens the summary.
class TurnButtons extends StatelessWidget {
  const TurnButtons({
    super.key,
    required this.state,
    required this.listenHint,
    required this.speakHint,
    required this.onListen,
    required this.onPause,
    required this.onSpeak,
    required this.onStop,
    required this.onEnd,
    required this.onSummary,
  });

  final ConversationState state;
  final String listenHint;
  final String speakHint;
  final VoidCallback onListen;
  final VoidCallback onPause;
  final VoidCallback onSpeak;
  final VoidCallback onStop;
  final VoidCallback onEnd;
  final VoidCallback onSummary;

  static const _size = Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (state.ended) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton.tonalIcon(
          key: const Key('summary-button'),
          onPressed: onSummary,
          icon: const Icon(Icons.summarize_outlined),
          label: Text(l10n.summaryOpen),
          style: FilledButton.styleFrom(minimumSize: _size),
        ),
      );
    }
    final meeting = state.mode == ConversationMode.meeting;
    final started = state.sessionStartedAt != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _withHint(context, _left(context), listenHint)),
              if (!meeting) ...[
                const SizedBox(width: 12),
                Expanded(child: _withHint(context, _right(context), speakHint)),
              ],
            ],
          ),
          if (started) ...[
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                key: const Key('end-button'),
                onPressed: onEnd,
                icon: const Icon(Icons.stop_circle_outlined),
                label: Text(l10n.conversationEnd),
                style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ],
      ),
    );
  }

  RoundedRectangleBorder get _shape => RoundedRectangleBorder(borderRadius: BorderRadius.circular(18));

  Widget _left(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final recording = state.activeSpeaker == Speaker.me;
    if (state.listenMode) {
      return KeyedSubtree(
        key: const Key('pause-button'),
        child: FilledButton.tonalIcon(
          onPressed: recording ? null : onPause,
          icon: const Icon(Icons.pause),
          label: Text(l10n.conversationPause),
          style: FilledButton.styleFrom(minimumSize: _size, shape: _shape),
        ),
      );
    }
    return KeyedSubtree(
      key: const Key('listen-button'),
      child: FilledButton.icon(
        onPressed: recording ? null : onListen,
        icon: const Icon(Icons.hearing),
        label: Text(l10n.conversationListen),
        style: FilledButton.styleFrom(minimumSize: _size, shape: _shape),
      ),
    );
  }

  Widget _right(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (state.activeSpeaker == Speaker.me) {
      return KeyedSubtree(
        key: const Key('stop-button'),
        child: FilledButton.icon(
          onPressed: onStop,
          icon: const Icon(Icons.mic),
          label: Text(l10n.conversationStop),
          // White in both themes: the dark theme's onPrimary is navy, unreadable on red.
          style: FilledButton.styleFrom(
            minimumSize: _size,
            shape: _shape,
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }
    return KeyedSubtree(
      key: const Key('speak-button'),
      child: FilledButton.tonalIcon(
        onPressed: onSpeak,
        icon: const Icon(Icons.mic_none),
        label: Text(l10n.conversationSpeak),
        style: FilledButton.styleFrom(minimumSize: _size, shape: _shape),
      ),
    );
  }

  Widget _withHint(BuildContext context, Widget button, String hint) {
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    return Column(
      children: [
        button,
        const SizedBox(height: 6),
        Text(hint, textAlign: TextAlign.center, style: TextStyle(color: tokens.muted, fontSize: 12)),
      ],
    );
  }
}
