import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap.dart';
import '../../../app/theme/anuvaad_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/language_registry/language.dart';
import '../../conversation/application/voice_service.dart';
import '../../conversation/data/android_audio.dart';
import '../../conversation/domain/voice.dart';
import '../application/voice_preferences.dart';

/// A sentence per language for the Test button.
const _samples = {
  'en-IN': 'Hello, how are you?',
  'hi-IN': 'नमस्ते, आप कैसे हैं?',
  'gu-IN': 'નમસ્તે, તમે કેમ છો?',
};

final voiceOptionsProvider = FutureProvider.autoDispose.family<List<VoiceOption>, String>(
  (ref, language) => ref.watch(speechSynthProvider).voices(language),
);

/// Choose the voice for each language (spec §5-10 "voice"), with a test sentence.
class VoicesScreen extends ConsumerWidget {
  const VoicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    final languages = ref.watch(languageRegistryProvider).coreLanguages;
    return Scaffold(
      key: const Key('voices-screen'),
      appBar: AppBar(title: Text(l10n.voicesTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(l10n.voicesIntro, style: TextStyle(color: tokens.muted, height: 1.4)),
            const SizedBox(height: 12),
            for (final language in languages) _LanguageVoices(language: language),
          ],
        ),
      ),
    );
  }
}

class _LanguageVoices extends ConsumerWidget {
  const _LanguageVoices({required this.language});

  final Language language;

  Future<void> _test(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final path = await ref.read(voiceServiceProvider).synthesize(
            segmentId: 'voice-test-${language.code}',
            text: _samples[language.code] ?? language.nativeName,
            language: language.code,
          );
      await ref.read(audioOutputProvider).play(path: path, deviceId: null, playbackId: 'voice-test');
    } on VoiceMissing {
      messenger.showSnackBar(SnackBar(content: Text(l10n.voicesMissing(language.displayName))));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.voicesTestFailed)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    final chosen = ref.watch(voicePreferencesProvider).voices[language.code];
    final voices = (ref.watch(voiceOptionsProvider(language.code)).value ?? const <VoiceOption>[])
        .where((v) => v.installed)
        .toList();
    final notifier = ref.read(voicePreferencesProvider.notifier);
    Widget check(bool on) => on ? Icon(Icons.check, color: tokens.blue) : const SizedBox(width: 24);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(language.nameFirstLabel, style: TextStyle(fontWeight: FontWeight.w800, color: tokens.ink)),
                  ),
                  TextButton.icon(
                    key: Key('test-voice-${language.code}'),
                    onPressed: () => _test(context, ref),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(l10n.voicesTest),
                  ),
                ],
              ),
            ),
            ListTile(
              key: Key('voice-default-${language.code}'),
              title: Text(l10n.voicesDefault),
              subtitle: Text(l10n.voicesDefaultSubtitle),
              trailing: check(chosen == null || !voices.any((v) => v.name == chosen)),
              onTap: () => notifier.setVoice(language.code, null),
            ),
            for (final (i, voice) in voices.indexed)
              ListTile(
                title: Text(voice.network ? l10n.voicesOnline(i + 1) : l10n.voicesOnPhone(i + 1)),
                trailing: check(chosen == voice.name),
                onTap: () => notifier.setVoice(language.code, voice.name),
              ),
          ],
        ),
      ),
    );
  }
}
