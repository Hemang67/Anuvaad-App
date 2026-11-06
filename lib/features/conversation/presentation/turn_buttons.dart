import 'package:flutter/material.dart';

import '../../../app/theme/anuvaad_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/segment.dart';

/// Listen (left) and Speak (right). While a turn is active, its button becomes Stop and the other is disabled.
class TurnButtons extends StatelessWidget {
  const TurnButtons({
    super.key,
    required this.activeSpeaker,
    required this.listenHint,
    required this.speakHint,
    required this.onStart,
    required this.onStop,
  });

  final Speaker? activeSpeaker;
  final String listenHint;
  final String speakHint;
  final ValueChanged<Speaker> onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _button(context, Speaker.other, listenHint)),
          const SizedBox(width: 12),
          Expanded(child: _button(context, Speaker.me, speakHint)),
        ],
      ),
    );
  }

  Widget _button(BuildContext context, Speaker speaker, String hint) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    final active = activeSpeaker == speaker;
    final enabled = activeSpeaker == null;
    final label = speaker == Speaker.other ? l10n.conversationListen : l10n.conversationSpeak;
    final icon = speaker == Speaker.other ? Icons.hearing : Icons.mic_none;
    const size = Size.fromHeight(56);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(18));

    final Widget button;
    if (active) {
      button = KeyedSubtree(
        key: const Key('stop-button'),
        child: FilledButton.icon(
          onPressed: onStop,
          icon: const Icon(Icons.mic),
          label: Text(l10n.conversationStop),
          // White in both themes: the dark theme's onPrimary is navy, unreadable on red.
          style: FilledButton.styleFrom(
            minimumSize: size,
            shape: shape,
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
          ),
        ),
      );
    } else {
      final onPressed = enabled ? () => onStart(speaker) : null;
      button = KeyedSubtree(
        key: Key(speaker == Speaker.other ? 'listen-button' : 'speak-button'),
        child: speaker == Speaker.other
            ? FilledButton.icon(
                onPressed: onPressed,
                icon: Icon(icon),
                label: Text(label),
                style: FilledButton.styleFrom(minimumSize: size, shape: shape),
              )
            : FilledButton.tonalIcon(
                onPressed: onPressed,
                icon: Icon(icon),
                label: Text(label),
                style: FilledButton.styleFrom(minimumSize: size, shape: shape),
              ),
      );
    }
    return Column(
      children: [
        button,
        const SizedBox(height: 6),
        Text(hint, textAlign: TextAlign.center, style: TextStyle(color: tokens.muted, fontSize: 12)),
      ],
    );
  }
}
