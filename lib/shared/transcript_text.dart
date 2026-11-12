import 'dart:math';

import 'package:intl/intl.dart';

import '../features/conversation/domain/segment.dart';
import '../l10n/app_localizations.dart';

/// One finished line of a conversation, from a live segment or a saved one.
class TranscriptLine {
  const TranscriptLine({
    required this.speaker,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.text,
    required this.at,
    this.translation,
    this.unclear = false,
  });

  final Speaker speaker;
  final String sourceLanguage;
  final String targetLanguage;
  final String text;
  final String? translation;
  final bool unclear;

  /// When it was said (the final result's time).
  final DateTime at;

  /// The finished lines of a live conversation, in order; cards still listening are left out.
  static List<TranscriptLine> fromSegments(List<Segment> segments) => [
        for (final s in segments)
          if (s.isFinal && s.text.trim().isNotEmpty)
            TranscriptLine(
              speaker: s.speaker,
              sourceLanguage: s.sourceLanguage,
              targetLanguage: s.targetLanguage,
              text: s.text,
              translation: s.status == SegmentStatus.translated ? s.translation?.text : null,
              unclear: s.status == SegmentStatus.unclear,
              at: s.finalAt ?? s.startedAt,
            ),
      ];
}

/// Whole minutes, at least 1, for headers and summaries.
int conversationMinutes(DateTime startedAt, DateTime? endedAt) =>
    max(1, ((endedAt ?? startedAt).difference(startedAt).inSeconds / 60).round());

/// "English ↔ Hindi" (or "English ↔ Hindi, Gujarati"): my language and the other languages heard.
String languagePairLabel(String myLanguage, List<TranscriptLine> lines, String Function(String code) languageName) {
  final others = <String>{
    for (final line in lines)
      for (final code in [line.sourceLanguage, line.targetLanguage])
        if (code != myLanguage) code,
  }.toList();
  return others.isEmpty ? languageName(myLanguage) : '${languageName(myLanguage)} ↔ ${others.map(languageName).join(', ')}';
}

/// Plain-text transcript for Copy and Share (spec §5-08): header, then each line with its translation.
String transcriptText({
  required List<TranscriptLine> lines,
  required String myLanguage,
  required String Function(String code) languageName,
  required AppLocalizations l10n,
  required DateTime startedAt,
  DateTime? endedAt,
}) {
  final date = DateFormat('d MMM yyyy, HH:mm', l10n.localeName).format(startedAt);
  final time = DateFormat('HH:mm:ss', l10n.localeName);
  final out = StringBuffer()
    ..writeln(l10n.transcriptHeader(date, conversationMinutes(startedAt, endedAt)))
    ..writeln(languagePairLabel(myLanguage, lines, languageName))
    ..writeln();
  for (final line in lines) {
    final who = line.speaker == Speaker.me ? l10n.transcriptYou : l10n.transcriptOtherPerson;
    final result = line.unclear ? l10n.transcriptUnclear : (line.translation ?? l10n.transcriptNotTranslated);
    out
      ..writeln('[${time.format(line.at)}] $who (${languageName(line.sourceLanguage)}): ${line.text}')
      ..writeln('  → ${languageName(line.targetLanguage)}: $result');
  }
  return out.toString();
}
