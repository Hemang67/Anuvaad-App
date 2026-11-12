import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap.dart';
import '../../../app/theme/anuvaad_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/language_registry/language.dart';
import '../../conversation/data/android_audio.dart';
import '../../conversation/data/offline_models.dart';
import '../../conversation/domain/voice.dart';
import '../application/language_status.dart';
import '../application/language_preferences_controller.dart';

class LanguagesScreen extends ConsumerStatefulWidget {
  const LanguagesScreen({super.key});

  @override
  ConsumerState<LanguagesScreen> createState() => _LanguagesScreenState();
}

class _LanguagesScreenState extends ConsumerState<LanguagesScreen> {
  late LanguagePreferences _draft = ref.read(languagePreferencesProvider);
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    // Back from Android's voice settings: read every status again.
    _lifecycle = AppLifecycleListener(onResume: () => ref.invalidate(languageStatusProvider));
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }

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
                detail: '',
                status: _CoreStatus(language: language),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: tokens.soft, borderRadius: BorderRadius.circular(12)),
                  child: Text(l10n.languagesCoreChip, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: tokens.blue)),
                ),
              ),
            const SizedBox(height: 18),
            _SectionRow(title: l10n.languagesMoreTitle, subtitle: l10n.languagesMoreSubtitle),
            const SizedBox(height: 10),
            for (final language in ref.watch(plannedLanguagesProvider).value ?? registry.plannedLanguages)
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
  const _LanguageRow({required this.language, required this.detail, required this.trailing, this.title, this.status});
  final Language language;
  final String? title;
  final String detail;
  final Widget trailing;

  /// Core languages: what works on this phone, under the name.
  final Widget? status;

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
                    if (detail.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(detail, style: TextStyle(color: tokens.muted, fontSize: 12)),
                    ],
                    ?status,
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

enum _Network { wifiOnly, any }

/// Speech input, offline translation and voice for one core language, with Download and Install voice.
class _CoreStatus extends ConsumerStatefulWidget {
  const _CoreStatus({required this.language});

  final Language language;

  @override
  ConsumerState<_CoreStatus> createState() => _CoreStatusState();
}

class _CoreStatusState extends ConsumerState<_CoreStatus> {
  bool _downloading = false;

  Future<void> _download() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final network = await showDialog<_Network>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.languagesDownloadTitle),
        content: Text(l10n.languagesDownloadBody(widget.language.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(),
            child: Text(MaterialLocalizations.of(dialog).cancelButtonLabel),
          ),
          TextButton(onPressed: () => Navigator.of(dialog).pop(_Network.any), child: Text(l10n.languagesAnyNetwork)),
          FilledButton(onPressed: () => Navigator.of(dialog).pop(_Network.wifiOnly), child: Text(l10n.languagesWifiOnly)),
        ],
      ),
    );
    if (network == null || !mounted) return;
    setState(() => _downloading = true);
    final ok = await ref.read(offlineModelsProvider).downloadNow(widget.language.code, wifiOnly: network == _Network.wifiOnly);
    if (!mounted) return;
    setState(() => _downloading = false);
    ref.invalidate(languageStatusProvider(widget.language.code));
    if (!ok) messenger.showSnackBar(SnackBar(content: Text(l10n.languagesDownloadFailed)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    final code = widget.language.code;
    final status = ref.watch(languageStatusProvider(code)).value;
    if (status == null) return const SizedBox(height: 4);

    Widget line(bool ok, String text, [Widget? action]) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(ok ? Icons.check_circle : Icons.info_outline, size: 16, color: ok ? tokens.green : tokens.muted),
              const SizedBox(width: 6),
              Expanded(child: Text(text, style: TextStyle(color: tokens.muted, fontSize: 12))),
              ?action,
            ],
          ),
        );

    final compact = TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 8));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        line(status.speechInput, status.speechInput ? l10n.languageSpeechReady : l10n.languageSpeechMissing),
        line(
          status.offlineModel,
          status.offlineModel ? l10n.languageModelReady : l10n.languageModelMissing,
          status.offlineModel
              ? null
              : _downloading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : TextButton(
                      key: Key('download-model-$code'),
                      style: compact,
                      onPressed: _download,
                      child: Text(l10n.languagesDownload),
                    ),
        ),
        line(
          status.voice == VoiceAvailability.available,
          switch (status.voice) {
            VoiceAvailability.available => l10n.languageVoiceReady,
            VoiceAvailability.needsDownload => l10n.languageVoiceDownload,
            VoiceAvailability.unsupported => l10n.languageVoiceMissing,
          },
          status.voice == VoiceAvailability.available
              ? null
              : TextButton(
                  key: Key('install-voice-$code'),
                  style: compact,
                  onPressed: () => ref.read(speechSynthProvider).openVoiceInstall(code),
                  child: Text(l10n.conversationInstallVoice),
                ),
        ),
      ],
    );
  }
}

