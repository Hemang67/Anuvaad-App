import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_language.dart';
import '../../../app/bootstrap.dart';
import '../../../app/routes.dart';
import '../../../app/theme/anuvaad_colors.dart';
import '../../../app/theme/theme_mode_controller.dart';
import '../../../core/config/app_config.dart';
import '../../../l10n/app_localizations.dart';
import '../../app_update/application/update_controller.dart';
import '../../conversation/application/language_detection.dart';
import '../../conversation/application/review_reply.dart';
import '../../history/application/history_providers.dart';
import '../../voices/application/voice_preferences.dart';
import 'widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _checkForUpdates(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(updateControllerProvider.notifier).check(UpdateTrigger.manual);
    final state = ref.read(updateControllerProvider);
    final message = switch (state) {
      UpdateUpToDate() => l10n.settingsUpToDate,
      UpdateFailed(decision: null) => l10n.updateFailedCheck,
      _ => null, // an available update opens the update popup
    };
    if (message != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  /// Turning saving off with conversations already saved asks whether to keep them (spec §13: delete controls).
  Future<void> _setSaveHistory(BuildContext context, WidgetRef ref, bool on) async {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(saveHistoryProvider.notifier);
    if (on) return notifier.set(true);
    final repository = ref.read(historyRepositoryProvider);
    if ((await repository.list()).isEmpty || !context.mounted) return notifier.set(false);
    final keep = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.settingsKeepTitle),
        content: Text(l10n.settingsKeepBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialog).pop(true), child: Text(l10n.settingsKeep)),
          FilledButton(onPressed: () => Navigator.of(dialog).pop(false), child: Text(l10n.settingsDeleteAllButton)),
        ],
      ),
    );
    if (keep == null) return; // dismissed: nothing changes
    await notifier.set(false);
    if (!keep) {
      await repository.deleteAll();
      invalidateHistory(ref);
    }
  }

  Future<void> _deleteAll(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.settingsDeleteAllTitle),
        content: Text(l10n.historyDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(MaterialLocalizations.of(dialog).cancelButtonLabel),
          ),
          FilledButton(onPressed: () => Navigator.of(dialog).pop(true), child: Text(l10n.settingsDeleteAllButton)),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(historyRepositoryProvider).deleteAll();
    invalidateHistory(ref);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.settingsDeleteAllDone)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    final info = ref.watch(packageInfoProvider);
    final mode = ref.watch(themeModeProvider);
    final config = ref.watch(appConfigProvider);
    final updatesEnabled = config.apiBaseUrl != null || config.releasesRepo != null;
    final checking = ref.watch(updateControllerProvider) is UpdateChecking;
    // Android 14+ only; until the answer arrives the switch waits, disabled.
    final detection = ref.watch(detectionSupportedProvider).value ?? false;

    return Scaffold(
      key: const Key('settings-screen'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            Text(
              l10n.settingsTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: tokens.ink),
            ),
            const SizedBox(height: 18),
            SettingsSection(
              title: l10n.settingsAppearance,
              subtitle: l10n.settingsAppearanceDefault,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(value: ThemeMode.system, icon: const Icon(Icons.brightness_auto), label: Text(l10n.themeSystem)),
                      ButtonSegment(value: ThemeMode.light, icon: const Icon(Icons.light_mode_outlined), label: Text(l10n.themeLight)),
                      ButtonSegment(value: ThemeMode.dark, icon: const Icon(Icons.dark_mode_outlined), label: Text(l10n.themeDark)),
                    ],
                    selected: {mode},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) => ref.read(themeModeProvider.notifier).select(selection.first),
                  ),
                ),
                SettingsRow(
                  title: l10n.settingsAppLanguage,
                  trailing: DropdownButton<String>(
                    key: const Key('app-language'),
                    value: ref.watch(appLanguageProvider),
                    underline: const SizedBox.shrink(),
                    items: [
                      DropdownMenuItem(value: 'system', child: Text(l10n.appLanguageSystem)),
                      for (final code in appLanguages) DropdownMenuItem(value: code, child: Text(appLanguageNames[code]!)),
                    ],
                    onChanged: (code) {
                      if (code != null) ref.read(appLanguageProvider.notifier).select(code);
                    },
                  ),
                ),
              ],
            ),
            SettingsSection(
              title: l10n.settingsConversation,
              children: [
                SettingsRow(
                  title: l10n.settingsAutoDetect,
                  subtitle: detection ? l10n.settingsAutoDetectSubtitle : l10n.settingsAutoDetectUnsupported,
                  trailing: Switch(
                    key: const Key('auto-detect-switch'),
                    value: detection && ref.watch(autoDetectProvider),
                    onChanged: detection ? (on) => ref.read(autoDetectProvider.notifier).set(on) : null,
                  ),
                ),
                SettingsRow(
                  title: l10n.settingsReviewReply,
                  subtitle: l10n.settingsReviewReplySubtitle,
                  trailing: Switch(
                    key: const Key('review-reply-switch'),
                    value: ref.watch(reviewReplyProvider),
                    onChanged: (on) => ref.read(reviewReplyProvider.notifier).set(on),
                  ),
                ),
                SettingsRow(title: l10n.settingsSpeechSpeed),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: SegmentedButton<SpeechRate>(
                    key: const Key('speech-rate'),
                    segments: [
                      ButtonSegment(value: SpeechRate.slow, label: Text(l10n.speechRateSlow)),
                      ButtonSegment(value: SpeechRate.normal, label: Text(l10n.speechRateNormal)),
                      ButtonSegment(value: SpeechRate.fast, label: Text(l10n.speechRateFast)),
                    ],
                    selected: {ref.watch(voicePreferencesProvider).rate},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) => ref.read(voicePreferencesProvider.notifier).setRate(selection.first),
                  ),
                ),
                SettingsRow(
                  title: l10n.settingsVoices,
                  subtitle: l10n.settingsVoicesSubtitle,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(Routes.voices),
                ),
              ],
            ),
            SettingsSection(
              title: l10n.settingsAudio,
              children: [
                SettingsRow(
                  title: l10n.settingsAudioDevices,
                  subtitle: l10n.settingsAudioDevicesSubtitle,
                  onTap: () => context.push(Routes.audioDevices),
                ),
              ],
            ),
            SettingsSection(
              title: l10n.settingsPrivacy,
              children: [
                SettingsRow(
                  title: l10n.settingsSaveHistory,
                  subtitle: l10n.settingsSaveHistorySubtitle,
                  trailing: Switch(
                    key: const Key('save-history-switch'),
                    value: ref.watch(saveHistoryProvider),
                    onChanged: (on) => _setSaveHistory(context, ref, on),
                  ),
                ),
                SettingsRow(
                  title: l10n.settingsRawAudio,
                  trailing: Text(l10n.settingsRawAudioNever, style: TextStyle(color: tokens.muted, fontWeight: FontWeight.w600)),
                ),
                SettingsRow(
                  key: const Key('delete-all-history'),
                  title: l10n.settingsDeleteAll,
                  trailing: const Icon(Icons.delete_outline),
                  onTap: () => _deleteAll(context, ref),
                ),
                SettingsRow(
                  title: l10n.settingsPrivacyData,
                  subtitle: l10n.settingsPrivacyDataSubtitle,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(Routes.privacy),
                ),
              ],
            ),
            SettingsSection(
              title: l10n.settingsLanguagesSection,
              children: [
                SettingsRow(
                  title: l10n.settingsOfflineModels,
                  subtitle: l10n.settingsOfflineModelsSubtitle,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go(Routes.languages),
                ),
              ],
            ),
            SettingsSection(
              title: l10n.settingsDiagnostics,
              children: [
                SettingsRow(
                  title: l10n.settingsLatency,
                  subtitle: l10n.settingsLatencySubtitle,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(Routes.latency),
                ),
              ],
            ),
            SettingsSection(
              title: l10n.settingsAbout,
              children: [
                SettingsRow(
                  title: l10n.settingsAboutAnuvaad,
                  subtitle: l10n.poweredBy,
                  trailing: Text(
                    l10n.settingsVersion(info.version, info.buildNumber),
                    style: TextStyle(color: tokens.muted, fontWeight: FontWeight.w600),
                  ),
                ),
                SettingsRow(
                  title: l10n.settingsCheckUpdates,
                  subtitle: updatesEnabled ? null : l10n.settingsUpdatesUnavailable,
                  trailing: checking
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.system_update_outlined),
                  onTap: updatesEnabled && !checking ? () => _checkForUpdates(context, ref) : null,
                  enabled: updatesEnabled,
                ),
                SettingsRow(
                  title: l10n.settingsReleaseNotes,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: updatesEnabled ? () => context.go(Routes.releaseNotes) : null,
                  enabled: updatesEnabled,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
