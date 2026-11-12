import 'package:anuvaad/features/conversation/domain/audio_output.dart';
import 'package:anuvaad/features/conversation/domain/segment.dart';
import 'package:anuvaad/features/conversation/domain/translation.dart';
import 'package:anuvaad/features/diagnostics/domain/latency_sample.dart';

/// A Hindi → English sample whose stages take the given milliseconds (null leaves a stage out).
LatencySample latencySample({
  String pair = 'hi-IN→en-IN',
  int? firstPartial = 400,
  int? endToFinal = 800,
  int? translation = 600,
  int? synthesis = 300,
  int? playback = 100,
  int? endToAudio = 1800,
  DateTime? at,
}) =>
    LatencySample(
      at: at ?? DateTime(2026, 11, 6, 10),
      pair: pair,
      speaker: Speaker.other,
      provider: 'cloudflare',
      provenance: TranslationProvenance.online,
      output: OutputKind.bluetooth,
      onsetToFirstPartialMs: firstPartial,
      speechEndToFinalMs: endToFinal,
      translationMs: translation,
      synthesisMs: synthesis,
      playbackStartMs: playback,
      speechEndToAudioMs: endToAudio,
    );
