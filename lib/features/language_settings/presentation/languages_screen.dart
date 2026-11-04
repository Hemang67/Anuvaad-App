import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap.dart';
import '../../../app/theme/anuvaad_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/language_registry/language.dart';
import '../application/language_preferences_controller.dart';

class LanguagesScreen extends ConsumerStatefulWidget {
  const LanguagesScreen({super.key});

  @override
  ConsumerState<LanguagesScreen> createState() => _LanguagesScreenState();
}

class _LanguagesScreenState extends ConsumerState<LanguagesScreen> {
  late LanguagePreferences _draft = ref.read(languagePreferencesProvider);

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(languagePreferencesProvider.notifier).save(_draft);
    messenger.showSnackBar(SnackBar(content: Text(l10n.languagesSaved)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final registry = ref.watch(languageRegistryProvider);
    final core = registry.coreLanguages;
    final canSwap = _draft.otherLanguage != autoDetect;

    return Scaffold(
      key: const Key('languages-screen'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            Text(l10n.languagesTitle, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: tokens.ink)),
            const SizedBox(height: 8),
            Text(l10n.languagesIntro(core.length), style: TextStyle(color: tokens.muted, height: 1.4)),
            const SizedBox(height: 20),
            _LanguageField(
              fieldKey: const Key('my-language-field'),
              label: l10n.languagesMyLabel,
              value: _draft.myLanguage,
              items: [for (final l in core) (l.code, l.nativeFirstLabel)],
              onChanged: (code) => setState(
                () => _draft = LanguagePreferences(myLanguage: code, otherLanguage: _draft.otherLanguage),
              ),
            ),
            Center(
              child: IconButton(
                tooltip: l10n.languagesSwap,
                onPressed: canSwap ? () => setState(() => _draft = swapLanguages(_draft)) : null,
                icon: const Icon(Icons.swap_vert),
              ),
            ),
            _LanguageField(
              fieldKey: const Key('other-language-field'),
              label: l10n.languagesOtherLabel,
              value: _draft.otherLanguage,
              items: [(autoDetect, l10n.languagesAutoDetect), for (final l in core) (l.code, l.nativeFirstLabel)],
              onChanged: (code) => setState(
                () => _draft = LanguagePreferences(myLanguage: _draft.myLanguage, otherLanguage: code),
              ),
            ),
            if (!_draft.isValid)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(l10n.languagesSameLanguage, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            const SizedBox(height: 24),
            _SectionRow(title: l10n.languagesIncludedTitle, subtitle: l10n.languagesIncludedCount(core.length)),
            const SizedBox(height: 10),
            for (final language in core)
              _LanguageRow(
                language: language,
                detail: _capabilityLine(l10n, language.capabilities),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: tokens.soft, borderRadius: BorderRadius.circular(12)),
                  child: Text(l10n.languagesCoreChip, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: tokens.blue)),
                ),
              ),
            const SizedBox(height: 18),
            _SectionRow(title: l10n.languagesMoreTitle, subtitle: l10n.languagesMoreSubtitle),
            const SizedBox(height: 10),
            for (final language in registry.plannedLanguages)
              _LanguageRow(
                language: language,
                title: language.displayName,
                detail: l10n.languagesPackDetail(language.nativeName),
                trailing: TextButton(
                  onPressed: () => ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text(l10n.languagesPackPlanned(language.displayName)))),
                  child: Text(l10n.languagesSoon),
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _draft.isValid ? _save : null,
                child: Text(l10n.languagesSave),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capabilityLine(AppLocalizations l10n, LanguageCapabilities c) => [
        if (c.speechRecognition) l10n.capabilitySpeechInput,
        if (c.translationInput && c.translationOutput) l10n.capabilityTranslation,
        if (c.textToSpeech) l10n.capabilityVoiceOutput,
      ].join(' · ');
}

class _LanguageField extends StatelessWidget {
  const _LanguageField({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final Key fieldKey;
  final String label;
  final String value;
  final List<(String, String)> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, letterSpacing: 1.1, fontWeight: FontWeight.w800, color: tokens.muted)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: fieldKey,
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: tokens.card,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: tokens.line)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: tokens.line)),
          ),
          items: [for (final (code, text) in items) DropdownMenuItem(value: code, child: Text(text))],
          onChanged: (code) {
            if (code != null) onChanged(code);
          },
        ),
      ],
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: tokens.ink))),
        Text(subtitle, style: TextStyle(color: tokens.muted, fontSize: 12)),
      ],
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({required this.language, required this.detail, required this.trailing, this.title});
  final Language language;
  final String? title;
  final String detail;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: tokens.soft, borderRadius: BorderRadius.circular(12)),
                child: Text(language.shortLabel, style: TextStyle(fontWeight: FontWeight.w800, color: tokens.blue)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title ?? language.nameFirstLabel, style: TextStyle(fontWeight: FontWeight.w700, color: tokens.ink)),
                    const SizedBox(height: 2),
                    Text(detail, style: TextStyle(color: tokens.muted, fontSize: 12)),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
