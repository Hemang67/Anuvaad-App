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

  @override
  String get conversationTitle => 'In-person conversation';

  @override
  String get conversationListen => 'Listen';

  @override
  String conversationListenHint(String language) {
    return 'They speak $language';
  }

  @override
  String get conversationSpeak => 'Speak';

  @override
  String conversationSpeakHint(String language) {
    return 'You speak $language';
  }

  @override
  String get conversationStop => 'Stop';

  @override
  String get conversationListening => 'Listening…';

  @override
  String get conversationTranslating => 'Translating…';

  @override
  String conversationOtherLabel(String language) {
    return 'OTHER PERSON · $language';
  }

  @override
  String conversationYouLabel(String language) {
    return 'YOU · $language';
  }

  @override
  String get conversationOfflineLabel => 'Offline translation';

  @override
  String get conversationEmptyTitle => 'Start a conversation';

  @override
  String get conversationEmptyBody =>
      'Tap Listen when the other person talks, or Speak to reply. Each translation is shown and spoken.';

  @override
  String get conversationChooseOtherLanguage =>
      'Which language will they speak?';

  @override
  String get conversationRetry => 'Try again';

  @override
  String get conversationAllowMic => 'Allow';

  @override
  String get conversationOpenSettings => 'Open settings';

  @override
  String get noticeMicDenied => 'Anuvaad needs the microphone to hear speech.';

  @override
  String get noticeMicPermanentlyDenied =>
      'Microphone access is off. Turn it on in Settings to use conversations.';

  @override
  String get noticeRecognizerUnavailable =>
      'Speech recognition isn\'t available on this phone. Install or update the Google app, then try again.';

  @override
  String get noticeNoSpeech =>
      'Didn\'t catch that. Try again a little closer to the phone.';

  @override
  String get noticeNetwork =>
      'Speech recognition needs a connection. Check your internet and try again.';

  @override
  String noticeLanguageUnsupported(String language) {
    return '$language speech recognition isn\'t available on this phone yet. Update the Google app, or add $language in its voice settings.';
  }

  @override
  String get noticeBusy => 'The microphone is busy. Try again in a moment.';

  @override
  String get noticeGeneric =>
      'Something went wrong with speech recognition. Try again.';

  @override
  String get translationOfflineNotReady =>
      'You\'re offline, and offline translation isn\'t downloaded yet. Connect to Wi-Fi once to download it.';

  @override
  String get translationFailed => 'Couldn\'t translate this.';

  @override
  String get audioDeviceSpeaker => 'Phone speaker';

  @override
  String get audioDeviceWired => 'Wired earphones';

  @override
  String get audioDeviceBluetooth => 'Bluetooth earphones';

  @override
  String get audioDeviceUsb => 'USB earphones';

  @override
  String get noticeEarphonesDisconnected =>
      'Earphones disconnected. Translations now play on the phone speaker.';

  @override
  String noticeSpeakerUnavailable(String device) {
    return 'Couldn\'t use the phone speaker. Your reply played in $device.';
  }

  @override
  String get noticePlaybackFailed =>
      'Couldn\'t play the translation. Tap Replay to try again.';

  @override
  String conversationOutput(String device) {
    return 'Output: $device';
  }

  @override
  String get conversationReplay => 'Replay translation';

  @override
  String get conversationPlaying => 'Playing…';

  @override
  String conversationNoVoice(String language) {
    return 'No $language voice on this phone, so this translation is text only.';
  }

  @override
  String get conversationInstallVoice => 'Install voice';

  @override
  String get audioDevicesTitle => 'Audio devices';

  @override
  String get audioDevicesIntro =>
      'Choose where each voice plays. Only devices connected right now are shown.';

  @override
  String get audioMicTitle => 'Microphone input';

  @override
  String get audioMicSubtitle => 'Capture the other person\'s speech';

  @override
  String get audioMicPhone => 'Phone microphone';

  @override
  String get audioForMeTitle => 'Translated voice · You';

  @override
  String get audioForMeSubtitle => 'Hear translation privately';

  @override
  String get audioForOtherTitle => 'Your reply · Other person';

  @override
  String get audioForOtherSubtitle => 'Play translated speech aloud';

  @override
  String get audioOptionEarphones => 'Earphones';

  @override
  String get audioOptionSpeaker => 'Phone speaker';

  @override
  String audioNow(String device) {
    return 'Now: $device';
  }

  @override
  String get audioNoEarphones =>
      'No earphones connected, so this plays on the phone speaker.';

  @override
  String get audioTestSound => 'Test output sound';

  @override
  String audioTestPlayedOn(String device) {
    return 'Played on $device';
  }

  @override
  String get audioCompatibility =>
      'Bluetooth microphone and playback routing vary by headset and Android version. Anuvaad shows the route Android actually uses.';

  @override
  String get settingsAudio => 'Audio';

  @override
  String get settingsAudioDevices => 'Audio devices';

  @override
  String get settingsAudioDevicesSubtitle => 'Where translations play';
}
