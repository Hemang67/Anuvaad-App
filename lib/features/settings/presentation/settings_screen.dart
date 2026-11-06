import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap.dart';
import '../../../app/routes.dart';
import '../../../app/theme/anuvaad_colors.dart';
import '../../../app/theme/theme_mode_controller.dart';
import '../../../core/config/app_config.dart';
import '../../../l10n/app_localizations.dart';
import '../../app_update/application/update_controller.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    final info = ref.watch(packageInfoProvider);
    final mode = ref.watch(themeModeProvider);
    final config = ref.watch(appConfigProvider);
    final updatesEnabled = config.apiBaseUrl != null || config.releasesRepo != null;
    final checking = ref.watch(updateControllerProvider) is UpdateChecking;

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
