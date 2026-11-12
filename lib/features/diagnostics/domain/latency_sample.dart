import '../../conversation/domain/audio_output.dart';
import '../../conversation/domain/segment.dart';
import '../../conversation/domain/translation.dart';

/// How long each stage of one translated turn took (spec R34, §14.2). Each stage comes from its own two timestamps;
/// none is a sum of others. Holds no words: only the language pair, provider and route.
class LatencySample {
  const LatencySample({
    required this.at,
    required this.pair,
    required this.speaker,
    this.provider,
    this.provenance,
    this.output,
    this.onsetToFirstPartialMs,
    this.speechEndToFinalMs,
    this.translationMs,
    this.synthesisMs,
    this.playbackStartMs,
    this.speechEndToAudioMs,
  });

  /// Measures [s]. End of speech falls back to the final result when the recognizer didn't report it.
  factory LatencySample.fromSegment(Segment s, {required DateTime at, OutputKind? output}) {
    int? between(DateTime? from, DateTime? to) {
      if (from == null || to == null) return null;
      final ms = to.difference(from).inMilliseconds;
      return ms < 0 ? null : ms;
    }

    final speechEnd = s.speechEndAt ?? s.finalAt;
    return LatencySample(
      at: at,
      pair: '${s.sourceLanguage}→${s.targetLanguage}',
      speaker: s.speaker,
      provider: s.translation?.provider,
      provenance: s.translation?.provenance,
      output: output,
      onsetToFirstPartialMs: between(s.speechStartAt, s.firstPartialAt),
      speechEndToFinalMs: between(s.speechEndAt, s.finalAt),
      translationMs: between(s.finalAt, s.translatedAt),
      synthesisMs: between(s.translatedAt, s.synthesizedAt),
      playbackStartMs: between(s.synthesizedAt, s.playbackStartedAt),
      speechEndToAudioMs: between(speechEnd, s.playbackStartedAt),
    );
  }

  factory LatencySample.fromJson(Map<String, Object?> json) {
    T? named<T extends Enum>(List<T> values, Object? name) =>
        name is String ? values.where((v) => v.name == name).firstOrNull : null;
    int? ms(String key) => json[key] is int ? json[key] as int : null;
    return LatencySample(
      at: DateTime.parse(json['at']! as String),
      pair: json['pair']! as String,
      speaker: named(Speaker.values, json['speaker']) ?? Speaker.other,
      provider: json['provider'] as String?,
      provenance: named(TranslationProvenance.values, json['provenance']),
      output: named(OutputKind.values, json['output']),
      onsetToFirstPartialMs: ms('onsetToFirstPartialMs'),
      speechEndToFinalMs: ms('speechEndToFinalMs'),
      translationMs: ms('translationMs'),
      synthesisMs: ms('synthesisMs'),
      playbackStartMs: ms('playbackStartMs'),
      speechEndToAudioMs: ms('speechEndToAudioMs'),
    );
  }

  final DateTime at;

  /// "hi-IN→en-IN".
  final String pair;
  final Speaker speaker;
  final String? provider;
  final TranslationProvenance? provenance;
  final OutputKind? output;

  final int? onsetToFirstPartialMs;
  final int? speechEndToFinalMs;
  final int? translationMs;
  final int? synthesisMs;
  final int? playbackStartMs;

  /// The headline number: end of speech to the first translated audio (spec R35, target p95 < 3 s).
  final int? speechEndToAudioMs;

  Map<String, Object?> toJson() => {
        'at': at.toIso8601String(),
        'pair': pair,
        'speaker': speaker.name,
        'provider': provider,
        'provenance': provenance?.name,
        'output': output?.name,
        'onsetToFirstPartialMs': onsetToFirstPartialMs,
        'speechEndToFinalMs': speechEndToFinalMs,
        'translationMs': translationMs,
        'synthesisMs': synthesisMs,
        'playbackStartMs': playbackStartMs,
        'speechEndToAudioMs': speechEndToAudioMs,
      };
}
