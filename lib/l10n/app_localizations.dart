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
