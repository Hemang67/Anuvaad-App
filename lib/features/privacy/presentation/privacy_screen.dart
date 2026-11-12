import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/anuvaad_colors.dart';
import '../../../core/config/app_config.dart';
import '../../../l10n/app_localizations.dart';

/// Privacy & data (spec R33, §13): what leaves the phone, where it goes, what is kept, and the controls.
/// Matches the website's Privacy page.
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    final api = ref.watch(appConfigProvider).apiBaseUrl;
    final sections = [
      (l10n.privacyLeavesTitle, [l10n.privacyLeavesUpdates, l10n.privacyLeavesAudio, l10n.privacyLeavesText, l10n.privacyLeavesVoices]),
      (l10n.privacyGoesTitle, [l10n.privacyGoesServer, l10n.privacyGoesOffline, l10n.privacyGoesReleases]),
      (l10n.privacyStoredTitle, [l10n.privacyStoredAudio, l10n.privacyStoredVoiceFiles, l10n.privacyStoredHistory, l10n.privacyStoredLatency]),
      (l10n.privacyControlsTitle, [l10n.privacyControlsHistory, l10n.privacyControlsMic]),
    ];
    return Scaffold(
      key: const Key('privacy-screen'),
      appBar: AppBar(title: Text(l10n.settingsPrivacyData)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            for (final (title, points) in sections)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: tokens.ink)),
                      const SizedBox(height: 8),
                      for (final point in points)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('•  ', style: TextStyle(color: tokens.blue, fontWeight: FontWeight.w800)),
                              Expanded(child: Text(point, style: TextStyle(color: tokens.ink, height: 1.4))),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (api != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => launchUrl(api.replace(path: '/privacy'), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.open_in_new),
                  label: Text(l10n.privacyFullPage),
                ),
              ),
            const SizedBox(height: 8),
            Text(l10n.privacyContact, style: TextStyle(color: tokens.muted)),
          ],
        ),
      ),
    );
  }
}
