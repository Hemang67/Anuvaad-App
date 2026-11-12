import 'dart:io';

import 'package:anuvaad/features/diagnostics/data/latency_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/conversation_fakes.dart';
import '../../helpers/latency_fixtures.dart';

void main() {
  late Directory root;
  late LatencyLog log;
  late FakeTranscriptSharer sharer;

  setUp(() {
    root = Directory.systemTemp.createTempSync('anuvaad_latency_screen');
    log = LatencyLog(() async => root);
    sharer = FakeTranscriptSharer();
  });
  tearDown(() => root.deleteSync(recursive: true));

  Future<void> openReport(WidgetTester tester) async {
    await pumpAnuvaadApp(tester, prefs: {'onboarding_complete': true}, latency: log, sharer: sharer);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
    await tester.pumpAndSettle();
    await scrollIntoView(tester, find.text('Latency report'));
    await tester.tap(find.text('Latency report'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('latency-screen')), findsOneWidget);
  }

  testWidgets('latency screen shows per-pair stats and exports', (tester) async {
    for (final ms in [1500, 1800, 2600]) {
      await log.record(latencySample(endToAudio: ms));
    }
    await openReport(tester);
    expect(find.text('No words are recorded, only timings.'), findsOneWidget);
    expect(find.text('Hindi → English'), findsOneWidget);
    expect(find.text('3 turns'), findsOneWidget);
    expect(find.text('End of speech → first audio'), findsOneWidget);
    expect(find.text('median 1.8 s · p95 2.6 s'), findsOneWidget);

    await tester.tap(find.byTooltip('Export CSV'));
    await tester.pumpAndSettle();
    expect(sharer.shared.single.fileName, endsWith('.csv'));
    expect(sharer.shared.single.text, startsWith('at,pair,speaker'));
  });

  testWidgets('an empty report says how to fill it, and Clear empties it', (tester) async {
    await log.record(latencySample());
    await openReport(tester);
    await tester.tap(find.byTooltip('Clear'));
    await tester.pumpAndSettle();
    expect(find.text('No timings yet. Have a conversation, then come back.'), findsOneWidget);
    expect(await log.samples(), isEmpty);
  });
}
