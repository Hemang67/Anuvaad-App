import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap.dart';
import '../../../app/theme/anuvaad_colors.dart';
import '../../../app/theme/theme_mode_controller.dart';
import '../../../l10n/app_localizations.dart';
import 'widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    final info = ref.watch(packageInfoProvider);
    final mode = ref.watch(themeModeProvider);

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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
