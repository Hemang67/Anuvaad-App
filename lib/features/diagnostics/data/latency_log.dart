import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/latency_sample.dart';

/// The last [limit] latency samples, one JSON object per line in `<root>/latency.jsonl`, on the phone only.
/// Synchronous file work inside async methods, as in the history store (small file; widget tests' fake-async zone).
class LatencyLog {
  LatencyLog(this._root, {this.limit = 1000});

  final Future<Directory> Function() _root;
  final int limit;

  Future<File> _file() async => File('${(await _root()).path}${Platform.pathSeparator}latency.jsonl');

  Future<void> record(LatencySample sample) async {
    final file = await _file();
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('${jsonEncode(sample.toJson())}\n', mode: FileMode.append, flush: true);
    final lines = file.readAsLinesSync();
    if (lines.length > limit) file.writeAsStringSync('${lines.sublist(lines.length - limit).join('\n')}\n', flush: true);
  }

  /// Oldest first; damaged lines are skipped.
  Future<List<LatencySample>> samples() async {
    final file = await _file();
    if (!file.existsSync()) return const [];
    final samples = <LatencySample>[];
    for (final line in file.readAsLinesSync()) {
      if (line.trim().isEmpty) continue;
      try {
        samples.add(LatencySample.fromJson((jsonDecode(line) as Map).cast<String, Object?>()));
      } catch (error) {
        debugPrint('Skipping a damaged latency line: $error');
      }
    }
    return samples;
  }

  Future<void> clear() async {
    final file = await _file();
    if (file.existsSync()) file.deleteSync();
  }
}

final latencyLogProvider = Provider<LatencyLog>((ref) => LatencyLog(getApplicationSupportDirectory));

/// One header row, then one row per sample; empty cells for stages that weren't measured.
String latencyCsv(List<LatencySample> samples, {required String deviceModel, required String androidVersion, required String appVersion}) {
  String cell(Object? value) {
    final text = value?.toString() ?? '';
    return text.contains(',') || text.contains('"') ? '"${text.replaceAll('"', '""')}"' : text;
  }

  final out = StringBuffer(
    'at,pair,speaker,provider,provenance,output,onset_to_first_partial_ms,speech_end_to_final_ms,translation_ms,'
    'synthesis_ms,playback_start_ms,speech_end_to_audio_ms,device,android,app\n',
  );
  for (final s in samples) {
    out.writeln([
      s.at.toIso8601String(),
      s.pair,
      s.speaker.name,
      s.provider,
      s.provenance?.name,
      s.output?.name,
      s.onsetToFirstPartialMs,
      s.speechEndToFinalMs,
      s.translationMs,
      s.synthesisMs,
      s.playbackStartMs,
      s.speechEndToAudioMs,
      deviceModel,
      androidVersion,
      appVersion,
    ].map(cell).join(','));
  }
  return out.toString();
}
