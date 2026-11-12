import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('gu'),
    Locale('hi'),
  ];

  /// Application name shown in the task switcher.
  ///
  /// In en, this message translates to:
  /// **'Anuvaad'**
  String get appTitle;

  /// No description provided for @brandName.
  ///
  /// In en, this message translates to:
  /// **'Anuvaad'**
  String get brandName;

  /// No description provided for @brandTagline.
  ///
  /// In en, this message translates to:
  /// **'Speak Any Language. Be Closer.'**
  String get brandTagline;

  /// No description provided for @poweredBy.
  ///
  /// In en, this message translates to:
  /// **'Powered by REA Intelligence'**
  String get poweredBy;

  /// No description provided for @brandLogoLabel.
  ///
  /// In en, this message translates to:
  /// **'Anuvaad logo'**
  String get brandLogoLabel;

  /// No description provided for @splashStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Anuvaad couldn\'t start. Please try again.'**
  String get splashStartFailed;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get navLanguages;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @listOr.
  ///
  /// In en, this message translates to:
  /// **' or '**
  String get listOr;

  /// No description provided for @listAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get listAnd;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Talk naturally with people who speak {languages}.'**
  String onboardingWelcomeBody(String languages);

  /// No description provided for @onboardingModesTitle.
  ///
  /// In en, this message translates to:
  /// **'Two simple modes'**
  String get onboardingModesTitle;

  /// No description provided for @onboardingListenTitle.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get onboardingListenTitle;

  /// No description provided for @onboardingListenBody.
  ///
  /// In en, this message translates to:
  /// **'Anuvaad listens to the other person and plays the translation in your earphones.'**
  String get onboardingListenBody;

  /// No description provided for @onboardingSpeakTitle.
  ///
  /// In en, this message translates to:
  /// **'Speak'**
  String get onboardingSpeakTitle;

  /// No description provided for @onboardingSpeakBody.
  ///
  /// In en, this message translates to:
  /// **'Reply in your own language. Anuvaad says it aloud in theirs.'**
  String get onboardingSpeakBody;

  /// No description provided for @onboardingPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your privacy'**
  String get onboardingPrivacyTitle;

  /// No description provided for @onboardingPrivacySpeech.
  ///
  /// In en, this message translates to:
  /// **'Your speech is turned into text by your phone\'s speech service.'**
  String get onboardingPrivacySpeech;

  /// No description provided for @onboardingPrivacyText.
  ///
  /// In en, this message translates to:
  /// **'The text is sent to the Anuvaad server to be translated. It isn\'t stored.'**
  String get onboardingPrivacyText;

  /// No description provided for @onboardingPrivacyStorage.
  ///
  /// In en, this message translates to:
  /// **'Raw audio is never saved. History stays off unless you turn it on.'**
  String get onboardingPrivacyStorage;

  /// No description provided for @onboardingPrivacyQuality.
  ///
  /// In en, this message translates to:
  /// **'Translation quality and speed can vary with your network and device.'**
  String get onboardingPrivacyQuality;

  /// No description provided for @onboardingPrivacyLink.
  ///
  /// In en, this message translates to:
  /// **'Read the full privacy notice'**
  String get onboardingPrivacyLink;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingGetStarted;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'YOUR PERSONAL LANGUAGE BRIDGE'**
  String get homeGreeting;

  /// No description provided for @homeHeadlineTop.
  ///
  /// In en, this message translates to:
  /// **'Speak freely.'**
  String get homeHeadlineTop;

  /// No description provided for @homeHeadlineBottom.
  ///
  /// In en, this message translates to:
  /// **'Understand everyone.'**
  String get homeHeadlineBottom;

  /// No description provided for @homeHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Your voice, understood worldwide.'**
  String get homeHeroTitle;

  /// No description provided for @homeHeroBody.
  ///
  /// In en, this message translates to:
  /// **'Real-time translation in {languages}.'**
  String homeHeroBody(String languages);

  /// No description provided for @homeModesTitle.
  ///
  /// In en, this message translates to:
  /// **'Start communicating'**
  String get homeModesTitle;

  /// No description provided for @homeModesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a mode'**
  String get homeModesSubtitle;

  /// No description provided for @homeInPersonTitle.
  ///
  /// In en, this message translates to:
  /// **'In-person conversation'**
  String get homeInPersonTitle;

  /// No description provided for @homeInPersonSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Talk naturally face-to-face'**
  String get homeInPersonSubtitle;

  /// No description provided for @homeMeetingTitle.
  ///
  /// In en, this message translates to:
  /// **'Online meeting'**
  String get homeMeetingTitle;

  /// No description provided for @homeMeetingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Supported audio sources only'**
  String get homeMeetingSubtitle;

  /// No description provided for @homeComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming in an update'**
  String get homeComingSoon;

  /// No description provided for @homeMyLanguage.
  ///
  /// In en, this message translates to:
  /// **'MY LANGUAGE'**
  String get homeMyLanguage;

  /// No description provided for @homeChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get homeChange;

  /// No description provided for @homeQuickAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick access'**
  String get homeQuickAccessTitle;

  /// No description provided for @homeQuickAccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Explore Anuvaad'**
  String get homeQuickAccessSubtitle;

  /// No description provided for @languagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languagesTitle;

  /// No description provided for @languagesIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose the language you understand and the language spoken by the other person. All {count} core languages are included by default.'**
  String languagesIntro(int count);

  /// No description provided for @languagesMyLabel.
  ///
  /// In en, this message translates to:
  /// **'MY LANGUAGE · TRANSLATE INTO'**
  String get languagesMyLabel;

  /// No description provided for @languagesOtherLabel.
  ///
  /// In en, this message translates to:
  /// **'OTHER PERSON · SPEAKING'**
  String get languagesOtherLabel;

  /// No description provided for @languagesAutoDetect.
  ///
  /// In en, this message translates to:
  /// **'Automatic detection'**
  String get languagesAutoDetect;

  /// No description provided for @languagesSwap.
  ///
  /// In en, this message translates to:
  /// **'Swap languages'**
  String get languagesSwap;

  /// No description provided for @languagesSameLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose two different languages.'**
  String get languagesSameLanguage;

  /// No description provided for @languagesIncludedTitle.
  ///
  /// In en, this message translates to:
  /// **'Included by default'**
  String get languagesIncludedTitle;

  /// No description provided for @languagesIncludedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} core languages'**
  String languagesIncludedCount(int count);

  /// No description provided for @languagesCoreChip.
  ///
  /// In en, this message translates to:
  /// **'CORE'**
  String get languagesCoreChip;

  /// No description provided for @languagesMoreTitle.
  ///
  /// In en, this message translates to:
  /// **'More languages'**
  String get languagesMoreTitle;

  /// No description provided for @languagesMoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Future releases'**
  String get languagesMoreSubtitle;

  /// No description provided for @languagesPackDetail.
  ///
  /// In en, this message translates to:
  /// **'{nativeName} · Language pack'**
  String languagesPackDetail(String nativeName);

  /// No description provided for @languagesSoon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get languagesSoon;

  /// No description provided for @languagesPackPlanned.
  ///
  /// In en, this message translates to:
  /// **'{name} language pack is planned for a future release.'**
  String languagesPackPlanned(String name);

  /// No description provided for @languagesSave.
  ///
  /// In en, this message translates to:
  /// **'Save language preferences'**
  String get languagesSave;

  /// No description provided for @languagesSaved.
  ///
  /// In en, this message translates to:
  /// **'Language preferences saved'**
  String get languagesSaved;

  /// No description provided for @capabilitySpeechInput.
  ///
  /// In en, this message translates to:
  /// **'Speech input'**
  String get capabilitySpeechInput;

  /// No description provided for @capabilityTranslation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get capabilityTranslation;

  /// No description provided for @capabilityVoiceOutput.
  ///
  /// In en, this message translates to:
  /// **'Voice output'**
  String get capabilityVoiceOutput;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsAppearanceDefault.
  ///
  /// In en, this message translates to:
  /// **'Default: System'**
  String get settingsAppearanceDefault;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsAboutAnuvaad.
  ///
  /// In en, this message translates to:
  /// **'About Anuvaad'**
  String get settingsAboutAnuvaad;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'v{version} ({build})'**
  String settingsVersion(String version, String build);

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailableTitle;

  /// No description provided for @updateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Version {version} · {date} · {size} MB'**
  String updateSubtitle(String version, String date, String size);

  /// No description provided for @updateWhatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get updateWhatsNew;

  /// No description provided for @updateFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get updateFixed;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateNow;

  /// No description provided for @updateMandatory.
  ///
  /// In en, this message translates to:
  /// **'This update is required to keep using Anuvaad.'**
  String get updateMandatory;

  /// No description provided for @updateDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading… {percent}%'**
  String updateDownloading(int percent);

  /// No description provided for @updateVerifying.
  ///
  /// In en, this message translates to:
  /// **'Checking the download…'**
  String get updateVerifying;

  /// No description provided for @updateInstalling.
  ///
  /// In en, this message translates to:
  /// **'Opening the installer…'**
  String get updateInstalling;

  /// No description provided for @updatePermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow updates'**
  String get updatePermissionTitle;

  /// No description provided for @updatePermissionBody.
  ///
  /// In en, this message translates to:
  /// **'To install the update, Android needs you to allow Anuvaad to install apps. Turn on “Allow from this source”, then come back.'**
  String get updatePermissionBody;

  /// No description provided for @updateOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get updateOpenSettings;

  /// No description provided for @updateFailedPermission.
  ///
  /// In en, this message translates to:
  /// **'Updates can\'t be installed until you allow this. You can try again any time from Settings → Check for updates.'**
  String get updateFailedPermission;

  /// No description provided for @updateFailedCheck.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check for updates. Check your connection and try again.'**
  String get updateFailedCheck;

  /// No description provided for @updateFailedDownload.
  ///
  /// In en, this message translates to:
  /// **'The download didn\'t finish. Check your connection and try again.'**
  String get updateFailedDownload;

  /// No description provided for @updateFailedIntegrity.
  ///
  /// In en, this message translates to:
  /// **'The download was damaged, so it wasn\'t installed. Please try again.'**
  String get updateFailedIntegrity;

  /// No description provided for @updateFailedInstall.
  ///
  /// In en, this message translates to:
  /// **'Android couldn\'t open the installer. Please try again.'**
  String get updateFailedInstall;

  /// No description provided for @updateClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get updateClose;

  /// No description provided for @updateNotInstalledTitle.
  ///
  /// In en, this message translates to:
  /// **'The update wasn\'t installed'**
  String get updateNotInstalledTitle;

  /// No description provided for @updateNotInstalledBody.
  ///
  /// In en, this message translates to:
  /// **'If Android said “App not installed”, uninstall this copy of Anuvaad and install it again from the website.'**
  String get updateNotInstalledBody;

  /// No description provided for @updateOpenWebsite.
  ///
  /// In en, this message translates to:
  /// **'Open website'**
  String get updateOpenWebsite;

  /// No description provided for @whatsNewTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s new in {version}'**
  String whatsNewTitle(String version);

  /// No description provided for @whatsNewGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get whatsNewGotIt;

  /// No description provided for @settingsCheckUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get settingsCheckUpdates;

  /// No description provided for @settingsUpToDate.
  ///
  /// In en, this message translates to:
  /// **'You\'re on the latest version'**
  String get settingsUpToDate;

  /// No description provided for @settingsReleaseNotes.
  ///
  /// In en, this message translates to:
  /// **'Release notes'**
  String get settingsReleaseNotes;

  /// No description provided for @settingsUpdatesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Updates aren\'t available in this preview build.'**
  String get settingsUpdatesUnavailable;

  /// No description provided for @releaseNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Release notes'**
  String get releaseNotesTitle;

  /// No description provided for @releaseNotesVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String releaseNotesVersion(String version);

  /// No description provided for @releaseNotesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load release notes.'**
  String get releaseNotesLoadFailed;

  /// No description provided for @releaseNotesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No releases yet.'**
  String get releaseNotesEmpty;

  /// No description provided for @updateReadyToInstall.
  ///
  /// In en, this message translates to:
  /// **'The update is downloaded and checked. It\'s ready to install.'**
  String get updateReadyToInstall;

  /// No description provided for @updateInstallNow.
  ///
  /// In en, this message translates to:
  /// **'Install now'**
  String get updateInstallNow;

  /// No description provided for @conversationTitle.
  ///
  /// In en, this message translates to:
  /// **'In-person conversation'**
  String get conversationTitle;

  /// No description provided for @conversationListen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get conversationListen;

  /// No description provided for @conversationListenHint.
  ///
  /// In en, this message translates to:
  /// **'They speak {language}'**
  String conversationListenHint(String language);

  /// No description provided for @conversationSpeak.
  ///
  /// In en, this message translates to:
  /// **'Speak'**
  String get conversationSpeak;

  /// No description provided for @conversationSpeakHint.
  ///
  /// In en, this message translates to:
  /// **'You speak {language}'**
  String conversationSpeakHint(String language);

  /// No description provided for @conversationStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get conversationStop;

  /// No description provided for @conversationListening.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get conversationListening;

  /// No description provided for @conversationTranslating.
  ///
  /// In en, this message translates to:
  /// **'Translating…'**
  String get conversationTranslating;

  /// No description provided for @conversationOtherLabel.
  ///
  /// In en, this message translates to:
  /// **'OTHER PERSON · {language}'**
  String conversationOtherLabel(String language);

  /// No description provided for @conversationYouLabel.
  ///
  /// In en, this message translates to:
  /// **'YOU · {language}'**
  String conversationYouLabel(String language);

  /// No description provided for @conversationOfflineLabel.
  ///
  /// In en, this message translates to:
  /// **'Offline translation'**
  String get conversationOfflineLabel;

  /// No description provided for @conversationEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation'**
  String get conversationEmptyTitle;

  /// No description provided for @conversationEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tap Listen and Anuvaad keeps listening, translating and speaking each turn. Tap Speak to reply.'**
  String get conversationEmptyBody;

  /// No description provided for @conversationChooseOtherLanguage.
  ///
  /// In en, this message translates to:
  /// **'Which language will they speak?'**
  String get conversationChooseOtherLanguage;

  /// No description provided for @conversationRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get conversationRetry;

  /// No description provided for @conversationAllowMic.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get conversationAllowMic;

  /// No description provided for @conversationOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get conversationOpenSettings;

  /// No description provided for @noticeMicDenied.
  ///
  /// In en, this message translates to:
  /// **'Anuvaad needs the microphone to hear speech.'**
  String get noticeMicDenied;

  /// No description provided for @noticeMicPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is off. Turn it on in Settings to use conversations.'**
  String get noticeMicPermanentlyDenied;

  /// No description provided for @noticeRecognizerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition isn\'t available on this phone. Install or update the Google app, then try again.'**
  String get noticeRecognizerUnavailable;

  /// No description provided for @noticeNoSpeech.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t catch that. Try again a little closer to the phone.'**
  String get noticeNoSpeech;

  /// No description provided for @noticeNetwork.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition needs a connection. Check your internet and try again.'**
  String get noticeNetwork;

  /// No description provided for @noticeLanguageUnsupported.
  ///
  /// In en, this message translates to:
  /// **'{language} speech recognition isn\'t available on this phone yet. Update the Google app, or add {language} in its voice settings.'**
  String noticeLanguageUnsupported(String language);

  /// No description provided for @noticeBusy.
  ///
  /// In en, this message translates to:
  /// **'The microphone is busy. Try again in a moment.'**
  String get noticeBusy;

  /// No description provided for @noticeGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong with speech recognition. Try again.'**
  String get noticeGeneric;

  /// No description provided for @translationOfflineNotReady.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline, and offline translation isn\'t downloaded yet. Connect to Wi-Fi once to download it.'**
  String get translationOfflineNotReady;

  /// No description provided for @translationFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t translate this.'**
  String get translationFailed;

  /// No description provided for @audioDeviceSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Phone speaker'**
  String get audioDeviceSpeaker;

  /// No description provided for @audioDeviceWired.
  ///
  /// In en, this message translates to:
  /// **'Wired earphones'**
  String get audioDeviceWired;

  /// No description provided for @audioDeviceBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth earphones'**
  String get audioDeviceBluetooth;

  /// No description provided for @audioDeviceUsb.
  ///
  /// In en, this message translates to:
  /// **'USB earphones'**
  String get audioDeviceUsb;

  /// No description provided for @noticeEarphonesDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Earphones disconnected. Translations now play on the phone speaker.'**
  String get noticeEarphonesDisconnected;

  /// No description provided for @noticeSpeakerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t use the phone speaker. Your reply played in {device}.'**
  String noticeSpeakerUnavailable(String device);

  /// No description provided for @noticePlaybackFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t play the translation. Tap Replay to try again.'**
  String get noticePlaybackFailed;

  /// No description provided for @conversationOutput.
  ///
  /// In en, this message translates to:
  /// **'Output: {device}'**
  String conversationOutput(String device);

  /// No description provided for @conversationReplay.
  ///
  /// In en, this message translates to:
  /// **'Replay translation'**
  String get conversationReplay;

  /// No description provided for @conversationPlaying.
  ///
  /// In en, this message translates to:
  /// **'Playing…'**
  String get conversationPlaying;

  /// No description provided for @conversationNoVoice.
  ///
  /// In en, this message translates to:
  /// **'No {language} voice on this phone, so this translation is text only.'**
  String conversationNoVoice(String language);

  /// No description provided for @conversationInstallVoice.
  ///
  /// In en, this message translates to:
  /// **'Install voice'**
  String get conversationInstallVoice;

  /// No description provided for @audioDevicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Audio devices'**
  String get audioDevicesTitle;

  /// No description provided for @audioDevicesIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose where each voice plays. Only devices connected right now are shown.'**
  String get audioDevicesIntro;

  /// No description provided for @audioMicTitle.
  ///
  /// In en, this message translates to:
  /// **'Microphone input'**
  String get audioMicTitle;

  /// No description provided for @audioMicSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Capture the other person\'s speech'**
  String get audioMicSubtitle;

  /// No description provided for @audioMicPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone microphone'**
  String get audioMicPhone;

  /// No description provided for @audioForMeTitle.
  ///
  /// In en, this message translates to:
  /// **'Translated voice · You'**
  String get audioForMeTitle;

  /// No description provided for @audioForMeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hear translation privately'**
  String get audioForMeSubtitle;

  /// No description provided for @audioForOtherTitle.
  ///
  /// In en, this message translates to:
  /// **'Your reply · Other person'**
  String get audioForOtherTitle;

  /// No description provided for @audioForOtherSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Play translated speech aloud'**
  String get audioForOtherSubtitle;

  /// No description provided for @audioOptionEarphones.
  ///
  /// In en, this message translates to:
  /// **'Earphones'**
  String get audioOptionEarphones;

  /// No description provided for @audioOptionSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Phone speaker'**
  String get audioOptionSpeaker;

  /// No description provided for @audioNow.
  ///
  /// In en, this message translates to:
  /// **'Now: {device}'**
  String audioNow(String device);

  /// No description provided for @audioNoEarphones.
  ///
  /// In en, this message translates to:
  /// **'No earphones connected, so this plays on the phone speaker.'**
  String get audioNoEarphones;

  /// No description provided for @audioTestSound.
  ///
  /// In en, this message translates to:
  /// **'Test output sound'**
  String get audioTestSound;

  /// No description provided for @audioTestPlayedOn.
  ///
  /// In en, this message translates to:
  /// **'Played on {device}'**
  String audioTestPlayedOn(String device);

  /// No description provided for @audioCompatibility.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth microphone and playback routing vary by headset and Android version. Anuvaad shows the route Android actually uses.'**
  String get audioCompatibility;

  /// No description provided for @settingsAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get settingsAudio;

  /// No description provided for @settingsAudioDevices.
  ///
  /// In en, this message translates to:
  /// **'Audio devices'**
  String get settingsAudioDevices;

  /// No description provided for @settingsAudioDevicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Where translations play'**
  String get settingsAudioDevicesSubtitle;

  /// No description provided for @noticePausedForSilence.
  ///
  /// In en, this message translates to:
  /// **'Listening paused after a minute of silence. Tap Listen to continue.'**
  String get noticePausedForSilence;

  /// No description provided for @noticePausedForInterruption.
  ///
  /// In en, this message translates to:
  /// **'Paused for a call or alarm. Tap Listen to continue.'**
  String get noticePausedForInterruption;

  /// No description provided for @noticeAskToRepeat.
  ///
  /// In en, this message translates to:
  /// **'Got it: {language}. Ask them to say it again.'**
  String noticeAskToRepeat(String language);

  /// No description provided for @conversationLanguageUnclear.
  ///
  /// In en, this message translates to:
  /// **'Language unclear. What did they speak?'**
  String get conversationLanguageUnclear;

  /// No description provided for @transcriptHeader.
  ///
  /// In en, this message translates to:
  /// **'Anuvaad conversation · {date} · {minutes} min'**
  String transcriptHeader(String date, int minutes);

  /// No description provided for @transcriptYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get transcriptYou;

  /// No description provided for @transcriptOtherPerson.
  ///
  /// In en, this message translates to:
  /// **'Other person'**
  String get transcriptOtherPerson;

  /// No description provided for @transcriptNotTranslated.
  ///
  /// In en, this message translates to:
  /// **'Not translated'**
  String get transcriptNotTranslated;

  /// No description provided for @transcriptUnclear.
  ///
  /// In en, this message translates to:
  /// **'Language unclear'**
  String get transcriptUnclear;

  /// No description provided for @statusReady.
  ///
  /// In en, this message translates to:
  /// **'READY TO LISTEN'**
  String get statusReady;

  /// No description provided for @statusListening.
  ///
  /// In en, this message translates to:
  /// **'LISTENING'**
  String get statusListening;

  /// No description provided for @statusRecording.
  ///
  /// In en, this message translates to:
  /// **'YOUR TURN'**
  String get statusRecording;

  /// No description provided for @statusChoosingLanguage.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE THE LANGUAGE'**
  String get statusChoosingLanguage;

  /// No description provided for @statusTranslating.
  ///
  /// In en, this message translates to:
  /// **'TRANSLATING…'**
  String get statusTranslating;

  /// No description provided for @statusSpeaking.
  ///
  /// In en, this message translates to:
  /// **'SPEAKING'**
  String get statusSpeaking;

  /// No description provided for @statusReviewing.
  ///
  /// In en, this message translates to:
  /// **'REVIEW YOUR REPLY'**
  String get statusReviewing;

  /// No description provided for @statusPaused.
  ///
  /// In en, this message translates to:
  /// **'PAUSED'**
  String get statusPaused;

  /// No description provided for @statusEnded.
  ///
  /// In en, this message translates to:
  /// **'ENDED'**
  String get statusEnded;

  /// No description provided for @modeInPerson.
  ///
  /// In en, this message translates to:
  /// **'In person'**
  String get modeInPerson;

  /// No description provided for @modeMeeting.
  ///
  /// In en, this message translates to:
  /// **'Meeting'**
  String get modeMeeting;

  /// No description provided for @headerTheirLanguage.
  ///
  /// In en, this message translates to:
  /// **'Their language: {language}'**
  String headerTheirLanguage(String language);

  /// No description provided for @headerTheirLanguageDetected.
  ///
  /// In en, this message translates to:
  /// **'Their language: {language} · Detected'**
  String headerTheirLanguageDetected(String language);

  /// No description provided for @headerTheirLanguageAuto.
  ///
  /// In en, this message translates to:
  /// **'Their language: Automatic'**
  String get headerTheirLanguageAuto;

  /// No description provided for @headerChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get headerChange;

  /// No description provided for @headerChooseTitle.
  ///
  /// In en, this message translates to:
  /// **'Which language do they speak?'**
  String get headerChooseTitle;

  /// No description provided for @conversationPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get conversationPause;

  /// No description provided for @conversationEnd.
  ///
  /// In en, this message translates to:
  /// **'End conversation'**
  String get conversationEnd;

  /// No description provided for @conversationOtherLabelDetected.
  ///
  /// In en, this message translates to:
  /// **'OTHER PERSON · {language} · DETECTED'**
  String conversationOtherLabelDetected(String language);

  /// No description provided for @reviewHint.
  ///
  /// In en, this message translates to:
  /// **'Check your reply before they hear it.'**
  String get reviewHint;

  /// No description provided for @reviewEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get reviewEdit;

  /// No description provided for @reviewPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get reviewPlay;

  /// No description provided for @reviewDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get reviewDiscard;

  /// No description provided for @reviewEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit what you said'**
  String get reviewEditTitle;

  /// No description provided for @reviewTranslateAgain.
  ///
  /// In en, this message translates to:
  /// **'Translate again'**
  String get reviewTranslateAgain;

  /// No description provided for @summaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversation ended'**
  String get summaryTitle;

  /// No description provided for @summaryMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String summaryMinutes(int minutes);

  /// No description provided for @summaryTurns.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 turn} other{{count} turns}}'**
  String summaryTurns(int count);

  /// No description provided for @summaryCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy transcript'**
  String get summaryCopy;

  /// No description provided for @summaryCopied.
  ///
  /// In en, this message translates to:
  /// **'Transcript copied'**
  String get summaryCopied;

  /// No description provided for @summaryDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get summaryDone;

  /// No description provided for @summaryOpen.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summaryOpen;

  /// No description provided for @settingsConversation.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get settingsConversation;

  /// No description provided for @settingsAutoDetect.
  ///
  /// In en, this message translates to:
  /// **'Automatic language detection'**
  String get settingsAutoDetect;

  /// No description provided for @settingsAutoDetectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Detect English, Hindi and Gujarati'**
  String get settingsAutoDetectSubtitle;

  /// No description provided for @settingsReviewReply.
  ///
  /// In en, this message translates to:
  /// **'Review my reply before playing'**
  String get settingsReviewReply;

  /// No description provided for @settingsReviewReplySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check and edit your reply before the other person hears it'**
  String get settingsReviewReplySubtitle;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search saved conversations…'**
  String get historySearchHint;

  /// No description provided for @historyOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Saving conversations is off'**
  String get historyOffTitle;

  /// No description provided for @historyOffBody.
  ///
  /// In en, this message translates to:
  /// **'Turn it on to keep conversations on this phone. Nothing is saved until you do.'**
  String get historyOffBody;

  /// No description provided for @historyTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on in Settings'**
  String get historyTurnOn;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved conversations yet'**
  String get historyEmpty;

  /// No description provided for @historyNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No conversations match “{query}”.'**
  String historyNoMatch(String query);

  /// No description provided for @historyMinutesChip.
  ///
  /// In en, this message translates to:
  /// **'{minutes} MIN'**
  String historyMinutesChip(int minutes);

  /// No description provided for @historyDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get historyDetailTitle;

  /// No description provided for @historyNotFound.
  ///
  /// In en, this message translates to:
  /// **'This conversation is no longer saved.'**
  String get historyNotFound;

  /// No description provided for @historyLineOther.
  ///
  /// In en, this message translates to:
  /// **'OTHER PERSON · {language} · {time}'**
  String historyLineOther(String language, String time);

  /// No description provided for @historyLineYou.
  ///
  /// In en, this message translates to:
  /// **'YOU · {language} · {time}'**
  String historyLineYou(String language, String time);

  /// No description provided for @historyCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get historyCopy;

  /// No description provided for @historyShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get historyShare;

  /// No description provided for @historyDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get historyDelete;

  /// No description provided for @historyDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this conversation?'**
  String get historyDeleteTitle;

  /// No description provided for @historyDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'It\'s removed from this phone and can\'t be brought back.'**
  String get historyDeleteBody;

  /// No description provided for @homeRecentTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent conversations'**
  String get homeRecentTitle;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// No description provided for @homeDeviceStatus.
  ///
  /// In en, this message translates to:
  /// **'Translated voice: {me} · Reply: {reply}'**
  String homeDeviceStatus(String me, String reply);

  /// No description provided for @summarySave.
  ///
  /// In en, this message translates to:
  /// **'Save to history'**
  String get summarySave;

  /// No description provided for @summarySaved.
  ///
  /// In en, this message translates to:
  /// **'Saved to history'**
  String get summarySaved;

  /// No description provided for @settingsSpeechSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speech speed'**
  String get settingsSpeechSpeed;

  /// No description provided for @speechRateSlow.
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get speechRateSlow;

  /// No description provided for @speechRateNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get speechRateNormal;

  /// No description provided for @speechRateFast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get speechRateFast;

  /// No description provided for @settingsVoices.
  ///
  /// In en, this message translates to:
  /// **'Voices'**
  String get settingsVoices;

  /// No description provided for @settingsVoicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a voice for each language'**
  String get settingsVoicesSubtitle;

  /// No description provided for @voicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Voices'**
  String get voicesTitle;

  /// No description provided for @voicesIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose the voice for each language. Default lets the phone choose.'**
  String get voicesIntro;

  /// No description provided for @voicesDefault.
  ///
  /// In en, this message translates to:
  /// **'Default voice'**
  String get voicesDefault;

  /// No description provided for @voicesDefaultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Chosen by the phone'**
  String get voicesDefaultSubtitle;

  /// No description provided for @voicesOnPhone.
  ///
  /// In en, this message translates to:
  /// **'Voice {number} · on this phone'**
  String voicesOnPhone(int number);

  /// No description provided for @voicesOnline.
  ///
  /// In en, this message translates to:
  /// **'Voice {number} · needs internet'**
  String voicesOnline(int number);

  /// No description provided for @voicesTest.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get voicesTest;

  /// No description provided for @voicesMissing.
  ///
  /// In en, this message translates to:
  /// **'No {language} voice on this phone yet. Install one from Languages.'**
  String voicesMissing(String language);

  /// No description provided for @voicesTestFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t play the test sentence.'**
  String get voicesTestFailed;

  /// No description provided for @languageSpeechReady.
  ///
  /// In en, this message translates to:
  /// **'Speech input · Ready'**
  String get languageSpeechReady;

  /// No description provided for @languageSpeechMissing.
  ///
  /// In en, this message translates to:
  /// **'Speech input · Not available on this phone'**
  String get languageSpeechMissing;

  /// No description provided for @languageModelReady.
  ///
  /// In en, this message translates to:
  /// **'Offline translation · Downloaded'**
  String get languageModelReady;

  /// No description provided for @languageModelMissing.
  ///
  /// In en, this message translates to:
  /// **'Offline translation · Not downloaded'**
  String get languageModelMissing;

  /// No description provided for @languageVoiceReady.
  ///
  /// In en, this message translates to:
  /// **'Voice · Installed'**
  String get languageVoiceReady;

  /// No description provided for @languageVoiceDownload.
  ///
  /// In en, this message translates to:
  /// **'Voice · Needs download'**
  String get languageVoiceDownload;

  /// No description provided for @languageVoiceMissing.
  ///
  /// In en, this message translates to:
  /// **'Voice · Not available'**
  String get languageVoiceMissing;

  /// No description provided for @languagesDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get languagesDownload;

  /// No description provided for @languagesDownloadTitle.
  ///
  /// In en, this message translates to:
  /// **'Download offline translation?'**
  String get languagesDownloadTitle;

  /// No description provided for @languagesDownloadBody.
  ///
  /// In en, this message translates to:
  /// **'{language} for translating without internet. About 30 MB.'**
  String languagesDownloadBody(String language);

  /// No description provided for @languagesWifiOnly.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi only'**
  String get languagesWifiOnly;

  /// No description provided for @languagesAnyNetwork.
  ///
  /// In en, this message translates to:
  /// **'Use mobile data too'**
  String get languagesAnyNetwork;

  /// No description provided for @languagesDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t download. Check your connection and try again.'**
  String get languagesDownloadFailed;

  /// No description provided for @settingsLanguagesSection.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get settingsLanguagesSection;

  /// No description provided for @settingsOfflineModels.
  ///
  /// In en, this message translates to:
  /// **'Offline models'**
  String get settingsOfflineModels;

  /// No description provided for @settingsOfflineModelsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What works without internet, per language'**
  String get settingsOfflineModelsSubtitle;

  /// No description provided for @settingsAutoDetectUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Needs Android 14 or later. You\'ll choose the language instead.'**
  String get settingsAutoDetectUnsupported;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// No description provided for @settingsSaveHistory.
  ///
  /// In en, this message translates to:
  /// **'Save conversations'**
  String get settingsSaveHistory;

  /// No description provided for @settingsSaveHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Off by default · stays on this phone'**
  String get settingsSaveHistorySubtitle;

  /// No description provided for @settingsRawAudio.
  ///
  /// In en, this message translates to:
  /// **'Raw audio'**
  String get settingsRawAudio;

  /// No description provided for @settingsRawAudioNever.
  ///
  /// In en, this message translates to:
  /// **'Never saved'**
  String get settingsRawAudioNever;

  /// No description provided for @settingsDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all conversations'**
  String get settingsDeleteAll;

  /// No description provided for @settingsDeleteAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all saved conversations?'**
  String get settingsDeleteAllTitle;

  /// No description provided for @settingsDeleteAllButton.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get settingsDeleteAllButton;

  /// No description provided for @settingsDeleteAllDone.
  ///
  /// In en, this message translates to:
  /// **'All saved conversations deleted'**
  String get settingsDeleteAllDone;

  /// No description provided for @settingsKeepTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep saved conversations?'**
  String get settingsKeepTitle;

  /// No description provided for @settingsKeepBody.
  ///
  /// In en, this message translates to:
  /// **'New conversations won\'t be saved. The ones already saved can stay on this phone or be deleted now.'**
  String get settingsKeepBody;

  /// No description provided for @settingsKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get settingsKeep;

  /// No description provided for @settingsPrivacyData.
  ///
  /// In en, this message translates to:
  /// **'Privacy & data'**
  String get settingsPrivacyData;

  /// No description provided for @settingsPrivacyDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What leaves your phone, and what is kept'**
  String get settingsPrivacyDataSubtitle;

  /// No description provided for @privacyLeavesTitle.
  ///
  /// In en, this message translates to:
  /// **'What leaves your phone'**
  String get privacyLeavesTitle;

  /// No description provided for @privacyLeavesUpdates.
  ///
  /// In en, this message translates to:
  /// **'Update checks: the app\'s version and a random install ID go to the Anuvaad server to find out whether a newer release exists.'**
  String get privacyLeavesUpdates;

  /// No description provided for @privacyLeavesAudio.
  ///
  /// In en, this message translates to:
  /// **'Microphone audio: when Android\'s speech recognizer works online, Android sends the audio to Google\'s speech service. Anuvaad doesn\'t record or upload audio itself.'**
  String get privacyLeavesAudio;

  /// No description provided for @privacyLeavesText.
  ///
  /// In en, this message translates to:
  /// **'Recognized text and the random install ID go to the Anuvaad server so they can be translated.'**
  String get privacyLeavesText;

  /// No description provided for @privacyLeavesVoices.
  ///
  /// In en, this message translates to:
  /// **'Translated text, when it is spoken: Android\'s speech engine usually speaks on the phone, but may use Google\'s online voices for some languages.'**
  String get privacyLeavesVoices;

  /// No description provided for @privacyGoesTitle.
  ///
  /// In en, this message translates to:
  /// **'Where it goes'**
  String get privacyGoesTitle;

  /// No description provided for @privacyGoesServer.
  ///
  /// In en, this message translates to:
  /// **'The Anuvaad server runs on Vercel and passes text to Cloudflare Workers AI for translation. It doesn\'t store or log the text.'**
  String get privacyGoesServer;

  /// No description provided for @privacyGoesOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline translation runs on your phone with Google ML Kit; that text doesn\'t leave the phone.'**
  String get privacyGoesOffline;

  /// No description provided for @privacyGoesReleases.
  ///
  /// In en, this message translates to:
  /// **'App updates and release notes come from GitHub Releases.'**
  String get privacyGoesReleases;

  /// No description provided for @privacyStoredTitle.
  ///
  /// In en, this message translates to:
  /// **'What is stored'**
  String get privacyStoredTitle;

  /// No description provided for @privacyStoredAudio.
  ///
  /// In en, this message translates to:
  /// **'Raw microphone audio is never saved.'**
  String get privacyStoredAudio;

  /// No description provided for @privacyStoredVoiceFiles.
  ///
  /// In en, this message translates to:
  /// **'Spoken translations are temporary audio files, deleted when the conversation closes.'**
  String get privacyStoredVoiceFiles;

  /// No description provided for @privacyStoredHistory.
  ///
  /// In en, this message translates to:
  /// **'Saved conversations stay on this phone, and only when Save conversations is on or you tap Save. They\'re never uploaded.'**
  String get privacyStoredHistory;

  /// No description provided for @privacyStoredLatency.
  ///
  /// In en, this message translates to:
  /// **'The latency report keeps timings only, no words, on this phone.'**
  String get privacyStoredLatency;

  /// No description provided for @privacyControlsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your controls'**
  String get privacyControlsTitle;

  /// No description provided for @privacyControlsHistory.
  ///
  /// In en, this message translates to:
  /// **'Turn Save conversations on or off in Settings, delete one conversation in History, or delete them all in Settings.'**
  String get privacyControlsHistory;

  /// No description provided for @privacyControlsMic.
  ///
  /// In en, this message translates to:
  /// **'Pause or End stops the microphone straight away, and leaving the app pauses the conversation.'**
  String get privacyControlsMic;

  /// No description provided for @privacyFullPage.
  ///
  /// In en, this message translates to:
  /// **'Full privacy page'**
  String get privacyFullPage;

  /// No description provided for @privacyContact.
  ///
  /// In en, this message translates to:
  /// **'Contact details will be added before public launch.'**
  String get privacyContact;

  /// No description provided for @settingsAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get settingsAppLanguage;

  /// No description provided for @appLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'Phone\'s language'**
  String get appLanguageSystem;

  /// No description provided for @settingsDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get settingsDiagnostics;

  /// No description provided for @settingsLatency.
  ///
  /// In en, this message translates to:
  /// **'Latency report'**
  String get settingsLatency;

  /// No description provided for @settingsLatencySubtitle.
  ///
  /// In en, this message translates to:
  /// **'How long each step takes, no words recorded'**
  String get settingsLatencySubtitle;

  /// No description provided for @latencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Latency report'**
  String get latencyTitle;

  /// No description provided for @latencyNote.
  ///
  /// In en, this message translates to:
  /// **'No words are recorded, only timings.'**
  String get latencyNote;

  /// No description provided for @latencyTarget.
  ///
  /// In en, this message translates to:
  /// **'Target: end of speech → first audio under 3 s (p95)'**
  String get latencyTarget;

  /// No description provided for @latencyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No timings yet. Have a conversation, then come back.'**
  String get latencyEmpty;

  /// No description provided for @latencyExport.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get latencyExport;

  /// No description provided for @latencyClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get latencyClear;

  /// No description provided for @latencyPair.
  ///
  /// In en, this message translates to:
  /// **'{source} → {target}'**
  String latencyPair(String source, String target);

  /// No description provided for @latencyStats.
  ///
  /// In en, this message translates to:
  /// **'median {median} s · p95 {p95} s'**
  String latencyStats(String median, String p95);

  /// No description provided for @latencyStageTotal.
  ///
  /// In en, this message translates to:
  /// **'End of speech → first audio'**
  String get latencyStageTotal;

  /// No description provided for @latencyStageFirstWords.
  ///
  /// In en, this message translates to:
  /// **'Speech start → first words'**
  String get latencyStageFirstWords;

  /// No description provided for @latencyStageFinal.
  ///
  /// In en, this message translates to:
  /// **'End of speech → final text'**
  String get latencyStageFinal;

  /// No description provided for @latencyStageTranslation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get latencyStageTranslation;

  /// No description provided for @latencyStageVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice preparation'**
  String get latencyStageVoice;

  /// No description provided for @latencyStagePlayback.
  ///
  /// In en, this message translates to:
  /// **'Playback start'**
  String get latencyStagePlayback;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'gu', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
