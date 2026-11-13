import 'audio_output.dart';
import 'translation.dart';

/// Who is talking: the other person (Listen) or the user (Speak).
enum Speaker { other, me }

/// Face to face, or a meeting played on a speaker in the room (Listen only).
enum ConversationMode { inPerson, meeting }

/// [unclear]: final text whose language isn't certain; it waits for the user to pick before translating.
enum SegmentStatus { listening, translating, translated, failed, unclear }

/// The spoken half of a translated segment.
/// [awaitingReview]: a reply held for the user to check before it plays ("Review my reply before playing").
enum SpeechStatus { none, preparing, playing, played, failed, noVoice, awaitingReview }

/// One utterance: live text while listening, then its translation. [id] is stable across updates.
class Segment {
  const Segment({
    required this.id,
    required this.seq,
    required this.speaker,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.startedAt,
    this.text = '',
    this.isFinal = false,
    this.translation,
    this.status = SegmentStatus.listening,
    this.offlineNotReady = false,
    this.finalAt,
    this.translatedAt,
    this.speech = SpeechStatus.none,
    this.output,
    this.detected = false,
    this.speechStartAt,
    this.speechEndAt,
    this.firstPartialAt,
    this.synthesizedAt,
    this.playbackStartedAt,
  });

  final String id;

  /// Order of creation, starting at 1.
  final int seq;
  final Speaker speaker;
  final String sourceLanguage;
  final String targetLanguage;
  final String text;
  final bool isFinal;
  final Translation? translation;
  final SegmentStatus status;

  /// Failed because offline translation models aren't downloaded yet.
  final bool offlineNotReady;

  // Stage timestamps (spec R34), kept in memory only.
  final DateTime startedAt;
  final DateTime? finalAt;
  final DateTime? translatedAt;

  /// More stage timestamps for the latency report (spec §14.2): never summed, each stage measured on its own.
  final DateTime? speechStartAt;
  final DateTime? speechEndAt;
  final DateTime? firstPartialAt;
  final DateTime? synthesizedAt;
  final DateTime? playbackStartedAt;

  final SpeechStatus speech;

  /// The device Android actually played the translation on (never the requested one).
  final AudioOutput? output;

  /// The source language came from the recognizer's confident detection (shown as "Detected").
  final bool detected;

  Segment copyWith({
    Speaker? speaker,
    String? sourceLanguage,
    String? targetLanguage,
    bool? detected,
    DateTime? speechStartAt,
    DateTime? speechEndAt,
    DateTime? firstPartialAt,
    DateTime? synthesizedAt,
    DateTime? playbackStartedAt,
    String? text,
    bool? isFinal,
    Translation? translation,
    SegmentStatus? status,
    bool? offlineNotReady,
    DateTime? finalAt,
    DateTime? translatedAt,
    SpeechStatus? speech,
    AudioOutput? output,
  }) =>
      Segment(
        id: id,
        seq: seq,
        speaker: speaker ?? this.speaker,
        sourceLanguage: sourceLanguage ?? this.sourceLanguage,
        targetLanguage: targetLanguage ?? this.targetLanguage,
        startedAt: startedAt,
        text: text ?? this.text,
        isFinal: isFinal ?? this.isFinal,
        translation: translation ?? this.translation,
        status: status ?? this.status,
        offlineNotReady: offlineNotReady ?? this.offlineNotReady,
        finalAt: finalAt ?? this.finalAt,
        translatedAt: translatedAt ?? this.translatedAt,
        speech: speech ?? this.speech,
        output: output ?? this.output,
        detected: detected ?? this.detected,
        speechStartAt: speechStartAt ?? this.speechStartAt,
        speechEndAt: speechEndAt ?? this.speechEndAt,
        firstPartialAt: firstPartialAt ?? this.firstPartialAt,
        synthesizedAt: synthesizedAt ?? this.synthesizedAt,
        playbackStartedAt: playbackStartedAt ?? this.playbackStartedAt,
      );
}
