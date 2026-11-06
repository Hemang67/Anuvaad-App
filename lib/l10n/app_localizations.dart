import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

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
  /// **'Tap Listen when the other person talks, or Speak to reply. Translations appear here as text. Spoken translations arrive in the next update.'**
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
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
