// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'Anuvaad';

  @override
  String get brandName => 'Anuvaad';

  @override
  String get brandTagline => 'कोई भी भाषा बोलें। और करीब आएँ।';

  @override
  String get poweredBy => 'REA Intelligence द्वारा संचालित';

  @override
  String get brandLogoLabel => 'Anuvaad लोगो';

  @override
  String get splashStartFailed =>
      'Anuvaad शुरू नहीं हो सका। कृपया फिर से कोशिश करें।';

  @override
  String get tryAgain => 'फिर से कोशिश करें';

  @override
  String get navHome => 'होम';

  @override
  String get navLanguages => 'भाषाएँ';

  @override
  String get navSettings => 'सेटिंग्स';

  @override
  String get listOr => ' या';

  @override
  String get listAnd => ' और';

  @override
  String onboardingWelcomeBody(String languages) {
    return '$languages बोलने वाले लोगों से सहज रूप से बात करें।';
  }

  @override
  String get onboardingModesTitle => 'दो आसान तरीके';

  @override
  String get onboardingListenTitle => 'सुनें';

  @override
  String get onboardingListenBody =>
      'Anuvaad सामने वाले व्यक्ति को सुनता है और अनुवाद आपके ईयरफ़ोन में सुनाता है।';

  @override
  String get onboardingSpeakTitle => 'बोलें';

  @override
  String get onboardingSpeakBody =>
      'अपनी भाषा में जवाब दें। Anuvaad उसे उनकी भाषा में ज़ोर से बोलता है।';

  @override
  String get onboardingPrivacyTitle => 'आपकी गोपनीयता';

  @override
  String get onboardingPrivacySpeech =>
      'आपकी बोली को आपके फ़ोन की स्पीच सेवा टेक्स्ट में बदलती है।';

  @override
  String get onboardingPrivacyText =>
      'अनुवाद के लिए टेक्स्ट Anuvaad सर्वर पर भेजा जाता है। उसे सहेजा नहीं जाता।';

  @override
  String get onboardingPrivacyStorage =>
      'असली ऑडियो कभी सहेजा नहीं जाता। इतिहास तब तक बंद रहता है जब तक आप उसे चालू न करें।';

  @override
  String get onboardingPrivacyQuality =>
      'अनुवाद की गुणवत्ता और गति आपके नेटवर्क और डिवाइस के अनुसार बदल सकती है।';

  @override
  String get onboardingPrivacyLink => 'पूरी गोपनीयता सूचना पढ़ें';

  @override
  String get onboardingSkip => 'छोड़ें';

  @override
  String get onboardingNext => 'आगे';

  @override
  String get onboardingGetStarted => 'शुरू करें';

  @override
  String get homeGreeting => 'आपका अपना भाषा सेतु';

  @override
  String get homeHeadlineTop => 'खुलकर बोलें।';

  @override
  String get homeHeadlineBottom => 'सबको समझें।';

  @override
  String get homeHeroTitle => 'आपकी आवाज़, दुनिया भर में समझी जाए।';

  @override
  String homeHeroBody(String languages) {
    return '$languages में तुरंत अनुवाद।';
  }

  @override
  String get homeModesTitle => 'बातचीत शुरू करें';

  @override
  String get homeModesSubtitle => 'एक तरीका चुनें';

  @override
  String get homeInPersonTitle => 'आमने-सामने बातचीत';

  @override
  String get homeInPersonSubtitle => 'सामने बैठकर सहज बात करें';

  @override
  String get homeMeetingTitle => 'ऑनलाइन मीटिंग';

  @override
  String get homeMeetingSubtitle => 'पास में स्पीकर पर चल रही मीटिंग';

  @override
  String get homeComingSoon => 'आने वाले अपडेट में';

  @override
  String get homeMyLanguage => 'मेरी भाषा';

  @override
  String get homeChange => 'बदलें';

  @override
  String get homeQuickAccessTitle => 'झटपट पहुँच';

  @override
  String get homeQuickAccessSubtitle => 'Anuvaad को जानें';

  @override
  String get languagesTitle => 'भाषाएँ';

  @override
  String languagesIntro(int count) {
    return 'वह भाषा चुनें जो आप समझते हैं और वह भाषा जो सामने वाला व्यक्ति बोलता है। सभी $count मुख्य भाषाएँ पहले से शामिल हैं।';
  }

  @override
  String get languagesMyLabel => 'मेरी भाषा · इसमें अनुवाद करें';

  @override
  String get languagesOtherLabel => 'सामने वाला व्यक्ति · बोलता है';

  @override
  String get languagesAutoDetect => 'अपने-आप पहचान';

  @override
  String get languagesSwap => 'भाषाएँ अदला-बदली करें';

  @override
  String get languagesSameLanguage => 'दो अलग-अलग भाषाएँ चुनें।';

  @override
  String get languagesIncludedTitle => 'पहले से शामिल';

  @override
  String languagesIncludedCount(int count) {
    return '$count मुख्य भाषाएँ';
  }

  @override
  String get languagesCoreChip => 'मुख्य';

  @override
  String get languagesMoreTitle => 'और भाषाएँ';

  @override
  String get languagesMoreSubtitle => 'आगे के रिलीज़ में';

  @override
  String languagesPackDetail(String nativeName) {
    return '$nativeName · भाषा पैक';
  }

  @override
  String get languagesSoon => 'जल्द';

  @override
  String languagesPackPlanned(String name) {
    return '$name भाषा पैक आने वाले रिलीज़ के लिए योजना में है।';
  }

  @override
  String get languagesSave => 'भाषा की पसंद सहेजें';

  @override
  String get languagesSaved => 'भाषा की पसंद सहेजी गई';

  @override
  String get capabilitySpeechInput => 'बोलकर इनपुट';

  @override
  String get capabilityTranslation => 'अनुवाद';

  @override
  String get capabilityVoiceOutput => 'आवाज़ में आउटपुट';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get settingsAppearance => 'रूप-रंग';

  @override
  String get settingsAppearanceDefault => 'डिफ़ॉल्ट: सिस्टम';

  @override
  String get themeSystem => 'सिस्टम';

  @override
  String get themeLight => 'लाइट';

  @override
  String get themeDark => 'डार्क';

  @override
  String get settingsAbout => 'जानकारी';

  @override
  String get settingsAboutAnuvaad => 'Anuvaad के बारे में';

  @override
  String settingsVersion(String version, String build) {
    return 'v$version ($build)';
  }

  @override
  String get updateAvailableTitle => 'अपडेट उपलब्ध है';

  @override
  String updateSubtitle(String version, String date, String size) {
    return 'संस्करण $version · $date · $size MB';
  }

  @override
  String get updateWhatsNew => 'नया क्या है';

  @override
  String get updateFixed => 'ठीक किया गया';

  @override
  String get updateLater => 'बाद में';

  @override
  String get updateNow => 'अभी अपडेट करें';

  @override
  String get updateMandatory =>
      'Anuvaad का उपयोग जारी रखने के लिए यह अपडेट ज़रूरी है।';

  @override
  String updateDownloading(int percent) {
    return 'डाउनलोड हो रहा है… $percent%';
  }

  @override
  String get updateVerifying => 'डाउनलोड की जाँच हो रही है…';

  @override
  String get updateInstalling => 'इंस्टॉलर खुल रहा है…';

  @override
  String get updatePermissionTitle => 'अपडेट की अनुमति दें';

  @override
  String get updatePermissionBody =>
      'अपडेट इंस्टॉल करने के लिए Android को चाहिए कि आप Anuvaad को ऐप इंस्टॉल करने दें। “इस स्रोत से अनुमति दें” चालू करें, फिर वापस आएँ।';

  @override
  String get updateOpenSettings => 'सेटिंग्स खोलें';

  @override
  String get updateFailedPermission =>
      'जब तक आप यह अनुमति नहीं देते, अपडेट इंस्टॉल नहीं हो सकते। आप कभी भी सेटिंग्स → अपडेट जाँचें से फिर कोशिश कर सकते हैं।';

  @override
  String get updateFailedCheck =>
      'अपडेट की जाँच नहीं हो सकी। अपना कनेक्शन देखें और फिर कोशिश करें।';

  @override
  String get updateFailedDownload =>
      'डाउनलोड पूरा नहीं हुआ। अपना कनेक्शन देखें और फिर कोशिश करें।';

  @override
  String get updateFailedIntegrity =>
      'डाउनलोड खराब था, इसलिए इंस्टॉल नहीं किया गया। कृपया फिर कोशिश करें।';

  @override
  String get updateFailedInstall =>
      'Android इंस्टॉलर नहीं खोल सका। कृपया फिर कोशिश करें।';

  @override
  String get updateClose => 'बंद करें';

  @override
  String get updateNotInstalledTitle => 'अपडेट इंस्टॉल नहीं हुआ';

  @override
  String get updateNotInstalledBody =>
      'अगर Android ने “ऐप इंस्टॉल नहीं हुआ” कहा, तो Anuvaad की यह कॉपी अनइंस्टॉल करें और वेबसाइट से फिर इंस्टॉल करें।';

  @override
  String get updateOpenWebsite => 'वेबसाइट खोलें';

  @override
  String whatsNewTitle(String version) {
    return '$version में नया क्या है';
  }

  @override
  String get whatsNewGotIt => 'समझ गया';

  @override
  String get settingsCheckUpdates => 'अपडेट जाँचें';

  @override
  String get settingsUpToDate => 'आपके पास नया संस्करण है';

  @override
  String get settingsReleaseNotes => 'रिलीज़ नोट्स';

  @override
  String get settingsUpdatesUnavailable =>
      'इस प्रीव्यू बिल्ड में अपडेट उपलब्ध नहीं हैं।';

  @override
  String get releaseNotesTitle => 'रिलीज़ नोट्स';

  @override
  String releaseNotesVersion(String version) {
    return 'संस्करण $version';
  }

  @override
  String get releaseNotesLoadFailed => 'रिलीज़ नोट्स लोड नहीं हो सके।';

  @override
  String get releaseNotesEmpty => 'अभी कोई रिलीज़ नहीं।';

  @override
  String get updateReadyToInstall =>
      'अपडेट डाउनलोड और जाँच हो चुका है। इंस्टॉल के लिए तैयार है।';

  @override
  String get updateInstallNow => 'अभी इंस्टॉल करें';

  @override
  String get conversationTitle => 'आमने-सामने बातचीत';

  @override
  String get conversationListen => 'सुनें';

  @override
  String conversationListenHint(String language) {
    return 'वे $language बोलते हैं';
  }

  @override
  String get conversationSpeak => 'बोलें';

  @override
  String conversationSpeakHint(String language) {
    return 'आप $language बोलते हैं';
  }

  @override
  String get conversationStop => 'रोकें';

  @override
  String get conversationListening => 'सुन रहे हैं…';

  @override
  String get conversationTranslating => 'अनुवाद हो रहा है…';

  @override
  String conversationOtherLabel(String language) {
    return 'सामने वाला व्यक्ति · $language';
  }

  @override
  String conversationYouLabel(String language) {
    return 'आप · $language';
  }

  @override
  String get conversationOfflineLabel => 'ऑफ़लाइन अनुवाद';

  @override
  String get conversationEmptyTitle => 'बातचीत शुरू करें';

  @override
  String get conversationEmptyBody =>
      'सुनें दबाएँ, Anuvaad हर बारी को सुनता, अनुवाद करता और बोलता रहेगा। जवाब देने के लिए बोलें दबाएँ।';

  @override
  String get conversationChooseOtherLanguage => 'वे कौन-सी भाषा बोलेंगे?';

  @override
  String get conversationRetry => 'फिर से कोशिश करें';

  @override
  String get conversationAllowMic => 'अनुमति दें';

  @override
  String get conversationOpenSettings => 'सेटिंग्स खोलें';

  @override
  String get noticeMicDenied =>
      'बोली सुनने के लिए Anuvaad को माइक्रोफ़ोन चाहिए।';

  @override
  String get noticeMicPermanentlyDenied =>
      'माइक्रोफ़ोन की अनुमति बंद है। बातचीत के लिए इसे सेटिंग्स में चालू करें।';

  @override
  String get noticeRecognizerUnavailable =>
      'इस फ़ोन पर बोली पहचान उपलब्ध नहीं है। Google ऐप इंस्टॉल या अपडेट करें, फिर कोशिश करें।';

  @override
  String get noticeNoSpeech =>
      'सुनाई नहीं दिया। फ़ोन के थोड़ा पास से फिर कोशिश करें।';

  @override
  String get noticeNetwork =>
      'बोली पहचान के लिए इंटरनेट चाहिए। अपना इंटरनेट देखें और फिर कोशिश करें।';

  @override
  String noticeLanguageUnsupported(String language) {
    return 'इस फ़ोन पर अभी $language बोली पहचान उपलब्ध नहीं है। Google ऐप अपडेट करें, या उसकी आवाज़ सेटिंग्स में $language जोड़ें।';
  }

  @override
  String get noticeBusy =>
      'माइक्रोफ़ोन व्यस्त है। थोड़ी देर में फिर कोशिश करें।';

  @override
  String get noticeGeneric => 'बोली पहचान में कुछ गड़बड़ हुई। फिर कोशिश करें।';

  @override
  String get translationOfflineNotReady =>
      'आप ऑफ़लाइन हैं, और ऑफ़लाइन अनुवाद अभी डाउनलोड नहीं हुआ है। उसे डाउनलोड करने के लिए एक बार Wi-Fi से जुड़ें।';

  @override
  String get translationFailed => 'इसका अनुवाद नहीं हो सका।';

  @override
  String get audioDeviceSpeaker => 'फ़ोन स्पीकर';

  @override
  String get audioDeviceWired => 'तार वाले ईयरफ़ोन';

  @override
  String get audioDeviceBluetooth => 'Bluetooth ईयरफ़ोन';

  @override
  String get audioDeviceUsb => 'USB ईयरफ़ोन';

  @override
  String get noticeEarphonesDisconnected =>
      'ईयरफ़ोन हट गए। अब अनुवाद फ़ोन स्पीकर पर चलेंगे।';

  @override
  String noticeSpeakerUnavailable(String device) {
    return 'फ़ोन स्पीकर इस्तेमाल नहीं हो सका। आपका जवाब $device में चला।';
  }

  @override
  String get noticePlaybackFailed =>
      'अनुवाद नहीं चल सका। फिर कोशिश के लिए दोबारा सुनें दबाएँ।';

  @override
  String conversationOutput(String device) {
    return 'आउटपुट: $device';
  }

  @override
  String get conversationReplay => 'अनुवाद दोबारा सुनें';

  @override
  String get conversationPlaying => 'चल रहा है…';

  @override
  String conversationNoVoice(String language) {
    return 'इस फ़ोन पर $language आवाज़ नहीं है, इसलिए यह अनुवाद सिर्फ़ टेक्स्ट में है।';
  }

  @override
  String get conversationInstallVoice => 'आवाज़ इंस्टॉल करें';

  @override
  String get audioDevicesTitle => 'ऑडियो डिवाइस';

  @override
  String get audioDevicesIntro =>
      'चुनें कि हर आवाज़ कहाँ चले। सिर्फ़ अभी जुड़े डिवाइस दिखाए जाते हैं।';

  @override
  String get audioMicTitle => 'माइक्रोफ़ोन इनपुट';

  @override
  String get audioMicSubtitle => 'सामने वाले व्यक्ति की बोली सुनना';

  @override
  String get audioMicPhone => 'फ़ोन का माइक्रोफ़ोन';

  @override
  String get audioForMeTitle => 'अनुवादित आवाज़ · आप';

  @override
  String get audioForMeSubtitle => 'अनुवाद अकेले में सुनें';

  @override
  String get audioForOtherTitle => 'आपका जवाब · सामने वाला व्यक्ति';

  @override
  String get audioForOtherSubtitle => 'अनुवादित बोली ज़ोर से चलाएँ';

  @override
  String get audioOptionEarphones => 'ईयरफ़ोन';

  @override
  String get audioOptionSpeaker => 'फ़ोन स्पीकर';

  @override
  String audioNow(String device) {
    return 'अभी: $device';
  }

  @override
  String get audioNoEarphones =>
      'कोई ईयरफ़ोन नहीं जुड़ा, इसलिए यह फ़ोन स्पीकर पर चलेगा।';

  @override
  String get audioTestSound => 'आउटपुट ध्वनि जाँचें';

  @override
  String audioTestPlayedOn(String device) {
    return '$device पर चला';
  }

  @override
  String get audioCompatibility =>
      'Bluetooth माइक्रोफ़ोन और आवाज़ का रास्ता हेडसेट और Android संस्करण के अनुसार बदलता है। Anuvaad वही रास्ता दिखाता है जो Android सच में इस्तेमाल करता है।';

  @override
  String get settingsAudio => 'ऑडियो';

  @override
  String get settingsAudioDevices => 'ऑडियो डिवाइस';

  @override
  String get settingsAudioDevicesSubtitle => 'अनुवाद कहाँ चलें';

  @override
  String get noticePausedForSilence =>
      'एक मिनट की चुप्पी के बाद सुनना रोका गया। जारी रखने के लिए सुनें दबाएँ।';

  @override
  String get noticePausedForInterruption =>
      'कॉल या अलार्म के कारण रोका गया। जारी रखने के लिए सुनें दबाएँ।';

  @override
  String noticeAskToRepeat(String language) {
    return 'ठीक है: $language। उनसे फिर से कहने को कहें।';
  }

  @override
  String get conversationLanguageUnclear =>
      'भाषा साफ़ नहीं है। उन्होंने कौन-सी भाषा बोली?';

  @override
  String transcriptHeader(String date, int minutes) {
    return 'Anuvaad बातचीत · $date · $minutes मिनट';
  }

  @override
  String get transcriptYou => 'आप';

  @override
  String get transcriptOtherPerson => 'सामने वाला व्यक्ति';

  @override
  String get transcriptNotTranslated => 'अनुवाद नहीं हुआ';

  @override
  String get transcriptUnclear => 'भाषा साफ़ नहीं';

  @override
  String get statusReady => 'सुनने के लिए तैयार';

  @override
  String get statusListening => 'सुन रहे हैं';

  @override
  String get statusRecording => 'आपकी बारी';

  @override
  String get statusChoosingLanguage => 'भाषा चुनें';

  @override
  String get statusTranslating => 'अनुवाद हो रहा है…';

  @override
  String get statusSpeaking => 'बोल रहे हैं';

  @override
  String get statusReviewing => 'अपना जवाब जाँचें';

  @override
  String get statusPaused => 'रुका हुआ';

  @override
  String get statusEnded => 'समाप्त';

  @override
  String get modeInPerson => 'आमने-सामने';

  @override
  String get modeMeeting => 'मीटिंग';

  @override
  String headerTheirLanguage(String language) {
    return 'उनकी भाषा: $language';
  }

  @override
  String headerTheirLanguageDetected(String language) {
    return 'उनकी भाषा: $language · पहचानी गई';
  }

  @override
  String get headerTheirLanguageAuto => 'उनकी भाषा: अपने-आप';

  @override
  String get headerChange => 'बदलें';

  @override
  String get headerChooseTitle => 'वे कौन-सी भाषा बोलते हैं?';

  @override
  String get conversationPause => 'रोकें';

  @override
  String get conversationEnd => 'बातचीत समाप्त करें';

  @override
  String conversationOtherLabelDetected(String language) {
    return 'सामने वाला व्यक्ति · $language · पहचानी गई';
  }

  @override
  String get reviewHint => 'उनके सुनने से पहले अपना जवाब जाँच लें।';

  @override
  String get reviewEdit => 'बदलें';

  @override
  String get reviewPlay => 'चलाएँ';

  @override
  String get reviewDiscard => 'हटाएँ';

  @override
  String get reviewEditTitle => 'आपने जो कहा उसे बदलें';

  @override
  String get reviewTranslateAgain => 'फिर से अनुवाद करें';

  @override
  String get summaryTitle => 'बातचीत समाप्त';

  @override
  String summaryMinutes(int minutes) {
    return '$minutes मिनट';
  }

  @override
  String summaryTurns(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बारियाँ',
      one: '1 बारी',
    );
    return '$_temp0';
  }

  @override
  String get summaryCopy => 'ट्रांसक्रिप्ट कॉपी करें';

  @override
  String get summaryCopied => 'ट्रांसक्रिप्ट कॉपी हो गई';

  @override
  String get summaryDone => 'हो गया';

  @override
  String get summaryOpen => 'सारांश';

  @override
  String get settingsConversation => 'बातचीत';

  @override
  String get settingsAutoDetect => 'भाषा की अपने-आप पहचान';

  @override
  String get settingsAutoDetectSubtitle =>
      'अंग्रेज़ी, हिंदी और गुजराती पहचानें';

  @override
  String get settingsReviewReply => 'चलाने से पहले मेरा जवाब जाँचें';

  @override
  String get settingsReviewReplySubtitle =>
      'सामने वाले के सुनने से पहले अपना जवाब जाँचें और बदलें';

  @override
  String get historyTitle => 'इतिहास';

  @override
  String get historySearchHint => 'सहेजी गई बातचीत खोजें…';

  @override
  String get historyOffTitle => 'बातचीत सहेजना बंद है';

  @override
  String get historyOffBody =>
      'बातचीत इस फ़ोन पर रखने के लिए इसे चालू करें। जब तक आप ऐसा नहीं करते, कुछ भी सहेजा नहीं जाता।';

  @override
  String get historyTurnOn => 'सेटिंग्स में चालू करें';

  @override
  String get historyEmpty => 'अभी कोई बातचीत सहेजी नहीं गई';

  @override
  String historyNoMatch(String query) {
    return '“$query” से कोई बातचीत मेल नहीं खाती।';
  }

  @override
  String historyMinutesChip(int minutes) {
    return '$minutes मिनट';
  }

  @override
  String get historyDetailTitle => 'बातचीत';

  @override
  String get historyNotFound => 'यह बातचीत अब सहेजी नहीं है।';

  @override
  String historyLineOther(String language, String time) {
    return 'सामने वाला व्यक्ति · $language · $time';
  }

  @override
  String historyLineYou(String language, String time) {
    return 'आप · $language · $time';
  }

  @override
  String get historyCopy => 'कॉपी करें';

  @override
  String get historyShare => 'शेयर करें';

  @override
  String get historyDelete => 'हटाएँ';

  @override
  String get historyDeleteTitle => 'यह बातचीत हटाएँ?';

  @override
  String get historyDeleteBody =>
      'यह इस फ़ोन से हट जाएगी और वापस नहीं लाई जा सकेगी।';

  @override
  String get homeRecentTitle => 'हाल की बातचीत';

  @override
  String get homeSeeAll => 'सब देखें';

  @override
  String homeDeviceStatus(String me, String reply) {
    return 'अनुवादित आवाज़: $me · जवाब: $reply';
  }

  @override
  String get summarySave => 'इतिहास में सहेजें';

  @override
  String get summarySaved => 'इतिहास में सहेजी गई';

  @override
  String get settingsSpeechSpeed => 'बोलने की गति';

  @override
  String get speechRateSlow => 'धीमी';

  @override
  String get speechRateNormal => 'सामान्य';

  @override
  String get speechRateFast => 'तेज़';

  @override
  String get settingsVoices => 'आवाज़ें';

  @override
  String get settingsVoicesSubtitle => 'हर भाषा के लिए आवाज़ चुनें';

  @override
  String get voicesTitle => 'आवाज़ें';

  @override
  String get voicesIntro =>
      'हर भाषा के लिए आवाज़ चुनें। डिफ़ॉल्ट में फ़ोन खुद चुनता है।';

  @override
  String get voicesDefault => 'डिफ़ॉल्ट आवाज़';

  @override
  String get voicesDefaultSubtitle => 'फ़ोन द्वारा चुनी गई';

  @override
  String voicesOnPhone(int number) {
    return 'आवाज़ $number · इस फ़ोन पर';
  }

  @override
  String voicesOnline(int number) {
    return 'आवाज़ $number · इंटरनेट चाहिए';
  }

  @override
  String get voicesTest => 'जाँचें';

  @override
  String voicesMissing(String language) {
    return 'इस फ़ोन पर अभी $language आवाज़ नहीं है। भाषाएँ से एक इंस्टॉल करें।';
  }

  @override
  String get voicesTestFailed => 'जाँच वाला वाक्य नहीं चल सका।';

  @override
  String get languageSpeechReady => 'बोलकर इनपुट · तैयार';

  @override
  String get languageSpeechMissing => 'बोलकर इनपुट · इस फ़ोन पर उपलब्ध नहीं';

  @override
  String get languageModelReady => 'ऑफ़लाइन अनुवाद · डाउनलोड हो चुका';

  @override
  String get languageModelMissing => 'ऑफ़लाइन अनुवाद · डाउनलोड नहीं हुआ';

  @override
  String get languageVoiceReady => 'आवाज़ · इंस्टॉल है';

  @override
  String get languageVoiceDownload => 'आवाज़ · डाउनलोड करनी है';

  @override
  String get languageVoiceMissing => 'आवाज़ · उपलब्ध नहीं';

  @override
  String get languagesDownload => 'डाउनलोड करें';

  @override
  String get languagesDownloadTitle => 'ऑफ़लाइन अनुवाद डाउनलोड करें?';

  @override
  String languagesDownloadBody(String language) {
    return 'बिना इंटरनेट अनुवाद के लिए $language। लगभग 30 MB।';
  }

  @override
  String get languagesWifiOnly => 'सिर्फ़ Wi-Fi';

  @override
  String get languagesAnyNetwork => 'मोबाइल डेटा भी इस्तेमाल करें';

  @override
  String get languagesDownloadFailed =>
      'डाउनलोड नहीं हो सका। अपना कनेक्शन देखें और फिर कोशिश करें।';

  @override
  String get settingsLanguagesSection => 'भाषाएँ';

  @override
  String get settingsOfflineModels => 'ऑफ़लाइन मॉडल';

  @override
  String get settingsOfflineModelsSubtitle =>
      'हर भाषा में बिना इंटरनेट क्या चलता है';

  @override
  String get settingsAutoDetectUnsupported =>
      'Android 14 या नया चाहिए। इसकी जगह आप भाषा चुनेंगे।';

  @override
  String get settingsPrivacy => 'गोपनीयता';

  @override
  String get settingsSaveHistory => 'बातचीत सहेजें';

  @override
  String get settingsSaveHistorySubtitle =>
      'डिफ़ॉल्ट रूप से बंद · इसी फ़ोन पर रहती है';

  @override
  String get settingsRawAudio => 'असली ऑडियो';

  @override
  String get settingsRawAudioNever => 'कभी सहेजा नहीं जाता';

  @override
  String get settingsDeleteAll => 'सारी बातचीत हटाएँ';

  @override
  String get settingsDeleteAllTitle => 'सारी सहेजी गई बातचीत हटाएँ?';

  @override
  String get settingsDeleteAllButton => 'सब हटाएँ';

  @override
  String get settingsDeleteAllDone => 'सारी सहेजी गई बातचीत हटा दी गई';

  @override
  String get settingsKeepTitle => 'सहेजी गई बातचीत रखें?';

  @override
  String get settingsKeepBody =>
      'नई बातचीत सहेजी नहीं जाएगी। जो पहले से सहेजी गई हैं, वे इस फ़ोन पर रह सकती हैं या अभी हटाई जा सकती हैं।';

  @override
  String get settingsKeep => 'रखें';

  @override
  String get settingsPrivacyData => 'गोपनीयता और डेटा';

  @override
  String get settingsPrivacyDataSubtitle =>
      'आपके फ़ोन से क्या बाहर जाता है, और क्या रखा जाता है';

  @override
  String get privacyLeavesTitle => 'आपके फ़ोन से क्या बाहर जाता है';

  @override
  String get privacyLeavesUpdates =>
      'अपडेट जाँच: नया रिलीज़ है या नहीं, यह जानने के लिए ऐप का संस्करण और एक रैंडम इंस्टॉल ID Anuvaad सर्वर पर जाते हैं।';

  @override
  String get privacyLeavesAudio =>
      'माइक्रोफ़ोन ऑडियो: जब Android की बोली पहचान ऑनलाइन काम करती है, तब Android ऑडियो को Google की स्पीच सेवा पर भेजता है। Anuvaad खुद ऑडियो रिकॉर्ड या अपलोड नहीं करता।';

  @override
  String get privacyLeavesText =>
      'पहचाना गया टेक्स्ट और रैंडम इंस्टॉल ID अनुवाद के लिए Anuvaad सर्वर पर जाते हैं।';

  @override
  String get privacyLeavesVoices =>
      'अनुवादित टेक्स्ट, जब उसे बोला जाता है: Android का स्पीच इंजन आमतौर पर फ़ोन पर ही बोलता है, पर कुछ भाषाओं के लिए Google की ऑनलाइन आवाज़ें इस्तेमाल कर सकता है।';

  @override
  String get privacyGoesTitle => 'यह कहाँ जाता है';

  @override
  String get privacyGoesServer =>
      'Anuvaad सर्वर Vercel पर चलता है और अनुवाद के लिए टेक्स्ट Cloudflare Workers AI को भेजता है। यह टेक्स्ट को न सहेजता है, न लॉग करता है।';

  @override
  String get privacyGoesOffline =>
      'ऑफ़लाइन अनुवाद आपके फ़ोन पर Google ML Kit से होता है; वह टेक्स्ट फ़ोन से बाहर नहीं जाता।';

  @override
  String get privacyGoesReleases =>
      'ऐप अपडेट और रिलीज़ नोट्स GitHub Releases से आते हैं।';

  @override
  String get privacyStoredTitle => 'क्या रखा जाता है';

  @override
  String get privacyStoredAudio =>
      'असली माइक्रोफ़ोन ऑडियो कभी सहेजा नहीं जाता।';

  @override
  String get privacyStoredVoiceFiles =>
      'बोले गए अनुवाद अस्थायी ऑडियो फ़ाइलें होते हैं, जो बातचीत बंद होने पर हटा दी जाती हैं।';

  @override
  String get privacyStoredHistory =>
      'सहेजी गई बातचीत इसी फ़ोन पर रहती है, और सिर्फ़ तब जब बातचीत सहेजें चालू हो या आप सहेजें दबाएँ। इन्हें कभी अपलोड नहीं किया जाता।';

  @override
  String get privacyStoredLatency =>
      'लेटेंसी रिपोर्ट इसी फ़ोन पर सिर्फ़ समय रखती है, कोई शब्द नहीं।';

  @override
  String get privacyControlsTitle => 'आपके नियंत्रण';

  @override
  String get privacyControlsHistory =>
      'सेटिंग्स में बातचीत सहेजें चालू या बंद करें, इतिहास में एक बातचीत हटाएँ, या सेटिंग्स में सारी हटाएँ।';

  @override
  String get privacyControlsMic =>
      'रोकें या समाप्त करें तुरंत माइक्रोफ़ोन बंद कर देते हैं, और ऐप से बाहर जाने पर बातचीत रुक जाती है।';

  @override
  String get privacyFullPage => 'पूरा गोपनीयता पेज';

  @override
  String get privacyContact =>
      'संपर्क जानकारी सार्वजनिक लॉन्च से पहले जोड़ी जाएगी।';

  @override
  String get settingsAppLanguage => 'ऐप की भाषा';

  @override
  String get appLanguageSystem => 'फ़ोन की भाषा';

  @override
  String get settingsDiagnostics => 'डायग्नॉस्टिक्स';

  @override
  String get settingsLatency => 'लेटेंसी रिपोर्ट';

  @override
  String get settingsLatencySubtitle =>
      'हर चरण में कितना समय लगता है, कोई शब्द दर्ज नहीं';

  @override
  String get latencyTitle => 'लेटेंसी रिपोर्ट';

  @override
  String get latencyNote => 'कोई शब्द दर्ज नहीं होता, सिर्फ़ समय।';

  @override
  String get latencyTarget =>
      'लक्ष्य: बोलना ख़त्म होने से पहली आवाज़ तक 3 s से कम (p95)';

  @override
  String get latencyEmpty =>
      'अभी कोई समय दर्ज नहीं। एक बातचीत करें, फिर वापस आएँ।';

  @override
  String get latencyExport => 'CSV निर्यात करें';

  @override
  String get latencyClear => 'साफ़ करें';

  @override
  String latencyPair(String source, String target) {
    return '$source → $target';
  }

  @override
  String latencyStats(String median, String p95) {
    return 'मध्यमान $median s · p95 $p95 s';
  }

  @override
  String get latencyStageTotal => 'बोलना ख़त्म → पहली आवाज़';

  @override
  String get latencyStageFirstWords => 'बोलना शुरू → पहले शब्द';

  @override
  String get latencyStageFinal => 'बोलना ख़त्म → अंतिम टेक्स्ट';

  @override
  String get latencyStageTranslation => 'अनुवाद';

  @override
  String get latencyStageVoice => 'आवाज़ की तैयारी';

  @override
  String get latencyStagePlayback => 'चलना शुरू';

  @override
  String get meetingTitle => 'मीटिंग मोड';

  @override
  String get meetingExplain =>
      'Android ऐप्स को Zoom, Meet, Teams या WhatsApp का ऑडियो कैप्चर नहीं करने देता। मीटिंग को लैपटॉप या स्पीकरफ़ोन पर चलाएँ और अपना फ़ोन उसके पास रखें। Anuvaad फ़ोन के माइक्रोफ़ोन से सुनता है और अनुवाद आपके ईयरफ़ोन में चलाता है।';

  @override
  String get meetingLanguage => 'मीटिंग की भाषा';

  @override
  String get meetingTestMic => 'माइक्रोफ़ोन जाँचें';

  @override
  String get meetingTestListening => 'कुछ सेकंड सुन रहे हैं…';

  @override
  String meetingHeard(String text) {
    return 'हमने सुना: $text';
  }

  @override
  String get meetingHeardNothing =>
      'हमें कुछ सुनाई नहीं दिया। पास आएँ या मीटिंग की आवाज़ बढ़ाएँ।';

  @override
  String get meetingConsent =>
      'मीटिंग के सभी लोगों को पता है कि अनुवादक इस्तेमाल हो रहा है।';

  @override
  String get meetingStart => 'सुनना शुरू करें';

  @override
  String a11yOtherSaid(String language, String text) {
    return 'सामने वाला व्यक्ति, $language: $text';
  }

  @override
  String a11yYouSaid(String language, String text) {
    return 'आप, $language: $text';
  }

  @override
  String a11yTranslation(String text) {
    return 'अनुवाद: $text';
  }
}
