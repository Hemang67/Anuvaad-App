import 'package:anuvaad/core/permissions/microphone_permission.dart';
import 'package:anuvaad/features/conversation/application/translation_service.dart';
import 'package:anuvaad/features/conversation/data/android_speech_recognizer.dart';
import 'package:anuvaad/features/conversation/domain/speech_recognition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/conversation_fakes.dart';

void main() {
  late FakeSpeechRecognizer recognizer;

  setUp(() => recognizer = FakeSpeechRecognizer());

  Future<void> openSetup(WidgetTester tester) async {
    await pumpAnuvaadApp(
      tester,
      prefs: {'onboarding_complete': true, 'my_language': 'en-IN', 'other_language': 'hi-IN'},
      overrides: [
        speechRecognizerProvider.overrideWithValue(recognizer),
        microphonePermissionProvider.overrideWithValue(FakeMicrophonePermission()),
        translationServiceProvider.overrideWithValue(TranslationService(cloud: FakeTranslator(), offline: FakeTranslator())),
      ],
    );
    await scrollIntoView(tester, find.text('Online meeting'));
    await tester.tap(find.text('Online meeting'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('meeting-setup-screen')), findsOneWidget);
  }

  ButtonStyleButton start(WidgetTester tester) => tester.widget<ButtonStyleButton>(
        find.descendant(of: find.byKey(const Key('meeting-start')), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton)),
      );

  testWidgets("Home's Online meeting card opens the setup, which explains Android's limits", (tester) async {
    await openSetup(tester);
    expect(find.textContaining("Android doesn't let apps capture audio from Zoom, Meet, Teams or WhatsApp"), findsOneWidget);
  });

  testWidgets('Start needs the consent box', (tester) async {
    await openSetup(tester);
    await scrollIntoView(tester, find.byKey(const Key('meeting-start')));
    expect(start(tester).onPressed, isNull);
    await tester.tap(find.byKey(const Key('meeting-consent')));
    await tester.pumpAndSettle();
    expect(start(tester).onPressed, isNotNull);
  });

  testWidgets('Test microphone shows what was heard', (tester) async {
    await openSetup(tester);
    await scrollIntoView(tester, find.byKey(const Key('test-mic')));
    await tester.tap(find.byKey(const Key('test-mic')));
    await tester.pump();
    expect(recognizer.started, ['hi-IN']);
    expect(find.text('Listening for a few seconds…'), findsOneWidget);
    recognizer.emit(const FinalResult('नमस्ते सब लोग'));
    await tester.pumpAndSettle();
    expect(find.text('We heard: नमस्ते सब लोग'), findsOneWidget);
  });

  testWidgets('Test microphone with silence explains what to try', (tester) async {
    await openSetup(tester);
    await scrollIntoView(tester, find.byKey(const Key('test-mic')));
    await tester.tap(find.byKey(const Key('test-mic')));
    await tester.pump();
    recognizer.emit(const RecognitionError(RecognitionErrorCode.noMatch));
    await tester.pumpAndSettle();
    expect(find.text("We didn't hear anything. Move closer or turn the meeting volume up."), findsOneWidget);
  });

  testWidgets('a meeting session listens continuously with no Speak button', (tester) async {
    await openSetup(tester);
    await scrollIntoView(tester, find.byKey(const Key('meeting-consent')));
    await tester.tap(find.byKey(const Key('meeting-consent')));
    await tester.pumpAndSettle();
    await scrollIntoView(tester, find.byKey(const Key('meeting-start')));
    await tester.tap(find.byKey(const Key('meeting-start')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('conversation-screen')), findsOneWidget);
    expect(find.byKey(const Key('speak-button')), findsNothing);
    expect(find.byKey(const Key('pause-button')), findsOneWidget);
    expect(find.text('Meeting'), findsOneWidget);
    expect(recognizer.started, ['hi-IN']);
  });

  testWidgets('Start during the microphone test stops the test, so it cannot cancel the meeting (I2)', (tester) async {
    await openSetup(tester);
    await scrollIntoView(tester, find.byKey(const Key('test-mic')));
    await tester.tap(find.byKey(const Key('test-mic')));
    await tester.pump();
    await scrollIntoView(tester, find.byKey(const Key('meeting-consent')));
    await tester.tap(find.byKey(const Key('meeting-consent')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('meeting-start')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(recognizer.started, ['hi-IN', 'hi-IN']);
    final cancelsBefore = recognizer.cancels;
    await tester.pump(const Duration(seconds: 7));
    expect(recognizer.cancels, cancelsBefore, reason: "the test's timer must not cancel the meeting's recognizer");
  });

  testWidgets('leaving the setup during the microphone test closes the microphone (I2)', (tester) async {
    await openSetup(tester);
    await scrollIntoView(tester, find.byKey(const Key('test-mic')));
    await tester.tap(find.byKey(const Key('test-mic')));
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(recognizer.cancels, 1);
    await tester.pump(const Duration(seconds: 7));
    expect(recognizer.cancels, 1);
  });
}
