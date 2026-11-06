import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/conversation_fakes.dart';

const _onboarded = <String, Object>{'onboarding_complete': true};

void main() {
  late FakeAudioOutput audio;

  setUp(() => audio = FakeAudioOutput(connected: [fakeSpeaker, fakeBuds]));

  Future<void> openAudioDevices(WidgetTester tester, {Map<String, Object> prefs = _onboarded}) async {
    await pumpAnuvaadApp(tester, prefs: prefs, audio: audio);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Audio devices'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('audio-devices-screen')), findsOneWidget);
  }

  Finder inCard(String title, Finder finder) =>
      find.descendant(of: find.ancestor(of: find.text(title), matching: find.byType(Card)).first, matching: finder);

  testWidgets('Audio devices lists the microphone, both roles and the compatibility note', (tester) async {
    await openAudioDevices(tester);
    expect(find.text('Choose where each voice plays. Only devices connected right now are shown.'), findsOneWidget);
    expect(find.text('Microphone input'), findsOneWidget);
    expect(find.text("Capture the other person's speech"), findsOneWidget);
    expect(find.text('Phone microphone'), findsOneWidget);
    expect(find.text('Translated voice · You'), findsOneWidget);
    expect(find.text('Hear translation privately'), findsOneWidget);
    expect(find.text('Your reply · Other person'), findsOneWidget);
    expect(find.text('Play translated speech aloud'), findsOneWidget);
    await tester.scrollUntilVisible(find.textContaining('Bluetooth microphone and playback routing'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(
      find.text('Bluetooth microphone and playback routing vary by headset and Android version. '
          'Anuvaad shows the route Android actually uses.'),
      findsOneWidget,
    );
  });

  testWidgets('choosing Phone speaker for me persists and updates the Now line', (tester) async {
    final prefs = await openAudioDevicesAndReturnPrefs(tester, audio);
    expect(inCard('Translated voice · You', find.text('Now: Galaxy Buds')), findsOneWidget);
    expect(inCard('Your reply · Other person', find.text('Now: Phone speaker')), findsOneWidget);

    await tester.tap(inCard('Translated voice · You', find.text('Phone speaker')));
    await tester.pumpAndSettle();
    expect(inCard('Translated voice · You', find.text('Now: Phone speaker')), findsOneWidget);
    expect(prefs.getString('output_for_me'), 'speaker');
  });

  testWidgets('Test output sound plays a tone on the resolved device', (tester) async {
    await openAudioDevices(tester);
    await tester.tap(find.byKey(const Key('test-sound-forMe')));
    await tester.pumpAndSettle();
    expect(audio.calls, contains('tone:${fakeBuds.id}'));
    expect(find.text('Played on Galaxy Buds'), findsOneWidget);
  });

  testWidgets('no earphones connected shows the speaker line', (tester) async {
    audio.connected = [fakeSpeaker];
    await openAudioDevices(tester);
    expect(
      inCard('Translated voice · You', find.text('No earphones connected, so this plays on the phone speaker.')),
      findsOneWidget,
    );
  });
}

/// Opens the screen and returns the in-memory preferences, to check what was saved.
Future<SharedPreferences> openAudioDevicesAndReturnPrefs(WidgetTester tester, FakeAudioOutput audio) async {
  final prefs = await pumpAnuvaadApp(tester, prefs: _onboarded, audio: audio);
  await tester.tap(find.text('Settings'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Audio devices'));
  await tester.pumpAndSettle();
  return prefs;
}
