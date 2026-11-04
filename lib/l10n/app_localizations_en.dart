// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Anuvaad';

  @override
  String get brandName => 'Anuvaad';

  @override
  String get brandTagline => 'Speak Any Language. Be Closer.';

  @override
  String get poweredBy => 'Powered by REA Intelligence';

  @override
  String get brandLogoLabel => 'Anuvaad logo';

  @override
  String get splashStartFailed => 'Anuvaad couldn\'t start. Please try again.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get navHome => 'Home';

  @override
  String get navLanguages => 'Languages';

  @override
  String get navSettings => 'Settings';

  @override
  String get listOr => ' or ';

  @override
  String get listAnd => ' and ';

  @override
  String onboardingWelcomeBody(String languages) {
    return 'Talk naturally with people who speak $languages.';
  }

  @override
  String get onboardingModesTitle => 'Two simple modes';

  @override
  String get onboardingListenTitle => 'Listen';

  @override
  String get onboardingListenBody =>
      'Anuvaad listens to the other person and plays the translation in your earphones.';

  @override
  String get onboardingSpeakTitle => 'Speak';

  @override
  String get onboardingSpeakBody =>
      'Reply in your own language. Anuvaad says it aloud in theirs.';

  @override
  String get onboardingPrivacyTitle => 'Your privacy';

  @override
  String get onboardingPrivacySpeech =>
      'Your speech is turned into text by your phone\'s speech service.';

  @override
  String get onboardingPrivacyText =>
      'The text is sent to the Anuvaad server to be translated. It isn\'t stored.';

  @override
  String get onboardingPrivacyStorage =>
      'Raw audio is never saved. History stays off unless you turn it on.';

  @override
  String get onboardingPrivacyQuality =>
      'Translation quality and speed can vary with your network and device.';

  @override
  String get onboardingPrivacyLink => 'Read the full privacy notice';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingGetStarted => 'Get started';
}
