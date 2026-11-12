import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/anuvaad_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../language_settings/application/language_preferences_controller.dart';
import '../application/conversation_controller.dart';
import '../application/mic_level.dart';
import '../application/session_status.dart';
import '../domain/segment.dart';

/// Top of the live screen (prototype "Live conversation"): status chip, waveform and the other person's language.
class SessionHeader extends ConsumerWidget {
  const SessionHeader({super.key, required this.languageName, required this.choices});

  final String Function(String code) languageName;

  /// The languages the other person may speak (the core languages that aren't mine).
  final List<({String code, String name})> choices;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    final state = ref.watch(conversationControllerProvider);
    final prefsOther = ref.watch(languagePreferencesProvider).otherLanguage;
    final status = sessionStatus(state);
    final other = state.otherLanguageOverride ?? (prefsOther == autoDetect ? null : prefsOther);
    final languageLine = other == null
        ? l10n.headerTheirLanguageAuto
        : state.otherLanguageDetected
            ? l10n.headerTheirLanguageDetected(languageName(other))
            : l10n.headerTheirLanguage(languageName(other));
    final hearing = status == SessionStatus.listening || status == SessionStatus.recording;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              _StatusChip(status: status),
              Text(
                state.mode == ConversationMode.meeting ? l10n.modeMeeting : l10n.modeInPerson,
                style: TextStyle(color: tokens.muted, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _Waveform(active: hearing && state.activeSpeaker != null),
          Row(
            children: [
              Expanded(child: Text(languageLine, style: TextStyle(color: tokens.ink, fontWeight: FontWeight.w600))),
              if (!state.ended)
                TextButton(
                  key: const Key('change-language'),
                  onPressed: () => _chooseLanguage(context, ref),
                  child: Text(l10n.headerChange),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _chooseLanguage(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.headerChooseTitle, style: Theme.of(sheet).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final choice in choices)
                    ChoiceChip(
                      label: Text(choice.name),
                      selected: ref.read(conversationControllerProvider).otherLanguageOverride == choice.code,
                      onSelected: (_) {
                        ref.read(conversationControllerProvider.notifier).chooseOtherLanguage(choice.code);
                        Navigator.of(sheet).pop();
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The one thing the session is doing now; announced to screen readers when it changes.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final SessionStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    final (label, color) = switch (status) {
      SessionStatus.ready => (l10n.statusReady, tokens.muted),
      SessionStatus.listening => (l10n.statusListening, tokens.green),
      SessionStatus.recording => (l10n.statusRecording, tokens.green),
      SessionStatus.choosingLanguage => (l10n.statusChoosingLanguage, tokens.blue),
      SessionStatus.translating => (l10n.statusTranslating, tokens.blue),
      SessionStatus.speaking => (l10n.statusSpeaking, tokens.blue),
      SessionStatus.reviewing => (l10n.statusReviewing, tokens.blue),
      SessionStatus.paused => (l10n.statusPaused, tokens.muted),
      SessionStatus.ended => (l10n.statusEnded, tokens.muted),
    };
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: tokens.soft, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label, style: TextStyle(fontSize: 11, letterSpacing: 1.1, fontWeight: FontWeight.w800, color: tokens.ink)),
            ),
          ],
        ),
      ),
    );
  }
}

/// 17 bars that follow the microphone level while a turn is listening; flat otherwise.
class _Waveform extends ConsumerWidget {
  const _Waveform({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    final level = active ? ref.watch(micLevelProvider) : 0.0;
    return ExcludeSemantics(
      child: SizedBox(
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 17; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 4,
                height: 4 + level * 32 * (0.35 + 0.65 * sin(i * 0.9 + 1).abs()),
                decoration: BoxDecoration(
                  color: active ? tokens.blue : tokens.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
