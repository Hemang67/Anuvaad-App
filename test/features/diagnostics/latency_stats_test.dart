import 'package:anuvaad/features/conversation/domain/segment.dart';
import 'package:anuvaad/features/diagnostics/application/latency_stats.dart';
import 'package:anuvaad/features/diagnostics/domain/latency_sample.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/latency_fixtures.dart';

void main() {
  test('median and p95 by nearest rank, nulls skipped', () {
    final samples = [
      for (final ms in [400, 100, 300, 200]) latencySample(translation: ms),
      latencySample(translation: null),
      latencySample(pair: 'en-IN→gu-IN', translation: 900),
    ];
    final stats = statsByPair(samples, (s) => s.translationMs);
    expect(stats.keys, unorderedEquals(['hi-IN→en-IN', 'en-IN→gu-IN']));
    final hi = stats['hi-IN→en-IN']!;
    expect((hi.count, hi.median, hi.p95), (4, 200, 400));
    expect(stats['en-IN→gu-IN']!.median, 900);
  });

  test('a pair with no values for a stage is left out', () {
    final stats = statsByPair([latencySample(synthesis: null)], (s) => s.synthesisMs);
    expect(stats, isEmpty);
  });

  test('stages are measured separately, never summed', () {
    final segment = Segment(
      id: 's1',
      seq: 1,
      speaker: Speaker.other,
      sourceLanguage: 'hi-IN',
      targetLanguage: 'en-IN',
      startedAt: DateTime(2026, 11, 6, 10),
      speechEndAt: DateTime(2026, 11, 6, 10, 0, 3),
      playbackStartedAt: DateTime(2026, 11, 6, 10, 0, 5, 500),
    );
    final sample = LatencySample.fromSegment(segment, at: DateTime(2026, 11, 6, 10, 1));
    expect(sample.speechEndToAudioMs, 2500, reason: 'from the two timestamps, not a sum of stages');
    expect(sample.translationMs, isNull);
    expect(sample.synthesisMs, isNull);
    expect(sample.pair, 'hi-IN→en-IN');
  });
}
