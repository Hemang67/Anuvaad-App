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

  @override
  String get homeGreeting => 'YOUR PERSONAL LANGUAGE BRIDGE';

  @override
  String get homeHeadlineTop => 'Speak freely.';

  @override
  String get homeHeadlineBottom => 'Understand everyone.';

  @override
  String get homeHeroTitle => 'Your voice, understood worldwide.';

  @override
  String homeHeroBody(String languages) {
    return 'Real-time translation in $languages.';
  }

  @override
  String get homeModesTitle => 'Start communicating';

  @override
  String get homeModesSubtitle => 'Choose a mode';

  @override
  String get homeInPersonTitle => 'In-person conversation';

  @override
  String get homeInPersonSubtitle => 'Talk naturally face-to-face';

  @override
  String get homeMeetingTitle => 'Online meeting';

  @override
  String get homeMeetingSubtitle => 'Supported audio sources only';

  @override
  String get homeComingSoon => 'Coming in an update';

  @override
  String get homeMyLanguage => 'MY LANGUAGE';

  @override
  String get homeChange => 'Change';

  @override
  String get homeQuickAccessTitle => 'Quick access';

  @override
  String get homeQuickAccessSubtitle => 'Explore Anuvaad';

  @override
  String get languagesTitle => 'Languages';

  @override
  String languagesIntro(int count) {
    return 'Choose the language you understand and the language spoken by the other person. All $count core languages are included by default.';
  }

  @override
  String get languagesMyLabel => 'MY LANGUAGE · TRANSLATE INTO';

  @override
  String get languagesOtherLabel => 'OTHER PERSON · SPEAKING';

  @override
  String get languagesAutoDetect => 'Automatic detection';

  @override
  String get languagesSwap => 'Swap languages';

  @override
  String get languagesSameLanguage => 'Choose two different languages.';

  @override
  String get languagesIncludedTitle => 'Included by default';

  @override
  String languagesIncludedCount(int count) {
    return '$count core languages';
  }

  @override
  String get languagesCoreChip => 'CORE';

  @override
  String get languagesMoreTitle => 'More languages';

  @override
  String get languagesMoreSubtitle => 'Future releases';

  @override
  String languagesPackDetail(String nativeName) {
    return '$nativeName · Language pack';
  }

  @override
  String get languagesSoon => 'Soon';

  @override
  String languagesPackPlanned(String name) {
    return '$name language pack is planned for a future release.';
  }

  @override
  String get languagesSave => 'Save language preferences';

  @override
  String get languagesSaved => 'Language preferences saved';

  @override
  String get capabilitySpeechInput => 'Speech input';

  @override
  String get capabilityTranslation => 'Translation';

  @override
  String get capabilityVoiceOutput => 'Voice output';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsAppearanceDefault => 'Default: System';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAboutAnuvaad => 'About Anuvaad';

  @override
  String settingsVersion(String version, String build) {
    return 'v$version ($build)';
  }

  @override
  String get updateAvailableTitle => 'Update available';

  @override
  String updateSubtitle(String version, String date, String size) {
    return 'Version $version · $date · $size MB';
  }

  @override
  String get updateWhatsNew => 'What\'s new';

  @override
  String get updateFixed => 'Fixed';

  @override
  String get updateLater => 'Later';

  @override
  String get updateNow => 'Update now';

  @override
  String get updateMandatory =>
      'This update is required to keep using Anuvaad.';

  @override
  String updateDownloading(int percent) {
    return 'Downloading… $percent%';
  }

  @override
  String get updateVerifying => 'Checking the download…';

  @override
  String get updateInstalling => 'Opening the installer…';

  @override
  String get updatePermissionTitle => 'Allow updates';

  @override
  String get updatePermissionBody =>
      'To install the update, Android needs you to allow Anuvaad to install apps. Turn on “Allow from this source”, then come back.';

  @override
  String get updateOpenSettings => 'Open settings';

  @override
  String get updateFailedPermission =>
      'Updates can\'t be installed until you allow this. You can try again any time from Settings → Check for updates.';

  @override
  String get updateFailedCheck =>
      'Couldn\'t check for updates. Check your connection and try again.';

  @override
  String get updateFailedDownload =>
      'The download didn\'t finish. Check your connection and try again.';

  @override
  String get updateFailedIntegrity =>
      'The download was damaged, so it wasn\'t installed. Please try again.';

  @override
  String get updateFailedInstall =>
      'Android couldn\'t open the installer. Please try again.';

  @override
  String get updateClose => 'Close';

  @override
  String get updateNotInstalledTitle => 'The update wasn\'t installed';

  @override
  String get updateNotInstalledBody =>
      'If Android said “App not installed”, uninstall this copy of Anuvaad and install it again from the website.';

  @override
  String get updateOpenWebsite => 'Open website';

  @override
  String whatsNewTitle(String version) {
    return 'What\'s new in $version';
  }

  @override
  String get whatsNewGotIt => 'Got it';

  @override
  String get settingsCheckUpdates => 'Check for updates';

  @override
  String get settingsUpToDate => 'You\'re on the latest version';

  @override
  String get settingsReleaseNotes => 'Release notes';

  @override
  String get settingsUpdatesUnavailable =>
      'Updates aren\'t available in this preview build.';

  @override
  String get releaseNotesTitle => 'Release notes';

  @override
  String releaseNotesVersion(String version) {
    return 'Version $version';
  }

  @override
  String get releaseNotesLoadFailed => 'Couldn\'t load release notes.';

  @override
  String get releaseNotesEmpty => 'No releases yet.';

  @override
  String get updateReadyToInstall =>
      'The update is downloaded and checked. It\'s ready to install.';

  @override
  String get updateInstallNow => 'Install now';
}
