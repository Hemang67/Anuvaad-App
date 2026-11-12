import 'dart:async';
import 'dart:io';

import 'package:anuvaad/core/permissions/microphone_permission.dart';
import 'package:anuvaad/features/conversation/application/translation_service.dart';
import 'package:anuvaad/features/conversation/data/android_speech_recognizer.dart';
import 'package:anuvaad/features/conversation/data/mlkit_translator.dart';
import 'package:anuvaad/features/conversation/domain/audio_output.dart';
import 'package:anuvaad/features/conversation/domain/speech_recognition.dart';
import 'package:anuvaad/features/conversation/domain/translation.dart';
import 'package:anuvaad/features/conversation/domain/voice.dart';
import 'package:anuvaad/features/history/data/file_history_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/conversation_fakes.dart';

const _prefs = <String, Object>{'onboarding_complete': true, 'my_language': 'en-IN', 'other_language': 'hi-IN'};

void main() {
  late FakeSpeechRecognizer recognizer;
  late FakeTranslator cloud;
  late FakeTranslator offline;
  late FakeMicrophonePermission mic;
  late FakeAudioOutput audio;
  late FakeSpeechSynth synth;
  late FakeScreenAwake awake;

  setUp(() {
    recognizer = FakeSpeechRecognizer();
    cloud = FakeTranslator(reply: (_) => 'Where are you going today?');
    offline = FakeTranslator(provenance: TranslationProvenance.offline, provider: 'mlkit', reply: (_) => 'Where are you going?');
    mic = FakeMicrophonePermission();
    audio = FakeAudioOutput();
    synth = FakeSpeechSynth();
    awake = FakeScreenAwake();
  });

  Future<void> openConversation(WidgetTester tester, {Map<String, Object> prefs = _prefs}) async {
    await pumpAnuvaadApp(tester, prefs: prefs, audio: audio, synth: synth, screenAwake: awake, overrides: [
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

  /// The segment id of the last playback the app asked for.
  String lastPlayedId() => audio.calls.lastWhere((c) => c.startsWith('play:')).split(':')[1];

  /// The first call turns Listen mode on; after that, finishing the last playback lets Listen mode start the
  /// next turn by itself.
  Future<void> nextListenTurn(WidgetTester tester) async {
    if (find.byKey(const Key('listen-button')).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const Key('listen-button')));
    } else {
      final id = lastPlayedId();
      audio.emit(PlaybackStarted(id, fakeSpeaker));
      audio.emit(PlaybackCompleted(id));
    }
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
      find.text('Tap Listen and Anuvaad keeps listening, translating and speaking each turn. Tap Speak to reply.'),
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
      await nextListenTurn(tester);
      await say(tester, FinalResult('वाक्य नंबर $i, थोड़ा लंबा ताकि कार्ड बड़ा हो।'));
      cloud.holdAll!.complete();
      await tester.pumpAndSettle();
      final translation = find.textContaining('Translation of "वाक्य नंबर $i');
      final viewport = tester.getRect(find.byType(ListView));
      expect(tester.getRect(translation).bottom, lessThanOrEqualTo(viewport.bottom + 0.5), reason: 'turn $i');
      expect(viewport.bottom, lessThanOrEqualTo(list.bottom));
    }
  });

  Future<String> listenAndTranslate(WidgetTester tester, String text) async {
    await tester.tap(find.byKey(const Key('listen-button')));
    await tester.pumpAndSettle();
    await say(tester, FinalResult(text));
    return lastPlayedId();
  }

  testWidgets('a spoken translation shows Playing…, then Output and Replay', (tester) async {
    await openConversation(tester);
    final id = await listenAndTranslate(tester, 'आप आज कहाँ जा रहे हैं?');
    audio.emit(PlaybackStarted(id, fakeSpeaker));
    await tester.pumpAndSettle();
    expect(find.text('Playing…'), findsOneWidget);
    expect(find.text('Replay translation'), findsNothing);

    audio.emit(PlaybackCompleted(id));
    await tester.pumpAndSettle();
    expect(find.text('Playing…'), findsNothing);
    expect(find.text('Output: Phone speaker'), findsOneWidget);
    expect(find.byKey(Key('replay-$id')), findsOneWidget);
  });

  testWidgets('Replay plays the segment again', (tester) async {
    await openConversation(tester);
    final id = await listenAndTranslate(tester, 'नमस्ते');
    audio.emit(PlaybackStarted(id, fakeSpeaker));
    audio.emit(PlaybackCompleted(id));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('replay-$id')));
    await tester.pumpAndSettle();
    expect(audio.calls.where((c) => c.startsWith('play:$id:')), hasLength(2));
  });

  testWidgets('no-voice card offers Install voice', (tester) async {
    synth.availabilityByLocale['en-IN'] = VoiceAvailability.needsDownload;
    await openConversation(tester);
    await tester.tap(find.byKey(const Key('listen-button')));
    await tester.pumpAndSettle();
    await say(tester, const FinalResult('नमस्ते'));
    expect(find.text('No English voice on this phone, so this translation is text only.'), findsOneWidget);
    await tester.tap(find.text('Install voice'));
    await tester.pumpAndSettle();
    expect(synth.installsOpened, 1);
  });

  testWidgets('after installing a voice, Replay on the no-voice card speaks it', (tester) async {
    synth.availabilityByLocale['en-IN'] = VoiceAvailability.needsDownload;
    await openConversation(tester);
    await tester.tap(find.byKey(const Key('listen-button')));
    await tester.pumpAndSettle();
    await say(tester, const FinalResult('नमस्ते'));
    await tester.tap(find.text('Install voice'));
    await tester.pumpAndSettle();
    synth.availabilityByLocale['en-IN'] = VoiceAvailability.available;
    await tester.tap(find.text('Replay translation'));
    await tester.pumpAndSettle();
    expect(audio.calls.where((c) => c.startsWith('play:')), hasLength(1));
  });

  testWidgets('Replay on an older card keeps the list where it is', (tester) async {
    cloud.reply = (r) => 'Translation of "${r.text}": a long answer that wraps over several lines on a phone screen, '
        'so that the card grows when it arrives and the list must scroll to keep it visible.';
    await openConversation(tester);
    for (var i = 1; i <= 6; i++) {
      await nextListenTurn(tester);
      await say(tester, FinalResult('वाक्य नंबर $i, थोड़ा लंबा ताकि कार्ड बड़ा हो।'));
    }
    final first = audio.calls.firstWhere((c) => c.startsWith('play:')).split(':')[1];
    await tester.drag(find.byType(ListView), const Offset(0, 5000));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(Key('replay-$first')));
    await tester.pumpAndSettle();
    final card = find.byKey(ValueKey('segment-$first'));
    final before = tester.getRect(card).top;

    await tester.tap(find.byKey(Key('replay-$first')));
    await tester.pumpAndSettle();
    audio.emit(PlaybackStarted(first, fakeSpeaker));
    await tester.pumpAndSettle();
    expect(tester.getRect(card).top, closeTo(before, 1));
  });

  testWidgets('earphones disconnected notice appears', (tester) async {
    audio.connected = [fakeSpeaker, fakeBuds];
    await openConversation(tester);
    final id = await listenAndTranslate(tester, 'नमस्ते');
    audio.emit(PlaybackStarted(id, fakeBuds));
    audio.emit(PlaybackCompleted(id));
    await tester.pumpAndSettle();
    expect(find.text('Output: Galaxy Buds'), findsOneWidget);
    audio.setOutputs([fakeSpeaker]);
    await tester.pumpAndSettle();
    expect(find.text('Earphones disconnected. Translations now play on the phone speaker.'), findsOneWidget);
  });

  testWidgets('the app bar opens Audio devices, and Back returns to the conversation', (tester) async {
    await openConversation(tester);
    await tester.tap(find.byTooltip('Audio devices'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('audio-devices-screen')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('conversation-screen')), findsOneWidget);
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

  testWidgets('Listen becomes Pause while listening, and Pause stops it', (tester) async {
    await openConversation(tester);
    await tester.tap(find.byKey(const Key('listen-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('listen-button')), findsNothing);
    expect(find.byKey(const Key('pause-button')), findsOneWidget);
    final speak = tester.widget<ButtonStyleButton>(
      find.descendant(of: find.byKey(const Key('speak-button')), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton)),
    );
    expect(speak.onPressed, isNotNull, reason: 'Speak interrupts a waiting Listen turn');

    await tester.tap(find.byKey(const Key('pause-button')));
    await tester.pumpAndSettle();
    expect(recognizer.cancels, 1);
    expect(find.byKey(const Key('listen-button')), findsOneWidget);
    expect(find.text('PAUSED'), findsOneWidget);
  });

  testWidgets('Speak becomes Stop during my turn, and Stop finishes it', (tester) async {
    await openConversation(tester);
    await tester.tap(find.byKey(const Key('speak-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stop-button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('stop-button')));
    await tester.pumpAndSettle();
    expect(recognizer.stops, 1);
  });

  testWidgets('the Stop button stays readable (white on red) in dark mode', (tester) async {
    await openConversation(tester, prefs: {..._prefs, 'theme_mode': 'dark'});
    await tester.tap(find.byKey(const Key('speak-button')));
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
    expect(recognizer.started, ['gu-IN'], reason: 'Listen mode starts as soon as the language is known');
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

  testWidgets('status chip follows the session', (tester) async {
    await openConversation(tester);
    expect(find.text('READY TO LISTEN'), findsOneWidget);
    await tester.tap(find.byKey(const Key('listen-button')));
    await tester.pumpAndSettle();
    expect(find.text('LISTENING'), findsOneWidget);
    await say(tester, const FinalResult('नमस्ते'));
    expect(find.text('TRANSLATING…'), findsOneWidget);
    audio.emit(PlaybackStarted(lastPlayedId(), fakeSpeaker));
    await tester.pumpAndSettle();
    expect(find.text('SPEAKING'), findsOneWidget);
    final chip = tester.widget<Semantics>(
      find.ancestor(of: find.text('SPEAKING'), matching: find.byWidgetPredicate((w) => w is Semantics && w.properties.liveRegion == true)),
    );
    expect(chip.properties.liveRegion, isTrue);
  });

  testWidgets('the screen stays awake only while the session is active', (tester) async {
    await openConversation(tester);
    expect(awake.on, isFalse);
    await tester.tap(find.byKey(const Key('listen-button')));
    await tester.pumpAndSettle();
    expect(awake.on, isTrue);
    await tester.tap(find.byKey(const Key('pause-button')));
    await tester.pumpAndSettle();
    expect(awake.on, isFalse);
  });

  testWidgets('End shows the summary with duration and turns; Done leaves the screen', (tester) async {
    await openConversation(tester);
    expect(find.byKey(const Key('end-button')), findsNothing, reason: 'nothing to end yet');
    await tester.tap(find.byKey(const Key('listen-button')));
    await tester.pumpAndSettle();
    await say(tester, const FinalResult('नमस्ते'));
    await tester.tap(find.byKey(const Key('end-button')));
    await tester.pumpAndSettle();
    expect(find.text('Conversation ended'), findsOneWidget);
    expect(find.text('English ↔ Hindi'), findsOneWidget);
    expect(find.text('1 turn'), findsOneWidget);
    expect(audio.calls.last, 'stop');
    expect(awake.on, isFalse);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-screen')), findsOneWidget);
  });

  testWidgets('Copy transcript puts the transcript on the clipboard', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String?;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await openConversation(tester);
    await tester.tap(find.byKey(const Key('listen-button')));
    await tester.pumpAndSettle();
    await say(tester, const FinalResult('नमस्ते'));
    await tester.tap(find.byKey(const Key('end-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy transcript'));
    await tester.pumpAndSettle();
    expect(copied, contains('Other person (Hindi): नमस्ते'));
    expect(copied, contains('→ English: Where are you going today?'));
    expect(find.text('Transcript copied'), findsOneWidget);
  });

  testWidgets('an unclear card offers language chips', (tester) async {
    recognizer.detectionSupported = true;
    await openConversation(tester, prefs: {..._prefs, 'other_language': 'auto'});
    await tester.tap(find.byKey(const Key('listen-button')));
    await tester.pumpAndSettle();
    await say(tester, const FinalResult('नमस्ते'));
    expect(find.text('Language unclear. What did they speak?'), findsOneWidget);
    expect(find.text('CHOOSE THE LANGUAGE'), findsOneWidget);
    await tester.tap(find.byKey(const Key('unclear-hi-IN')));
    await tester.pumpAndSettle();
    expect(find.text('Where are you going today?'), findsOneWidget);
    expect(find.text('Language unclear. What did they speak?'), findsNothing);
  });

  testWidgets('a detected language is labelled on the card and in the header', (tester) async {
    recognizer.detectionSupported = true;
    await openConversation(tester, prefs: {..._prefs, 'other_language': 'auto'});
    await tester.tap(find.byKey(const Key('listen-button')));
    await tester.pumpAndSettle();
    recognizer.emit(const LanguageDetected('gu-IN', LanguageConfidence.confident));
    await say(tester, const FinalResult('તમે ક્યાં જાઓ છો?'));
    expect(find.text('OTHER PERSON · GUJARATI · DETECTED'), findsOneWidget);
    expect(find.text('Their language: Gujarati · Detected'), findsOneWidget);
  });

  testWidgets('Change in the header picks their language', (tester) async {
    await openConversation(tester);
    expect(find.text('Their language: Hindi'), findsOneWidget);
    await tester.tap(find.byKey(const Key('change-language')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Gujarati').last);
    await tester.pumpAndSettle();
    expect(find.text('Their language: Gujarati'), findsOneWidget);
    await tester.tap(find.byKey(const Key('listen-button')));
    await tester.pumpAndSettle();
    expect(recognizer.started, ['gu-IN']);
  });

  testWidgets('a reply under review offers Edit, Play and Discard', (tester) async {
    await openConversation(tester, prefs: {..._prefs, 'review_reply': true});
    await tester.tap(find.byKey(const Key('speak-button')));
    await tester.pumpAndSettle();
    await say(tester, const FinalResult('Hello'));
    expect(find.text('REVIEW YOUR REPLY'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Discard'), findsOneWidget);
    expect(audio.calls.where((c) => c.startsWith('play:')), isEmpty);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Hello there');
    await tester.tap(find.text('Translate again'));
    await tester.pumpAndSettle();
    expect(cloud.requests.last.text, 'Hello there');
    expect(find.text('Hello there'), findsOneWidget);

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    expect(audio.calls.where((c) => c.startsWith('play:')), hasLength(1));
  });

  testWidgets('summary Save saves this conversation', (tester) async {
    final root = Directory.systemTemp.createTempSync('anuvaad_summary_save');
    addTearDown(() => root.deleteSync(recursive: true));
    final repo = FileHistoryRepository(() async => root);
    await pumpAnuvaadApp(tester, prefs: _prefs, audio: audio, synth: synth, screenAwake: awake, history: repo, overrides: [
      speechRecognizerProvider.overrideWithValue(recognizer),
      microphonePermissionProvider.overrideWithValue(mic),
      translationServiceProvider.overrideWithValue(TranslationService(cloud: cloud, offline: offline)),
    ]);
    await tester.scrollUntilVisible(find.text('In-person conversation'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('In-person conversation'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('listen-button')));
    await tester.pumpAndSettle();
    await say(tester, const FinalResult('नमस्ते'));
    await tester.tap(find.byKey(const Key('end-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save to history'));
    await tester.pumpAndSettle();
    expect(find.text('Saved to history'), findsOneWidget);
    expect((await repo.list()).single.segments.single.text, 'नमस्ते');
  });
}
