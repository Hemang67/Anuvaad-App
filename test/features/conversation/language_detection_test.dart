import 'package:anuvaad/features/conversation/application/language_detection.dart';
import 'package:anuvaad/features/conversation/domain/speech_recognition.dart';
import 'package:flutter_test/flutter_test.dart';

const _allowed = ['hi-IN', 'gu-IN'];

({String locale, LanguageConfidence confidence}) _d(String locale, LanguageConfidence c) => (locale: locale, confidence: c);

DetectionOutcome _decide({
  String recognizedIn = 'hi-IN',
  String? stable,
  ({String locale, LanguageConfidence confidence})? detection,
  int words = 4,
}) =>
    decideSourceLanguage(recognizedIn: recognizedIn, stable: stable, detection: detection, allowed: _allowed, wordCount: words);

void main() {
  group('matchCoreLanguage', () {
    test('a detected short code matches its core language', () {
      for (final reported in ['hi', 'hi-in', 'HI-IN', 'hi_IN', 'hi-IN']) {
        expect(matchCoreLanguage(reported, _allowed), 'hi-IN', reason: reported);
      }
      expect(matchCoreLanguage('gu', _allowed), 'gu-IN');
    });

    test('a language outside the pair matches nothing', () {
      expect(matchCoreLanguage('mr-IN', _allowed), isNull);
      expect(matchCoreLanguage('en-IN', _allowed), isNull);
      expect(matchCoreLanguage('', _allowed), isNull);
    });
  });

  group('decideSourceLanguage', () {
    test('a not-confident detection never decides', () {
      expect(_decide(detection: _d('gu-IN', LanguageConfidence.notConfident)), isA<Unclear>());
      expect(_decide(detection: _d('gu-IN', LanguageConfidence.unknown)), isA<Unclear>());
      expect(
        _decide(stable: 'hi-IN', detection: _d('gu-IN', LanguageConfidence.notConfident)),
        isA<UseLanguage>().having((o) => o.code, 'code', 'hi-IN').having((o) => o.detected, 'detected', false),
      );
    });

    test('no stable language: a confident detection decides, nothing else does', () {
      expect(
        _decide(detection: _d('gu', LanguageConfidence.confident)),
        isA<UseLanguage>().having((o) => o.code, 'code', 'gu-IN').having((o) => o.detected, 'detected', true),
      );
      expect(_decide(), isA<Unclear>());
    });

    test('a detected language outside the pair is unclear', () {
      expect(_decide(detection: _d('mr-IN', LanguageConfidence.highlyConfident)), isA<Unclear>());
      // With a stable language, a borrowed English word is code-switching; only a sure outside language is unclear.
      expect(_decide(stable: 'hi-IN', detection: _d('en-IN', LanguageConfidence.confident)),
          isA<UseLanguage>().having((o) => o.code, 'code', 'hi-IN'));
      expect(_decide(stable: 'hi-IN', detection: _d('mr-IN', LanguageConfidence.highlyConfident)), isA<Unclear>());
    });

    test('a stable language holds without contrary evidence', () {
      expect(_decide(stable: 'hi-IN'), isA<UseLanguage>().having((o) => o.code, 'code', 'hi-IN'));
      expect(
        _decide(stable: 'hi-IN', detection: _d('hi-IN', LanguageConfidence.confident)),
        isA<UseLanguage>().having((o) => o.detected, 'detected', true).having((o) => o.switched, 'switched', false),
      );
    });

    test('switching needs strong evidence', () {
      expect(
        _decide(stable: 'hi-IN', detection: _d('gu-IN', LanguageConfidence.confident), words: 3),
        isA<UseLanguage>().having((o) => o.code, 'code', 'gu-IN').having((o) => o.switched, 'switched', true),
      );
      expect(
        _decide(stable: 'hi-IN', detection: _d('gu-IN', LanguageConfidence.highlyConfident), words: 1),
        isA<UseLanguage>().having((o) => o.code, 'code', 'gu-IN'),
      );
      expect(_decide(stable: 'hi-IN', detection: _d('gu-IN', LanguageConfidence.confident), words: 2), isA<Unclear>(),
          reason: 'a borrowed word or two is not a switch');
    });
  });

  test('without counting evidence, the language the recognizer listened in wins over a stable language changed mid-turn (M3)',
      () {
    expect(
      _decide(recognizedIn: 'hi-IN', stable: 'gu-IN'),
      isA<UseLanguage>().having((o) => o.code, 'code', 'hi-IN').having((o) => o.detected, 'detected', false),
    );
  });
}
