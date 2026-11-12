import 'dart:io';

import 'package:anuvaad/features/conversation/data/android_speech_recognizer.dart';
import 'package:anuvaad/features/history/data/file_history_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/conversation_fakes.dart';
import '../../helpers/history_fixtures.dart';

Future<SharedPreferences> _openSettings(WidgetTester tester, {String version = '0.1.0', String buildNumber = '1'}) async {
  final prefs = await pumpAnuvaadApp(
    tester,
    prefs: {'onboarding_complete': true},
    version: version,
    buildNumber: buildNumber,
  );
  await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('settings-screen')), findsOneWidget);
  return prefs;
}

/// Settings is longer than one screen: bring [finder] into view first.
Future<void> _scrollTo(WidgetTester tester, Finder finder) => scrollIntoView(tester, finder);

void main() {
  testWidgets('theme segment reflects and changes theme mode', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final prefs = await _openSettings(tester);

    final segments = tester.widget<SegmentedButton<ThemeMode>>(find.byType(SegmentedButton<ThemeMode>));
    expect(segments.selected, {ThemeMode.system});
    expect(find.text('Default: System'), findsOneWidget);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(prefs.getString('theme_mode'), 'dark');
    expect(Theme.of(tester.element(find.byKey(const Key('settings-screen')))).brightness, Brightness.dark);
    expect(tester.widget<SegmentedButton<ThemeMode>>(find.byType(SegmentedButton<ThemeMode>)).selected, {ThemeMode.dark});
  });

  testWidgets('shows version and build from PackageInfo', (tester) async {
    await _openSettings(tester, version: '0.2.3', buildNumber: '7');
    await _scrollTo(tester, find.text('v0.2.3 (7)'));
    expect(find.text('v0.2.3 (7)'), findsOneWidget);
  });

  testWidgets('shows About Anuvaad and Powered by REA Intelligence', (tester) async {
    await _openSettings(tester);
    await _scrollTo(tester, find.text('About Anuvaad'));
    expect(find.text('About Anuvaad'), findsOneWidget);
    expect(find.text('Powered by REA Intelligence'), findsOneWidget);
  });

  testWidgets('Settings has an Audio devices row that opens the screen', (tester) async {
    await pumpAnuvaadApp(tester, prefs: {'onboarding_complete': true});
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Where translations play'));
    expect(find.text('Where translations play'), findsOneWidget);
    await scrollIntoView(tester, find.text('Audio devices'));
    await tester.tap(find.text('Audio devices'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('audio-devices-screen')), findsOneWidget);
  });

  testWidgets('Settings has the auto-detect and review-reply switches, saved', (tester) async {
    final prefs = await pumpAnuvaadApp(tester, prefs: {'onboarding_complete': true}, overrides: [
      speechRecognizerProvider.overrideWithValue(FakeSpeechRecognizer()..detectionSupported = true),
    ]);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('review-reply-switch')), 200, scrollable: find.byType(Scrollable).first);
    expect(tester.widget<Switch>(find.byKey(const Key('auto-detect-switch'))).value, isTrue);
    expect(tester.widget<Switch>(find.byKey(const Key('review-reply-switch'))).value, isFalse);
    await tester.tap(find.byKey(const Key('auto-detect-switch')));
    await tester.tap(find.byKey(const Key('review-reply-switch')));
    await tester.pumpAndSettle();
    expect(prefs.getBool('auto_detect'), isFalse);
    expect(prefs.getBool('review_reply'), isTrue);
  });

  group('privacy', () {
    late Directory root;
    late FileHistoryRepository repo;

    setUp(() {
      root = Directory.systemTemp.createTempSync('anuvaad_settings_privacy');
      repo = FileHistoryRepository(() async => root);
    });
    tearDown(() => root.deleteSync(recursive: true));

    Future<SharedPreferences> open(WidgetTester tester, {bool historyOn = false}) async {
      final prefs = await pumpAnuvaadApp(tester, prefs: {'onboarding_complete': true, 'save_history': historyOn}, history: repo);
      await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
      await tester.pumpAndSettle();
      await scrollIntoView(tester, find.byKey(const Key('save-history-switch')));
      return prefs;
    }

    testWidgets('privacy switches default off and persist', (tester) async {
      final prefs = await open(tester);
      expect(tester.widget<Switch>(find.byKey(const Key('save-history-switch'))).value, isFalse);
      expect(find.text('Off by default · stays on this phone'), findsOneWidget);
      await tester.tap(find.byKey(const Key('save-history-switch')));
      await tester.pumpAndSettle();
      expect(prefs.getBool('save_history'), isTrue);
      await scrollIntoView(tester, find.text('Raw audio'));
      expect(find.text('Never saved'), findsOneWidget);
    });

    testWidgets('turning history off asks to keep or delete', (tester) async {
      await repo.save(savedConversation('a', DateTime(2026, 11, 5, 9)));
      final prefs = await open(tester, historyOn: true);
      await tester.tap(find.byKey(const Key('save-history-switch')));
      await tester.pumpAndSettle();
      expect(find.text('Keep saved conversations?'), findsOneWidget);
      await tester.tap(find.text('Keep'));
      await tester.pumpAndSettle();
      expect(prefs.getBool('save_history'), isFalse);
      expect(await repo.list(), hasLength(1));

      await tester.tap(find.byKey(const Key('save-history-switch')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save-history-switch')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete all'));
      await tester.pumpAndSettle();
      expect(prefs.getBool('save_history'), isFalse);
      expect(await repo.list(), isEmpty);
    });

    testWidgets('turning history off with nothing saved asks nothing', (tester) async {
      final prefs = await open(tester, historyOn: true);
      await tester.tap(find.byKey(const Key('save-history-switch')));
      await tester.pumpAndSettle();
      expect(find.text('Keep saved conversations?'), findsNothing);
      expect(prefs.getBool('save_history'), isFalse);
    });

    testWidgets('Delete all conversations empties history after confirming', (tester) async {
      await repo.save(savedConversation('a', DateTime(2026, 11, 5, 9)));
      await repo.save(savedConversation('b', DateTime(2026, 11, 6, 9)));
      await open(tester);
      await scrollIntoView(tester, find.byKey(const Key('delete-all-history')));
      await tester.tap(find.byKey(const Key('delete-all-history')));
      await tester.pumpAndSettle();
      expect(find.text('Delete all saved conversations?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete all'));
      await tester.pumpAndSettle();
      expect(await repo.list(), isEmpty);
      expect(find.text('All saved conversations deleted'), findsOneWidget);
    });

    testWidgets('auto-detect is disabled below Android 14', (tester) async {
      await pumpAnuvaadApp(tester, prefs: {'onboarding_complete': true}, overrides: [
        speechRecognizerProvider.overrideWithValue(FakeSpeechRecognizer()..detectionSupported = false),
      ]);
      await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
      await tester.pumpAndSettle();
      await scrollIntoView(tester, find.byKey(const Key('auto-detect-switch')));
      expect(tester.widget<Switch>(find.byKey(const Key('auto-detect-switch'))).onChanged, isNull);
      expect(find.text("Needs Android 14 or later. You'll choose the language instead."), findsOneWidget);
    });

    testWidgets('privacy screen explains each data flow', (tester) async {
      await open(tester);
      await scrollIntoView(tester, find.text('Privacy & data'));
      await tester.tap(find.text('Privacy & data'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('privacy-screen')), findsOneWidget);
      for (final title in ['What leaves your phone', 'Where it goes', 'What is stored', 'Your controls']) {
        await scrollIntoView(tester, find.text(title));
        expect(find.text(title), findsOneWidget);
      }
      await scrollIntoView(tester, find.textContaining('Raw microphone audio is never saved'));
      expect(find.textContaining('latency report keeps timings only'), findsOneWidget);
      await scrollIntoView(tester, find.text('Contact details will be added before public launch.'));
    });
  });
}
