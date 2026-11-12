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
      'Tap Listen and Anuvaad keeps listening, translating and speaking each turn. Tap Speak to reply.';

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

  @override
  String get noticePausedForSilence =>
      'Listening paused after a minute of silence. Tap Listen to continue.';

  @override
  String get noticePausedForInterruption =>
      'Paused for a call or alarm. Tap Listen to continue.';

  @override
  String noticeAskToRepeat(String language) {
    return 'Got it: $language. Ask them to say it again.';
  }

  @override
  String get conversationLanguageUnclear =>
      'Language unclear. What did they speak?';

  @override
  String transcriptHeader(String date, int minutes) {
    return 'Anuvaad conversation · $date · $minutes min';
  }

  @override
  String get transcriptYou => 'You';

  @override
  String get transcriptOtherPerson => 'Other person';

  @override
  String get transcriptNotTranslated => 'Not translated';

  @override
  String get transcriptUnclear => 'Language unclear';

  @override
  String get statusReady => 'READY TO LISTEN';

  @override
  String get statusListening => 'LISTENING';

  @override
  String get statusRecording => 'YOUR TURN';

  @override
  String get statusChoosingLanguage => 'CHOOSE THE LANGUAGE';

  @override
  String get statusTranslating => 'TRANSLATING…';

  @override
  String get statusSpeaking => 'SPEAKING';

  @override
  String get statusReviewing => 'REVIEW YOUR REPLY';

  @override
  String get statusPaused => 'PAUSED';

  @override
  String get statusEnded => 'ENDED';

  @override
  String get modeInPerson => 'In person';

  @override
  String get modeMeeting => 'Meeting';

  @override
  String headerTheirLanguage(String language) {
    return 'Their language: $language';
  }

  @override
  String headerTheirLanguageDetected(String language) {
    return 'Their language: $language · Detected';
  }

  @override
  String get headerTheirLanguageAuto => 'Their language: Automatic';

  @override
  String get headerChange => 'Change';

  @override
  String get headerChooseTitle => 'Which language do they speak?';

  @override
  String get conversationPause => 'Pause';

  @override
  String get conversationEnd => 'End conversation';

  @override
  String conversationOtherLabelDetected(String language) {
    return 'OTHER PERSON · $language · DETECTED';
  }

  @override
  String get reviewHint => 'Check your reply before they hear it.';

  @override
  String get reviewEdit => 'Edit';

  @override
  String get reviewPlay => 'Play';

  @override
  String get reviewDiscard => 'Discard';

  @override
  String get reviewEditTitle => 'Edit what you said';

  @override
  String get reviewTranslateAgain => 'Translate again';

  @override
  String get summaryTitle => 'Conversation ended';

  @override
  String summaryMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String summaryTurns(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count turns',
      one: '1 turn',
    );
    return '$_temp0';
  }

  @override
  String get summaryCopy => 'Copy transcript';

  @override
  String get summaryCopied => 'Transcript copied';

  @override
  String get summaryDone => 'Done';

  @override
  String get summaryOpen => 'Summary';

  @override
  String get settingsConversation => 'Conversation';

  @override
  String get settingsAutoDetect => 'Automatic language detection';

  @override
  String get settingsAutoDetectSubtitle => 'Detect English, Hindi and Gujarati';

  @override
  String get settingsReviewReply => 'Review my reply before playing';

  @override
  String get settingsReviewReplySubtitle =>
      'Check and edit your reply before the other person hears it';

  @override
  String get historyTitle => 'History';

  @override
  String get historySearchHint => 'Search saved conversations…';

  @override
  String get historyOffTitle => 'Saving conversations is off';

  @override
  String get historyOffBody =>
      'Turn it on to keep conversations on this phone. Nothing is saved until you do.';

  @override
  String get historyTurnOn => 'Turn on in Settings';

  @override
  String get historyEmpty => 'No saved conversations yet';

  @override
  String historyNoMatch(String query) {
    return 'No conversations match “$query”.';
  }

  @override
  String historyMinutesChip(int minutes) {
    return '$minutes MIN';
  }

  @override
  String get historyDetailTitle => 'Conversation';

  @override
  String get historyNotFound => 'This conversation is no longer saved.';

  @override
  String historyLineOther(String language, String time) {
    return 'OTHER PERSON · $language · $time';
  }

  @override
  String historyLineYou(String language, String time) {
    return 'YOU · $language · $time';
  }

  @override
  String get historyCopy => 'Copy';

  @override
  String get historyShare => 'Share';

  @override
  String get historyDelete => 'Delete';

  @override
  String get historyDeleteTitle => 'Delete this conversation?';

  @override
  String get historyDeleteBody =>
      'It\'s removed from this phone and can\'t be brought back.';

  @override
  String get homeRecentTitle => 'Recent conversations';

  @override
  String get homeSeeAll => 'See all';

  @override
  String homeDeviceStatus(String me, String reply) {
    return 'Translated voice: $me · Reply: $reply';
  }

  @override
  String get summarySave => 'Save to history';

  @override
  String get summarySaved => 'Saved to history';

  @override
  String get settingsSpeechSpeed => 'Speech speed';

  @override
  String get speechRateSlow => 'Slow';

  @override
  String get speechRateNormal => 'Normal';

  @override
  String get speechRateFast => 'Fast';

  @override
  String get settingsVoices => 'Voices';

  @override
  String get settingsVoicesSubtitle => 'Choose a voice for each language';

  @override
  String get voicesTitle => 'Voices';

  @override
  String get voicesIntro =>
      'Choose the voice for each language. Default lets the phone choose.';

  @override
  String get voicesDefault => 'Default voice';

  @override
  String get voicesDefaultSubtitle => 'Chosen by the phone';

  @override
  String voicesOnPhone(int number) {
    return 'Voice $number · on this phone';
  }

  @override
  String voicesOnline(int number) {
    return 'Voice $number · needs internet';
  }

  @override
  String get voicesTest => 'Test';

  @override
  String voicesMissing(String language) {
    return 'No $language voice on this phone yet. Install one from Languages.';
  }

  @override
  String get voicesTestFailed => 'Couldn\'t play the test sentence.';

  @override
  String get languageSpeechReady => 'Speech input · Ready';

  @override
  String get languageSpeechMissing =>
      'Speech input · Not available on this phone';

  @override
  String get languageModelReady => 'Offline translation · Downloaded';

  @override
  String get languageModelMissing => 'Offline translation · Not downloaded';

  @override
  String get languageVoiceReady => 'Voice · Installed';

  @override
  String get languageVoiceDownload => 'Voice · Needs download';

  @override
  String get languageVoiceMissing => 'Voice · Not available';

  @override
  String get languagesDownload => 'Download';

  @override
  String get languagesDownloadTitle => 'Download offline translation?';

  @override
  String languagesDownloadBody(String language) {
    return '$language for translating without internet. About 30 MB.';
  }

  @override
  String get languagesWifiOnly => 'Wi-Fi only';

  @override
  String get languagesAnyNetwork => 'Use mobile data too';

  @override
  String get languagesDownloadFailed =>
      'Couldn\'t download. Check your connection and try again.';

  @override
  String get settingsLanguagesSection => 'Languages';

  @override
  String get settingsOfflineModels => 'Offline models';

  @override
  String get settingsOfflineModelsSubtitle =>
      'What works without internet, per language';

  @override
  String get settingsAutoDetectUnsupported =>
      'Needs Android 14 or later. You\'ll choose the language instead.';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsSaveHistory => 'Save conversations';

  @override
  String get settingsSaveHistorySubtitle =>
      'Off by default · stays on this phone';

  @override
  String get settingsRawAudio => 'Raw audio';

  @override
  String get settingsRawAudioNever => 'Never saved';

  @override
  String get settingsDeleteAll => 'Delete all conversations';

  @override
  String get settingsDeleteAllTitle => 'Delete all saved conversations?';

  @override
  String get settingsDeleteAllButton => 'Delete all';

  @override
  String get settingsDeleteAllDone => 'All saved conversations deleted';

  @override
  String get settingsKeepTitle => 'Keep saved conversations?';

  @override
  String get settingsKeepBody =>
      'New conversations won\'t be saved. The ones already saved can stay on this phone or be deleted now.';

  @override
  String get settingsKeep => 'Keep';

  @override
  String get settingsPrivacyData => 'Privacy & data';

  @override
  String get settingsPrivacyDataSubtitle =>
      'What leaves your phone, and what is kept';

  @override
  String get privacyLeavesTitle => 'What leaves your phone';

  @override
  String get privacyLeavesUpdates =>
      'Update checks: the app\'s version and a random install ID go to the Anuvaad server to find out whether a newer release exists.';

  @override
  String get privacyLeavesAudio =>
      'Microphone audio: when Android\'s speech recognizer works online, Android sends the audio to Google\'s speech service. Anuvaad doesn\'t record or upload audio itself.';

  @override
  String get privacyLeavesText =>
      'Recognized text and the random install ID go to the Anuvaad server so they can be translated.';

  @override
  String get privacyLeavesVoices =>
      'Translated text, when it is spoken: Android\'s speech engine usually speaks on the phone, but may use Google\'s online voices for some languages.';

  @override
  String get privacyGoesTitle => 'Where it goes';

  @override
  String get privacyGoesServer =>
      'The Anuvaad server runs on Vercel and passes text to Cloudflare Workers AI for translation. It doesn\'t store or log the text.';

  @override
  String get privacyGoesOffline =>
      'Offline translation runs on your phone with Google ML Kit; that text doesn\'t leave the phone.';

  @override
  String get privacyGoesReleases =>
      'App updates and release notes come from GitHub Releases.';

  @override
  String get privacyStoredTitle => 'What is stored';

  @override
  String get privacyStoredAudio => 'Raw microphone audio is never saved.';

  @override
  String get privacyStoredVoiceFiles =>
      'Spoken translations are temporary audio files, deleted when the conversation closes.';

  @override
  String get privacyStoredHistory =>
      'Saved conversations stay on this phone, and only when Save conversations is on or you tap Save. They\'re never uploaded.';

  @override
  String get privacyStoredLatency =>
      'The latency report keeps timings only, no words, on this phone.';

  @override
  String get privacyControlsTitle => 'Your controls';

  @override
  String get privacyControlsHistory =>
      'Turn Save conversations on or off in Settings, delete one conversation in History, or delete them all in Settings.';

  @override
  String get privacyControlsMic =>
      'Pause or End stops the microphone straight away, and leaving the app pauses the conversation.';

  @override
  String get privacyFullPage => 'Full privacy page';

  @override
  String get privacyContact =>
      'Contact details will be added before public launch.';

  @override
  String get settingsAppLanguage => 'App language';

  @override
  String get appLanguageSystem => 'Phone\'s language';
}
