import 'dart:async';

import 'package:anuvaad/core/permissions/microphone_permission.dart';
import 'package:anuvaad/features/conversation/application/translation_service.dart';
import 'package:anuvaad/features/conversation/data/android_speech_recognizer.dart';
import 'package:anuvaad/features/conversation/data/mlkit_translator.dart';
import 'package:anuvaad/features/conversation/domain/speech_recognition.dart';
import 'package:anuvaad/features/conversation/domain/translation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/conversation_fakes.dart';

const _prefs = <String, Object>{'onboarding_complete': true, 'my_language': 'en-IN', 'other_language': 'hi-IN'};

void main() {
  late FakeSpeechRecognizer recognizer;
  late FakeTranslator cloud;
  late FakeTranslator offline;
  late FakeMicrophonePermission mic;

  setUp(() {
    recognizer = FakeSpeechRecognizer();
    cloud = FakeTranslator(reply: (_) => 'Where are you going today?');
    offline = FakeTranslator(provenance: TranslationProvenance.offline, provider: 'mlkit', reply: (_) => 'Where are you going?');
    mic = FakeMicrophonePermission();
  });

  Future<void> openConversation(WidgetTester tester, {Map<String, Object> prefs = _prefs}) async {
    await pumpAnuvaadApp(tester, prefs: prefs, overrides: [
      speechRecognizerProvider.overrideWithValue(recognizer),
      microphonePermissionProvider.overrideWithValue(mic),
      translationServiceProvider.overrideWithValue(TranslationService(cloud: cloud, offline: offline)),
    ]);
    await tester.scrollUntilVisible(find.text('In-person conversation'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('In-person conversation'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('conversation-screen')), findsOneWidget);
  }

  Future<void> say(WidgetTester tester, RecognitionEvent event) async {
    recognizer.emit(event);
    await tester.pumpAndSettle();
  }

  testWidgets('home in-person card opens the conversation screen and Back returns home', (tester) async {
    await openConversation(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-screen')), findsOneWidget);
  });

  testWidgets('empty state explains what to do', (tester) async {
    await openConversation(tester);
    expect(find.text('Start a conversation'), findsOneWidget);
    expect(
      find.text('Tap Listen when the other person talks, or Speak to reply. Translations appear here as text. '
          'Spoken translations arrive in the next update.'),
      findsOneWidget,
    );
    expect(find.text('They speak Hindi'), findsOneWidget);
    expect(find.text('You speak English'), findsOneWidget);
  });

  testWidgets('listen shows live text, then the translation', (tester) async {
    await openConversation(tester);
    await tester.tap(find.byKey(const Key('listen-button')));
    await tester.pumpAndSettle();
    expect(recognizer.started, ['hi-IN']);

    await say(tester, const PartialResult('आप'));
    final partial = tester.widget<Text>(find.text('आप'));
    expect(partial.style?.fontStyle, FontStyle.italic);

    await say(tester, const FinalResult('आप आज कहाँ जा रहे हैं?'));
    expect(find.text('OTHER PERSON · HINDI'), findsOneWidget);
    expect(find.text('आप आज कहाँ जा रहे हैं?'), findsOneWidget);
    expect(find.text('Where are you going today?'), findsOneWidget);
    expect(find.text('Offline translation'), findsNothing);
    expect(find.text('Start a conversation'), findsNothing);
  });

  testWidgets('the newest translation stays in view after many turns', (tester) async {
    cloud.reply = (r) => 'Translation of "${r.text}": a long answer that wraps over several lines on a phone screen, '
        'so that the card grows when it arrives and the list must scroll to keep it visible.';
    await openConversation(tester);
    final list = tester.getRect(find.byType(Scaffold));
    for (var i = 1; i <= 6; i++) {
      cloud.holdAll = Completer<void>();
      await tester.tap(find.byKey(const Key('listen-button')));
      await tester.pumpAndSettle();
      await say(tester, FinalResult('वाक्य नंबर $i, थोड़ा लंबा ताकि कार्ड बड़ा हो।'));
      cloud.holdAll!.complete();
      await tester.pumpAndSettle();
      final translation = find.textContaining('Translation of "वाक्य नंबर $i');
      final viewport = tester.getRect(find.byType(ListView));
      expect(tester.getRect(translation).bottom, lessThanOrEqualTo(viewport.bottom + 0.5), reason: 'turn $i');
      expect(viewport.bottom, lessThanOrEqualTo(list.bottom));
    }
  });

  testWidgets('speak turns are labelled as yours', (tester) async {
    await openConversation(tester);
    await tester.tap(find.byKey(const Key('speak-button')));
    await tester.pumpAndSettle();
    expect(recognizer.started, ['en-IN']);
    await say(tester, const FinalResult("I'm going to the office."));
    expect(find.text('YOU · ENGLISH'), findsOneWidget);
  });

  testWidgets('offline translations carry the Offline translation label', (tester) async {
    cloud.error = Exception('no network');
    await openConversation(tester);
    await tester.tap(find.byKey(const Key('listen-button')));
    await tester.pumpAndSettle();
    await say(tester, const FinalResult('आप कहाँ जा रहे हैं?'));
    expect(find.text('Where are you going?'), findsOneWidget);
    expect(find.text('Offline translation'), findsOneWidget);
  });

  testWidgets('stop button replaces listen while active and speak is disabled', (tester) async {
    await openConversation(tester);
    await tester.tap(find.byKey(const Key('listen-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('listen-button')), findsNothing);
    expect(find.byKey(const Key('stop-button')), findsOneWidget);
    final speak = tester.widget<ButtonStyleButton>(
      find.descendant(of: find.byKey(const Key('speak-button')), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton)),
    );
    expect(speak.onPressed, isNull);

    await tester.tap(find.byKey(const Key('stop-button')));
    await tester.pumpAndSettle();
    expect(recognizer.stops, 1);
  });

  testWidgets('the Stop button stays readable (white on red) in dark mode', (tester) async {
    await openConversation(tester, prefs: {..._prefs, 'theme_mode': 'dark'});
    await tester.tap(find.byKey(const Key('listen-button')));
    await tester.pumpAndSettle();
    final stop = tester.widget<ButtonStyleButton>(
      find.descendant(of: find.byKey(const Key('stop-button')), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton)),
    );
    expect(stop.style!.foregroundColor!.resolve({}), Colors.white);
  });

  testWidgets('automatic language asks which language they will speak', (tester) async {
    await openConversation(tester, prefs: {..._prefs, 'other_language': 'auto'});
    await tester.tap(find.byKey(const Key('listen-button')));
    await tester.pumpAndSettle();
    expect(find.text('Which language will they speak?'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Hindi'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Gujarati'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'English'), findsNothing);
    expect(recognizer.started, isEmpty);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Gujarati'));
    await tester.pumpAndSettle();
    expect(find.text('They speak Gujarati'), findsOneWidget);
    await tester.tap(find.byKey(const Key('listen-button')));
    await tester.pumpAndSettle();
    expect(recognizer.started, ['gu-IN']);
  });

  testWidgets('denied microphone offers Allow', (tester) async {
    mic
      ..current = MicPermission.denied
      ..onRequest = MicPermission.denied;
    await openConversation(tester);
    await tester.tap(find.byKey(const Key('listen-button')));
    await tester.pumpAndSettle();
    expect(find.text('Anuvaad needs the microphone to hear speech.'), findsOneWidget);
    mic.onRequest = MicPermission.granted;
    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();
    expect(find.text('Anuvaad needs the microphone to hear speech.'), findsNothing);
  });

  testWidgets('permanently denied microphone shows Open settings and does not request again', (tester) async {
    mic.current = MicPermission.permanentlyDenied;
    await openConversation(tester);
    await tester.tap(find.byKey(const Key('listen-button')));
    await tester.pumpAndSettle();
    expect(find.text('Microphone access is off. Turn it on in Settings to use conversations.'), findsOneWidget);
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    expect(mic.settingsOpened, 1);
    expect(mic.requests, 0);
  });

  testWidgets('offline not ready shows the Wi-Fi message and Try again', (tester) async {
    cloud.error = Exception('no network');
    offline.error = const OfflineModelMissing(['hi-IN']);
    await openConversation(tester);
    await tester.tap(find.byKey(const Key('listen-button')));
    await tester.pumpAndSettle();
    await say(tester, const FinalResult('नमस्ते'));
    expect(
      find.text("You're offline, and offline translation isn't downloaded yet. Connect to Wi-Fi once to download it."),
      findsOneWidget,
    );

    offline.error = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Where are you going?'), findsOneWidget);
    expect(find.text('Offline translation'), findsOneWidget);
  });

  testWidgets('recognizer notices name the language and can be dismissed', (tester) async {
    await openConversation(tester, prefs: {..._prefs, 'other_language': 'gu-IN'});
    await tester.tap(find.byKey(const Key('listen-button')));
    await tester.pumpAndSettle();
    await say(tester, const RecognitionError(RecognitionErrorCode.languageUnavailable));
    expect(
      find.text("Gujarati speech recognition isn't available on this phone yet. Update the Google app, "
          'or add Gujarati in its voice settings.'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.textContaining('speech recognition isn'), findsNothing);
  });

  testWidgets('renders Devanagari and Gujarati at text scale 2.0 without overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    cloud.reply = (_) => 'તમે આજે ક્યાં જઈ રહ્યા છો? હું ઓફિસ જઈ રહ્યો છું, સાંજે છ વાગ્યા સુધીમાં પાછો આવીશ.';
    await openConversation(tester, prefs: {..._prefs, 'my_language': 'gu-IN'});
    await tester.tap(find.byKey(const Key('listen-button')));
    await tester.pumpAndSettle();
    await say(tester, const FinalResult('आप आज कहाँ जा रहे हैं? मैं ऑफिस जा रहा हूँ, शाम छह बजे तक वापस आ जाऊँगा।'));
    expect(tester.takeException(), isNull);
    expect(find.text('OTHER PERSON · HINDI'), findsOneWidget);
  });
}
