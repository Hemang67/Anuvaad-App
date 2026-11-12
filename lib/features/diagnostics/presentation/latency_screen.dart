import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/bootstrap.dart';
import '../../../app/theme/anuvaad_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/transcript_sharer.dart';
import '../../app_update/application/update_controller.dart' show clockProvider;
import '../application/latency_stats.dart';
import '../data/latency_log.dart';
import '../domain/latency_sample.dart';

final latencySamplesProvider = FutureProvider.autoDispose<List<LatencySample>>(
  (ref) => ref.watch(latencyLogProvider).samples(),
);

/// Phone model and Android version for the CSV; "unknown" when Android won't say.
final deviceDescriptionProvider = FutureProvider<({String model, String android})>((ref) async {
  try {
    final info = await DeviceInfoPlugin().androidInfo;
    return (model: '${info.manufacturer} ${info.model}', android: info.version.release);
  } catch (_) {
    return (model: 'unknown', android: 'unknown');
  }
});

/// Settings → Latency report (spec R34/R35): per language pair, each stage's median and p95.
class LatencyScreen extends ConsumerWidget {
  const LatencyScreen({super.key});

  Future<void> _export(WidgetRef ref, List<LatencySample> samples) async {
    final device = await ref.read(deviceDescriptionProvider.future);
    final info = ref.read(packageInfoProvider);
    final now = ref.read(clockProvider)();
    await ref.read(transcriptSharerProvider).shareText(
          latencyCsv(samples, deviceModel: device.model, androidVersion: device.android, appVersion: '${info.version}+${info.buildNumber}'),
          fileName: 'anuvaad-latency-${DateFormat('yyyyMMdd-HHmm').format(now)}.csv',
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    final registry = ref.watch(languageRegistryProvider);
    String name(String code) => registry.byCode(code)?.displayName ?? code;
    final samples = ref.watch(latencySamplesProvider).value ?? const <LatencySample>[];

    final stages = <(String, int? Function(LatencySample))>[
      (l10n.latencyStageTotal, (s) => s.speechEndToAudioMs),
      (l10n.latencyStageFirstWords, (s) => s.onsetToFirstPartialMs),
      (l10n.latencyStageFinal, (s) => s.speechEndToFinalMs),
      (l10n.latencyStageTranslation, (s) => s.translationMs),
      (l10n.latencyStageVoice, (s) => s.synthesisMs),
      (l10n.latencyStagePlayback, (s) => s.playbackStartMs),
    ];
    final stats = [for (final (label, stage) in stages) (label, statsByPair(samples, stage))];
    final pairs = {for (final s in samples) s.pair}.toList()..sort();
    String seconds(int ms) => (ms / 1000).toStringAsFixed(1);

    return Scaffold(
      key: const Key('latency-screen'),
      appBar: AppBar(
        title: Text(l10n.latencyTitle),
        actions: [
          IconButton(
            tooltip: l10n.latencyExport,
            icon: const Icon(Icons.ios_share),
            onPressed: samples.isEmpty ? null : () => _export(ref, samples),
          ),
          IconButton(
            tooltip: l10n.latencyClear,
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: samples.isEmpty
                ? null
                : () async {
                    await ref.read(latencyLogProvider).clear();
                    ref.invalidate(latencySamplesProvider);
                  },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(l10n.latencyNote, style: TextStyle(color: tokens.muted)),
            const SizedBox(height: 4),
            Text(l10n.latencyTarget, style: TextStyle(color: tokens.ink, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (pairs.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Text(l10n.latencyEmpty, textAlign: TextAlign.center, style: TextStyle(color: tokens.muted)),
              ),
            for (final pair in pairs)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.latencyPair(name(pair.split('→').first), name(pair.split('→').last)),
                              style: TextStyle(fontWeight: FontWeight.w800, color: tokens.ink),
                            ),
                          ),
                          Text(
                            l10n.summaryTurns(samples.where((s) => s.pair == pair).length),
                            style: TextStyle(color: tokens.muted, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      for (final (label, byPair) in stats)
                        if (byPair[pair] case final stat?)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(label, style: TextStyle(color: tokens.ink)),
                                Text(
                                  l10n.latencyStats(seconds(stat.median), seconds(stat.p95)),
                                  style: TextStyle(color: tokens.muted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
