import 'package:anuvaad/core/config/app_config.dart';
import 'package:anuvaad/core/network/dio_provider.dart';
import 'package:anuvaad/features/conversation/data/android_speech_recognizer.dart';
import 'package:anuvaad/features/conversation/data/offline_models.dart';
import 'package:anuvaad/features/conversation/domain/voice.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/conversation_fakes.dart';

const _myField = Key('my-language-field');
const _otherField = Key('other-language-field');

Future<SharedPreferences> _openLanguages(WidgetTester tester, {Map<String, Object> prefs = const {}}) async {
  final shared = await pumpAnuvaadApp(tester, prefs: {'onboarding_complete': true, ...prefs});
  await tester.tap(find.text('Languages'));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('languages-screen')), findsOneWidget);
  return shared;
}

DropdownButton<String> _dropdown(WidgetTester tester, Key field) => tester.widget<DropdownButton<String>>(
      find.descendant(of: find.byKey(field), matching: find.byType(DropdownButton<String>)),
    );

Future<void> _choose(WidgetTester tester, Key field, String label) async {
  await tester.tap(find.byKey(field));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('my language offers the three core languages; other adds Automatic detection', (tester) async {
    await _openLanguages(tester);
    expect(_dropdown(tester, _myField).items!.map((i) => i.value), ['en-IN', 'hi-IN', 'gu-IN']);
    expect(_dropdown(tester, _otherField).items!.map((i) => i.value), ['auto', 'en-IN', 'hi-IN', 'gu-IN']);
    expect(find.text('Automatic detection'), findsOneWidget);
  });

  testWidgets('swap exchanges languages and is disabled for Automatic detection', (tester) async {
    await _openLanguages(tester, prefs: {'my_language': 'gu-IN', 'other_language': 'hi-IN'});
    await tester.tap(find.byTooltip('Swap languages'));
    await tester.pumpAndSettle();
    expect(_dropdown(tester, _myField).value, 'hi-IN');
    expect(_dropdown(tester, _otherField).value, 'gu-IN');

    await _choose(tester, _otherField, 'Automatic detection');
    final swap = tester.widget<IconButton>(find.ancestor(of: find.byTooltip('Swap languages'), matching: find.byType(IconButton)));
    expect(swap.onPressed, isNull);
  });

  testWidgets('same language on both sides shows validation and disables Save', (tester) async {
    await _openLanguages(tester, prefs: {'my_language': 'gu-IN'});
    await _choose(tester, _otherField, 'ગુજરાતી · Gujarati');
    expect(find.text('Choose two different languages.'), findsOneWidget);
    await _scrollTo(tester, find.text('Save language preferences'));
    final save = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save language preferences'));
    expect(save.onPressed, isNull);
  });

  testWidgets('Save persists both values', (tester) async {
    final prefs = await _openLanguages(tester, prefs: {'my_language': 'gu-IN'});
    await _choose(tester, _myField, 'हिन्दी · Hindi');
    await _scrollTo(tester, find.text('Save language preferences'));
    await tester.tap(find.text('Save language preferences'));
    await tester.pumpAndSettle();
    expect(prefs.getString('my_language'), 'hi-IN');
    expect(prefs.getString('other_language'), 'auto');
    expect(find.text('Language preferences saved'), findsOneWidget);
  });

  testWidgets('Soon on a planned language shows the future-release message', (tester) async {
    await _openLanguages(tester);
    await _scrollTo(tester, find.text('Marathi'));
    await tester.tap(find.descendant(
      of: find.ancestor(of: find.text('Marathi'), matching: find.byType(Card)),
      matching: find.text('Soon'),
    ));
    await tester.pump();
    expect(find.text('Marathi language pack is planned for a future release.'), findsOneWidget);
  });

  group('language status', () {
    late _OffWifiStore store;
    late FakeSpeechSynth synth;

    setUp(() {
      store = _OffWifiStore();
      synth = FakeSpeechSynth()..availabilityByLocale['gu-IN'] = VoiceAvailability.needsDownload;
    });

    Future<void> open(WidgetTester tester, {AppConfig? config, List<Override> overrides = const []}) async {
      await pumpAnuvaadApp(
        tester,
        prefs: {'onboarding_complete': true},
        offlineModels: OfflineModels(store),
        synth: synth,
        config: config ?? const AppConfig(apiBaseUrl: null, releasesRepo: null),
        overrides: [speechRecognizerProvider.overrideWithValue(FakeSpeechRecognizer()), ...overrides],
      );
      await tester.tap(find.text('Languages'));
      await tester.pumpAndSettle();
    }

    Finder inCard(String row, Finder finder) => find.descendant(of: find.widgetWithText(Card, row), matching: finder);

    testWidgets('status reflects model, voice and recognizer', (tester) async {
      await open(tester);
      await scrollIntoView(tester, find.text('Voice · Installed').first);
      expect(inCard('English · English', find.text('Offline translation · Downloaded')), findsOneWidget);
      expect(inCard('English · English', find.text('Speech input · Ready')), findsOneWidget);
      expect(inCard('English · English', find.text('Voice · Installed')), findsOneWidget);
      await scrollIntoView(tester, find.text('Offline translation · Not downloaded').first);
      expect(inCard('Hindi · हिन्दी', find.text('Offline translation · Not downloaded')), findsOneWidget);
      await scrollIntoView(tester, find.text('Voice · Needs download'));
      expect(inCard('Gujarati · ગુજરાતી', find.text('Voice · Needs download')), findsOneWidget);
      expect(inCard('Gujarati · ગુજરાતી', find.text('CORE')), findsOneWidget);
    });

    testWidgets('Download fetches the model and refreshes the row', (tester) async {
      await open(tester);
      await _scrollTo(tester, find.byKey(const Key('download-model-hi-IN')));
      await tester.ensureVisible(find.byKey(const Key('download-model-hi-IN')));
      await tester.tap(find.byKey(const Key('download-model-hi-IN')));
      await tester.pumpAndSettle();
      expect(find.text('Download offline translation?'), findsOneWidget);
      await tester.tap(find.text('Use mobile data too'));
      await tester.pumpAndSettle();
      expect(store.downloads, [(code: 'hi', wifiOnly: false)]);
      expect(inCard('Hindi · हिन्दी', find.text('Offline translation · Downloaded')), findsOneWidget);
    });

    testWidgets('Install voice opens the installer', (tester) async {
      await open(tester);
      await _scrollTo(tester, find.byKey(const Key('install-voice-gu-IN')));
      await tester.ensureVisible(find.byKey(const Key('install-voice-gu-IN')));
      await tester.tap(find.byKey(const Key('install-voice-gu-IN')));
      await tester.pumpAndSettle();
      expect(synth.installsOpened, 1);
    });

    testWidgets('future languages come from the backend catalogue', (tester) async {
      final dio = Dio();
      DioAdapter(dio: dio).onGet(
        'https://anuvaad.example/api/v1/languages',
        (server) => server.reply(200, {
          'languages': [
            {'code': 'ml-IN', 'name': 'Malayalam', 'nativeName': 'മലയാളം', 'installation': 'not_released', 'input': false, 'output': false},
          ],
        }),
      );
      await open(
        tester,
        config: AppConfig.parse(apiBaseUrl: 'https://anuvaad.example', releasesRepo: ''),
        overrides: [dioProvider.overrideWithValue(dio)],
      );
      await _scrollTo(tester, find.text('Malayalam'));
      expect(find.text('Malayalam'), findsOneWidget);
      expect(find.text('Marathi'), findsNothing);
    });

    testWidgets('or the bundled list when the backend fails', (tester) async {
      final dio = Dio();
      DioAdapter(dio: dio).onGet('https://anuvaad.example/api/v1/languages', (server) => server.reply(500, {'error': 'down'}));
      await open(
        tester,
        config: AppConfig.parse(apiBaseUrl: 'https://anuvaad.example', releasesRepo: ''),
        overrides: [dioProvider.overrideWithValue(dio)],
      );
      await _scrollTo(tester, find.text('Marathi'));
      expect(find.text('Marathi'), findsOneWidget);
    });
  });
}

/// A phone off Wi-Fi: the background Wi-Fi-only download gets nowhere; a download allowed on mobile data works.
class _OffWifiStore extends FakeOfflineModelStore {
  _OffWifiStore() : super(downloaded: {'en'});

  @override
  Future<bool> download(String bcpCode, {required bool wifiOnly}) async =>
      wifiOnly ? false : super.download(bcpCode, wifiOnly: wifiOnly);
}

