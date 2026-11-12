import 'package:anuvaad/features/conversation/domain/segment.dart';
import 'package:anuvaad/l10n/app_localizations_en.dart';
import 'package:anuvaad/shared/transcript_text.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  // The app's localizations load this; a plain test does it by hand.
  setUpAll(() => initializeDateFormatting('en'));

  test('transcriptText formats speakers, languages and untranslated lines', () {
    String name(String code) => const {'en-IN': 'English', 'hi-IN': 'Hindi', 'gu-IN': 'Gujarati'}[code]!;
    final text = transcriptText(
      lines: [
        TranscriptLine(
          speaker: Speaker.other,
          sourceLanguage: 'hi-IN',
          targetLanguage: 'en-IN',
          text: 'नमस्ते',
          translation: 'Hello',
          at: DateTime(2026, 11, 6, 10, 0, 5),
        ),
        TranscriptLine(
          speaker: Speaker.me,
          sourceLanguage: 'en-IN',
          targetLanguage: 'hi-IN',
          text: 'Fine, thanks',
          at: DateTime(2026, 11, 6, 10, 0, 20),
        ),
        TranscriptLine(
          speaker: Speaker.other,
          sourceLanguage: 'hi-IN',
          targetLanguage: 'en-IN',
          text: 'કેમ છો',
          unclear: true,
          at: DateTime(2026, 11, 6, 10, 1, 2),
        ),
      ],
      myLanguage: 'en-IN',
      languageName: name,
      l10n: AppLocalizationsEn(),
      startedAt: DateTime(2026, 11, 6, 10),
      endedAt: DateTime(2026, 11, 6, 10, 3, 10),
    );
    expect(
      text,
      'Anuvaad conversation · 6 Nov 2026, 10:00 · 3 min\n'
      'English ↔ Hindi\n'
      '\n'
      '[10:00:05] Other person (Hindi): नमस्ते\n'
      '  → English: Hello\n'
      '[10:00:20] You (English): Fine, thanks\n'
      '  → Hindi: Not translated\n'
      '[10:01:02] Other person (Hindi): કેમ છો\n'
      '  → English: Language unclear\n',
    );
  });

  test('a conversation under a minute still says 1 min', () {
    final text = transcriptText(
      lines: const [],
      myLanguage: 'en-IN',
      languageName: (c) => c,
      l10n: AppLocalizationsEn(),
      startedAt: DateTime(2026, 11, 6, 10),
      endedAt: DateTime(2026, 11, 6, 10, 0, 20),
    );
    expect(text.split('\n').first, endsWith('· 1 min'));
  });
}
