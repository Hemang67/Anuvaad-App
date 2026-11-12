import 'package:anuvaad/features/conversation/domain/voice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/conversation_fakes.dart';

void main() {
  late FakeSpeechSynth synth;
  late FakeAudioOutput audio;

  setUp(() {
    synth = FakeSpeechSynth()
      ..voicesByLocale['hi-IN'] = const [
        VoiceOption(name: 'hi-in-x-hia-local', network: false, installed: true),
        VoiceOption(name: 'hi-in-x-hie-network', network: true, installed: true),
      ];
    audio = FakeAudioOutput();
  });

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  Future<SharedPreferences> openVoices(WidgetTester tester) async {
    final prefs = await pumpAnuvaadApp(tester, prefs: {'onboarding_complete': true}, synth: synth, audio: audio);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Voices'));
    await tester.tap(find.text('Voices'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('voices-screen')), findsOneWidget);
    return prefs;
  }

  testWidgets('the voices screen lists voices per language and saves a choice', (tester) async {
    final prefs = await openVoices(tester);
    await scrollTo(tester, find.text('Voice 2 · needs internet'));
    expect(find.text('Voice 1 · on this phone'), findsOneWidget);
    await tester.tap(find.text('Voice 2 · needs internet'));
    await tester.pumpAndSettle();
    expect(prefs.getString('voice_hi-IN'), 'hi-in-x-hie-network');

    await tester.tap(find.byKey(const Key('voice-default-hi-IN')));
    await tester.pumpAndSettle();
    expect(prefs.getString('voice_hi-IN'), isNull);
  });

  testWidgets('Test plays the sample', (tester) async {
    await openVoices(tester);
    await scrollTo(tester, find.byKey(const Key('test-voice-hi-IN')));
    await tester.tap(find.byKey(const Key('test-voice-hi-IN')));
    await tester.pumpAndSettle();
    expect(synth.synthesizedTexts, ['नमस्ते, आप कैसे हैं?']);
    expect(audio.calls.where((c) => c.startsWith('play:')), hasLength(1));
  });

  testWidgets('a language with no voice says so', (tester) async {
    synth.availabilityByLocale['gu-IN'] = VoiceAvailability.needsDownload;
    await openVoices(tester);
    await scrollTo(tester, find.byKey(const Key('test-voice-gu-IN')));
    await tester.tap(find.byKey(const Key('test-voice-gu-IN')));
    await tester.pumpAndSettle();
    expect(find.text('No Gujarati voice on this phone yet. Install one from Languages.'), findsOneWidget);
  });

  testWidgets('speech speed saved from Settings', (tester) async {
    final prefs = await pumpAnuvaadApp(tester, prefs: {'onboarding_complete': true});
    await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const Key('speech-rate')));
    await tester.tap(find.text('Fast'));
    await tester.pumpAndSettle();
    expect(prefs.getString('speech_rate'), 'fast');
  });
}
