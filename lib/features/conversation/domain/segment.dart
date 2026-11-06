import 'translation.dart';

/// Who is talking: the other person (Listen) or the user (Speak).
enum Speaker { other, me }

enum SegmentStatus { listening, translating, translated, failed }

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

  Segment copyWith({
    String? text,
    bool? isFinal,
    Translation? translation,
    SegmentStatus? status,
    bool? offlineNotReady,
    DateTime? finalAt,
    DateTime? translatedAt,
  }) =>
      Segment(
        id: id,
        seq: seq,
        speaker: speaker,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
        startedAt: startedAt,
        text: text ?? this.text,
        isFinal: isFinal ?? this.isFinal,
        translation: translation ?? this.translation,
        status: status ?? this.status,
        offlineNotReady: offlineNotReady ?? this.offlineNotReady,
        finalAt: finalAt ?? this.finalAt,
        translatedAt: translatedAt ?? this.translatedAt,
      );
}
