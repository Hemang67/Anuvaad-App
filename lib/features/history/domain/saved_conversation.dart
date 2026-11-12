import '../../conversation/domain/segment.dart';
import '../../conversation/domain/translation.dart';

/// One saved line: what was said and its translation. No audio, ever.
class SavedSegment {
  const SavedSegment({
    required this.id,
    required this.seq,
    required this.speaker,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.text,
    required this.at,
    this.translation,
    this.provenance,
    this.unclear = false,
  });

  factory SavedSegment.fromJson(Map<String, Object?> json) => SavedSegment(
        id: json['id']! as String,
        seq: json['seq']! as int,
        speaker: Speaker.values.byName(json['speaker']! as String),
        sourceLanguage: json['sourceLanguage']! as String,
        targetLanguage: json['targetLanguage']! as String,
        text: json['text']! as String,
        translation: json['translation'] as String?,
        provenance: switch (json['provenance']) {
          final String name => TranslationProvenance.values.byName(name),
          _ => null,
        },
        unclear: json['unclear'] as bool? ?? false,
        at: DateTime.parse(json['at']! as String),
      );

  final String id;
  final int seq;
  final Speaker speaker;
  final String sourceLanguage;
  final String targetLanguage;
  final String text;

  /// Null when it was never translated (failed, unclear, or still in progress at End).
  final String? translation;
  final TranslationProvenance? provenance;
  final bool unclear;
  final DateTime at;

  Map<String, Object?> toJson() => {
        'id': id,
        'seq': seq,
        'speaker': speaker.name,
        'sourceLanguage': sourceLanguage,
        'targetLanguage': targetLanguage,
        'text': text,
        'translation': translation,
        'provenance': provenance?.name,
        'unclear': unclear,
        'at': at.toIso8601String(),
      };
}

/// A conversation the user chose to keep (history on, or Save after End). Stored only on the phone.
class SavedConversation {
  const SavedConversation({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.myLanguage,
    required this.otherLanguages,
    required this.mode,
    required this.segments,
  });

  static const schema = 1;

  /// Throws [FormatException] for anything that isn't a schema-1 conversation.
  factory SavedConversation.fromJson(Map<String, Object?> json) {
    if (json['schema'] != schema) throw FormatException('Unsupported history schema: ${json['schema']}');
    try {
      return SavedConversation(
        id: json['id']! as String,
        startedAt: DateTime.parse(json['startedAt']! as String),
        endedAt: DateTime.parse(json['endedAt']! as String),
        myLanguage: json['myLanguage']! as String,
        otherLanguages: [for (final code in json['otherLanguages']! as List) code as String],
        mode: ConversationMode.values.byName(json['mode']! as String),
        segments: [for (final s in json['segments']! as List) SavedSegment.fromJson((s as Map).cast<String, Object?>())],
      );
    } on TypeError catch (e) {
      throw FormatException('Malformed history entry: $e');
    } on ArgumentError catch (e) {
      throw FormatException('Malformed history entry: $e');
    }
  }

  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final String myLanguage;
  final List<String> otherLanguages;
  final ConversationMode mode;
  final List<SavedSegment> segments;

  Duration get duration => endedAt.difference(startedAt);

  Map<String, Object?> toJson() => {
        'schema': schema,
        'id': id,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt.toIso8601String(),
        'myLanguage': myLanguage,
        'otherLanguages': otherLanguages,
        'mode': mode.name,
        'segments': [for (final s in segments) s.toJson()],
      };
}
