import 'dart:io';

import 'package:anuvaad/features/history/data/file_history_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/conversation_fakes.dart';
import '../../helpers/history_fixtures.dart';

void main() {
  late Directory root;
  late FileHistoryRepository repo;
  late FakeTranscriptSharer sharer;

  setUp(() {
    root = Directory.systemTemp.createTempSync('anuvaad_history_screen_test');
    repo = FileHistoryRepository(() async => root);
    sharer = FakeTranscriptSharer();
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  Future<void> openHistory(WidgetTester tester, {bool historyOn = true}) async {
    await pumpAnuvaadApp(
      tester,
      prefs: {'onboarding_complete': true, 'save_history': historyOn},
      history: repo,
      sharer: sharer,
    );
    final chip = find.widgetWithText(ActionChip, 'History');
    await tester.scrollUntilVisible(chip, 200, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history-screen')), findsOneWidget);
  }

  Future<void> openDetail(WidgetTester tester, String id) async {
    await openHistory(tester);
    await tester.tap(find.byKey(Key('history-$id')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('conversation-detail-screen')), findsOneWidget);
  }

  group('History', () {
    testWidgets('history lists saved conversations newest first and searches', (tester) async {
      await repo.save(savedConversation('old', DateTime(2026, 11, 5, 9), text: 'Where is the station?', translation: 'स्टेशन कहाँ है?'));
      await repo.save(savedConversation('new', DateTime(2026, 11, 6, 9)));
      await openHistory(tester);
      expect(tester.getRect(find.byKey(const Key('history-new'))).top,
          lessThan(tester.getRect(find.byKey(const Key('history-old'))).top));
      expect(find.text('3 MIN'), findsNWidgets(2));
      expect(find.text('English ↔ Hindi'), findsNWidgets(2));

      await tester.enterText(find.byKey(const Key('history-search')), 'station');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('history-new')), findsNothing);
      expect(find.byKey(const Key('history-old')), findsOneWidget);
    });

    testWidgets('search with no match says so', (tester) async {
      await repo.save(savedConversation('a', DateTime(2026, 11, 6, 9)));
      await openHistory(tester);
      await tester.enterText(find.byKey(const Key('history-search')), 'xyz');
      await tester.pumpAndSettle();
      expect(find.text('No conversations match “xyz”.'), findsOneWidget);
    });

    testWidgets('history off shows the turn-on prompt', (tester) async {
      await openHistory(tester, historyOn: false);
      expect(find.text('Saving conversations is off'), findsOneWidget);
      await tester.tap(find.text('Turn on in Settings'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('settings-screen')), findsOneWidget);
    });

    testWidgets('history on but empty says so', (tester) async {
      await openHistory(tester);
      expect(find.text('No saved conversations yet'), findsOneWidget);
    });
  });

  group('Conversation detail', () {
    testWidgets('detail shows both languages, speaker and time, and marks untranslated lines', (tester) async {
      await repo.save(savedConversation('a', DateTime(2026, 11, 5, 9), unclear: true));
      await openDetail(tester, 'a');
      expect(find.text('English ↔ Hindi'), findsOneWidget);
      expect(find.text('OTHER PERSON · HINDI · 09:00:05'), findsOneWidget);
      expect(find.text('नमस्ते'), findsOneWidget);
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('YOU · ENGLISH · 09:00:20'), findsOneWidget);
      expect(find.text('Not translated'), findsOneWidget);
      expect(find.text('Language unclear'), findsOneWidget);
    });

    testWidgets('Copy and Share send the transcript text', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String?;
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      await repo.save(savedConversation('a', DateTime(2026, 11, 5, 9)));
      await openDetail(tester, 'a');

      await tester.tap(find.byTooltip('Copy'));
      await tester.pumpAndSettle();
      expect(copied, contains('[09:00:05] Other person (Hindi): नमस्ते'));

      await tester.tap(find.byTooltip('Share'));
      await tester.pumpAndSettle();
      expect(sharer.shared.single.fileName, 'anuvaad-2026-11-05-0900.txt');
      expect(sharer.shared.single.text, contains('  → English: Hello'));
    });

    testWidgets('Delete removes the conversation after confirming', (tester) async {
      await repo.save(savedConversation('a', DateTime(2026, 11, 5, 9)));
      await openDetail(tester, 'a');
      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete this conversation?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('history-screen')), findsOneWidget);
      expect(find.byKey(const Key('history-a')), findsNothing);
      expect(await repo.list(), isEmpty);
    });
  });

  group('Home', () {
    testWidgets('Home shows recent conversations only when history is on', (tester) async {
      await repo.save(savedConversation('a', DateTime(2026, 11, 5, 9)));
      await pumpAnuvaadApp(tester, prefs: {'onboarding_complete': true, 'save_history': true}, history: repo);
      await tester.scrollUntilVisible(find.text('Recent conversations'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.byKey(const Key('recent-a')), findsOneWidget);
    });

    testWidgets('Home hides recent conversations when history is off', (tester) async {
      await repo.save(savedConversation('a', DateTime(2026, 11, 5, 9)));
      await pumpAnuvaadApp(tester, prefs: {'onboarding_complete': true}, history: repo);
      await tester.scrollUntilVisible(find.widgetWithText(ActionChip, 'History'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('Recent conversations'), findsNothing);
    });

    testWidgets('Home device status names the current outputs', (tester) async {
      await pumpAnuvaadApp(
        tester,
        prefs: {'onboarding_complete': true},
        audio: FakeAudioOutput(connected: [fakeSpeaker, fakeBuds]),
      );
      final status = find.text('Translated voice: Galaxy Buds · Reply: Phone speaker');
      await tester.scrollUntilVisible(status, 200, scrollable: find.byType(Scrollable).first);
      expect(status, findsOneWidget);
      await tester.tap(status);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('audio-devices-screen')), findsOneWidget);
    });
  });
}
