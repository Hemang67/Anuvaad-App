import '../domain/latency_sample.dart';

/// Median and 95th percentile by nearest rank, in milliseconds.
class StageStats {
  const StageStats({required this.count, required this.median, required this.p95});

  final int count;
  final int median;
  final int p95;
}

/// One stage's stats per language pair; samples without that stage are skipped, and pairs with none are left out.
Map<String, StageStats> statsByPair(List<LatencySample> samples, int? Function(LatencySample) stage) {
  final byPair = <String, List<int>>{};
  for (final s in samples) {
    final value = stage(s);
    if (value != null) (byPair[s.pair] ??= []).add(value);
  }
  int rank(List<int> sorted, double p) => sorted[((p * sorted.length).ceil() - 1).clamp(0, sorted.length - 1)];
  return {
    for (final MapEntry(key: pair, value: values) in byPair.entries)
      pair: () {
        final sorted = [...values]..sort();
        return StageStats(count: sorted.length, median: rank(sorted, 0.5), p95: rank(sorted, 0.95));
      }(),
  };
}
