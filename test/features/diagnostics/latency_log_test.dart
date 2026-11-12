import 'dart:io';

import 'package:anuvaad/features/conversation/domain/segment.dart';
import 'package:anuvaad/features/conversation/domain/translation.dart';
import 'package:anuvaad/features/diagnostics/data/latency_log.dart';
import 'package:anuvaad/features/diagnostics/domain/latency_sample.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/latency_fixtures.dart';

void main() {
  late Directory root;
  late LatencyLog log;

  setUp(() {
    root = Directory.systemTemp.createTempSync('anuvaad_latency_test');
    log = LatencyLog(() async => root);
  });
  tearDown(() => root.deleteSync(recursive: true));

  test('the log keeps the last 1000 and contains no text', () async {
    final segment = Segment(
      id: 's1',
      seq: 1,
      speaker: Speaker.other,
      sourceLanguage: 'hi-IN',
      targetLanguage: 'en-IN',
      startedAt: DateTime(2026, 11, 6, 10),
      text: 'नमस्ते secret words',
      isFinal: true,
      translation: const Translation(segmentId: 's1', text: 'hello secret', provenance: TranslationProvenance.online, provider: 'cloudflare'),
      status: SegmentStatus.translated,
      finalAt: DateTime(2026, 11, 6, 10, 0, 2),
      translatedAt: DateTime(2026, 11, 6, 10, 0, 3),
    );
    await log.record(LatencySample.fromSegment(segment, at: DateTime(2026, 11, 6, 10, 1)));
    final file = File('${root.path}${Platform.pathSeparator}latency.jsonl');
    expect(file.readAsStringSync(), isNot(contains('secret')));
    expect(file.readAsStringSync(), isNot(contains('नमस्ते')));
    expect((await log.samples()).single.translationMs, 1000);

    for (var i = 0; i < 1004; i++) {
      await log.record(latencySample(translation: i));
    }
    final samples = await log.samples();
    expect(samples, hasLength(1000));
    expect(samples.first.translationMs, 4, reason: 'the oldest are dropped');
    expect(samples.last.translationMs, 1003);
  });

  test('clear empties the log, and a damaged line is skipped', () async {
    await log.record(latencySample());
    File('${root.path}${Platform.pathSeparator}latency.jsonl').writeAsStringSync('{"broken": \n', mode: FileMode.append);
    await log.record(latencySample(translation: 7));
    expect((await log.samples()).map((s) => s.translationMs), [600, 7]);
    await log.clear();
    expect(await log.samples(), isEmpty);
  });

  test('CSV has a header row and one row per sample', () {
    final csv = latencyCsv([latencySample(), latencySample(translation: null)], deviceModel: 'Pixel 7', androidVersion: '15', appVersion: '0.4.0+4');
    final lines = csv.trim().split('\n');
    expect(lines, hasLength(3));
    expect(lines.first,
        'at,pair,speaker,provider,provenance,output,onset_to_first_partial_ms,speech_end_to_final_ms,translation_ms,synthesis_ms,'
        'playback_start_ms,speech_end_to_audio_ms,device,android,app');
    expect(lines[1], '2026-11-06T10:00:00.000,hi-IN→en-IN,other,cloudflare,online,bluetooth,400,800,600,300,100,1800,Pixel 7,15,0.4.0+4');
    expect(lines[2], contains(',800,,300,'));
  });
}
