import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/anuvaad_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../conversation/application/output_router.dart';
import '../../conversation/data/android_audio.dart';
import '../../conversation/domain/audio_output.dart';

/// Where each voice plays (spec prototype "Audio devices"): microphone, translated voice for you, reply for them.
class AudioDevicesScreen extends ConsumerWidget {
  const AudioDevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    return Scaffold(
      key: const Key('audio-devices-screen'),
      appBar: AppBar(title: Text(l10n.audioDevicesTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(l10n.audioDevicesIntro, style: TextStyle(color: tokens.muted)),
            const SizedBox(height: 12),
            _SectionCard(
              icon: Icons.mic_none,
              title: l10n.audioMicTitle,
              subtitle: l10n.audioMicSubtitle,
              child: Text(l10n.audioMicPhone, style: TextStyle(fontWeight: FontWeight.w600, color: tokens.ink)),
            ),
            const _RoleCard(role: OutputRole.forMe, icon: Icons.headphones),
            const _RoleCard(role: OutputRole.forOther, icon: Icons.volume_up_outlined),
            const SizedBox(height: 8),
            Text(l10n.audioCompatibility, style: TextStyle(color: tokens.muted, fontSize: 12, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends ConsumerWidget {
  const _RoleCard({required this.role, required this.icon});

  final OutputRole role;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    final preference = ref.watch(outputPreferencesProvider)[role]!;
    final outputs = ref.watch(connectedOutputsProvider).value ?? const <AudioOutput>[];
    final target = resolveOutput(role, preference, outputs);
    final noEarphones = preference == OutputPreference.earphones && (target == null || !target.isEarphones);

    return _SectionCard(
      icon: icon,
      title: role == OutputRole.forMe ? l10n.audioForMeTitle : l10n.audioForOtherTitle,
      subtitle: role == OutputRole.forMe ? l10n.audioForMeSubtitle : l10n.audioForOtherSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<OutputPreference>(
            segments: [
              ButtonSegment(value: OutputPreference.earphones, icon: const Icon(Icons.headphones), label: Text(l10n.audioOptionEarphones)),
              ButtonSegment(value: OutputPreference.speaker, icon: const Icon(Icons.speaker_phone), label: Text(l10n.audioOptionSpeaker)),
            ],
            selected: {preference},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => ref.read(outputPreferencesProvider.notifier).select(role, selection.first),
          ),
          const SizedBox(height: 10),
          Text(
            noEarphones || target == null ? l10n.audioNoEarphones : l10n.audioNow(outputLabel(target, l10n)),
            style: TextStyle(color: tokens.muted),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: Key('test-sound-${role.name}'),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final routed = await ref.read(audioOutputProvider).playTestTone(deviceId: target?.id);
                // Report where Android actually played it, which may differ from the choice.
                if (routed != null) {
                  messenger
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text(l10n.audioTestPlayedOn(outputLabel(routed, l10n)))));
                }
              },
              icon: const Icon(Icons.play_arrow),
              label: Text(l10n.audioTestSound),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.icon, required this.title, required this.subtitle, required this.child});

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: tokens.soft, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: tokens.blue, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: tokens.ink)),
                      Text(subtitle, style: TextStyle(color: tokens.muted, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
