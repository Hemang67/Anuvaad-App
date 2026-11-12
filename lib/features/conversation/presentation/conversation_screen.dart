import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap.dart';
import '../../../app/routes.dart';
import '../../../app/theme/anuvaad_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../language_settings/application/language_preferences_controller.dart';
import '../application/conversation_controller.dart';
import '../application/output_router.dart';
import 'segment_card.dart';
import 'turn_buttons.dart';

/// In-person conversation (M2): live text and translations; spoken translations arrive in M3.
class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key});

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// What the cards show, apart from their speech lines.
  static int _contentKey(ConversationState s) => Object.hashAll([
        for (final x in s.segments)
          Object.hash(x.id, x.text, x.isFinal, x.status, x.translation?.text, x.translation?.provenance, x.offlineNotReady),
      ]);

  /// The newest card's speech line ("Playing…", or Output and Replay).
  static Object? _newestSpeechKey(ConversationState s) =>
      s.segments.isEmpty ? null : (s.segments.last.id, s.segments.last.speech, s.segments.last.output?.id);

  void _scrollToEnd({bool onlyIfAtEnd = false}) {
    // Measured before the change is laid out: someone reading an older card isn't pulled away.
    if (onlyIfAtEnd && _scroll.hasClients && _scroll.position.maxScrollExtent - _scroll.position.pixels > 48) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(conversationControllerProvider);
    final controller = ref.read(conversationControllerProvider.notifier);
    final registry = ref.watch(languageRegistryProvider);
    final prefs = ref.watch(languagePreferencesProvider);
    String name(String code) => registry.byCode(code)?.displayName ?? code;

    // Keep the newest line in view whenever a card's content changes (new card, live text, "Translating…", a
    // translation — including a late one on an older card, which pushes the newest down). Notices don't scroll.
    // The newest card's speech line scrolls only when the list is already at the end, so someone replaying an
    // older card stays where they are.
    ref.listen(conversationControllerProvider.select(_contentKey), (_, _) => _scrollToEnd());
    ref.listen(conversationControllerProvider.select(_newestSpeechKey), (_, _) => _scrollToEnd(onlyIfAtEnd: true));

    final other = state.otherLanguageOverride ?? prefs.otherLanguage;
    final listenHint = other == autoDetect ? l10n.languagesAutoDetect : l10n.conversationListenHint(name(other));

    return Scaffold(
      key: const Key('conversation-screen'),
      appBar: AppBar(
        title: Text(l10n.conversationTitle),
        actions: [
          IconButton(
            tooltip: l10n.audioDevicesTitle,
            icon: const Icon(Icons.headphones_outlined),
            onPressed: () => context.push(Routes.audioDevices),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: state.segments.isEmpty
                  ? const _EmptyState()
                  : ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      children: [
                        for (final segment in state.segments)
                          Padding(
                            key: ValueKey('segment-${segment.id}'),
                            padding: const EdgeInsets.only(bottom: 10),
                            child: SegmentCard(
                              segment: segment,
                              languageName: name,
                              onRetry: () => controller.retryTranslation(segment.id),
                              onReplay: () => controller.replay(segment.id),
                              onInstallVoice: () => controller.installVoice(segment.targetLanguage),
                            ),
                          ),
                      ],
                    ),
            ),
            if (state.notice case final notice?)
              _NoticeBanner(
                notice: notice,
                languageName: state.noticeLanguage == null ? null : name(state.noticeLanguage!),
                deviceName: state.noticeOutput == null ? null : outputLabel(state.noticeOutput!, l10n),
                choices: [
                  for (final language in registry.coreLanguages)
                    if (language.code != prefs.myLanguage) (code: language.code, name: language.displayName),
                ],
                controller: controller,
              ),
            TurnButtons(
              activeSpeaker: state.activeSpeaker,
              listenHint: listenHint,
              speakHint: l10n.conversationSpeakHint(name(prefs.myLanguage)),
              onStart: controller.startTurn,
              onStop: controller.stopTurn,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: tokens.soft, shape: BoxShape.circle),
              child: Icon(Icons.forum_outlined, size: 34, color: tokens.blue),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.conversationEmptyTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: tokens.ink),
            ),
            const SizedBox(height: 8),
            Text(l10n.conversationEmptyBody, textAlign: TextAlign.center, style: TextStyle(color: tokens.muted, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({
    required this.notice,
    required this.languageName,
    required this.deviceName,
    required this.choices,
    required this.controller,
  });

  final ConversationNotice notice;
  final String? languageName;
  final String? deviceName;
  final List<({String code, String name})> choices;
  final ConversationController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    final message = switch (notice) {
      ConversationNotice.chooseOtherLanguage => l10n.conversationChooseOtherLanguage,
      ConversationNotice.micDenied => l10n.noticeMicDenied,
      ConversationNotice.micPermanentlyDenied => l10n.noticeMicPermanentlyDenied,
      ConversationNotice.recognizerUnavailable => l10n.noticeRecognizerUnavailable,
      ConversationNotice.noSpeech => l10n.noticeNoSpeech,
      ConversationNotice.network => l10n.noticeNetwork,
      ConversationNotice.languageUnsupported => l10n.noticeLanguageUnsupported(languageName ?? ''),
      ConversationNotice.busy => l10n.noticeBusy,
      ConversationNotice.generic => l10n.noticeGeneric,
      ConversationNotice.earphonesDisconnected => l10n.noticeEarphonesDisconnected,
      ConversationNotice.speakerUnavailable => l10n.noticeSpeakerUnavailable(deviceName ?? ''),
      ConversationNotice.playbackFailed => l10n.noticePlaybackFailed,
      ConversationNotice.pausedForSilence => l10n.noticePausedForSilence,
      ConversationNotice.pausedForInterruption => l10n.noticePausedForInterruption,
      ConversationNotice.askToRepeat => l10n.noticeAskToRepeat(languageName ?? ''),
    };
    final action = switch (notice) {
      ConversationNotice.micDenied => TextButton(onPressed: controller.allowMicrophone, child: Text(l10n.conversationAllowMic)),
      ConversationNotice.micPermanentlyDenied =>
        TextButton(onPressed: controller.openMicrophoneSettings, child: Text(l10n.conversationOpenSettings)),
      _ => null,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Card(
        color: tokens.soft,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 4, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: tokens.blue, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(message, style: TextStyle(color: tokens.ink))),
                  IconButton(
                    onPressed: controller.dismissNotice,
                    tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
              if (notice == ConversationNotice.chooseOtherLanguage)
                Wrap(
                  spacing: 8,
                  children: [
                    for (final choice in choices)
                      ChoiceChip(
                        label: Text(choice.name),
                        selected: false,
                        onSelected: (_) => controller.chooseOtherLanguage(choice.code),
                      ),
                  ],
                ),
              ?action,
            ],
          ),
        ),
      ),
    );
  }
}
