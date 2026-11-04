import 'package:anuvaad/features/language_settings/application/language_preferences_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('swapLanguages exchanges my and other language', () {
    final swapped = swapLanguages(const LanguagePreferences(myLanguage: 'gu-IN', otherLanguage: 'hi-IN'));
    expect(swapped.myLanguage, 'hi-IN');
    expect(swapped.otherLanguage, 'gu-IN');
  });

  test('swapLanguages throws when other is auto', () {
    expect(() => swapLanguages(const LanguagePreferences(myLanguage: 'gu-IN', otherLanguage: 'auto')), throwsArgumentError);
  });

  test('isValid rejects the same language on both sides but allows auto', () {
    expect(const LanguagePreferences(myLanguage: 'gu-IN', otherLanguage: 'gu-IN').isValid, isFalse);
    expect(const LanguagePreferences(myLanguage: 'gu-IN', otherLanguage: 'auto').isValid, isTrue);
    expect(const LanguagePreferences(myLanguage: 'gu-IN', otherLanguage: 'en-IN').isValid, isTrue);
  });
}
