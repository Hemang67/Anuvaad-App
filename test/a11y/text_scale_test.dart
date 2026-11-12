import 'dart:io';

import 'package:anuvaad/core/permissions/microphone_permission.dart';
import 'package:anuvaad/features/conversation/application/translation_service.dart';
import 'package:anuvaad/features/conversation/data/android_speech_recognizer.dart';
import 'package:anuvaad/features/conversation/domain/speech_recognition.dart';
import 'package:anuvaad/features/diagnostics/data/latency_log.dart';
import 'package:anuvaad/features/history/data/file_history_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/app_harness.dart';
import '../helpers/conversation_fakes.dart';
import '../helpers/history_fixtures.dart';
import '../helpers/latency_fixtures.dart';

/// Every main screen at 200% text on a small phone (360×780), in English and Gujarati (spec R48). Any overflow is
/// reported by Flutter as an error and fails the test; each screen is scrolled to the end so every part is laid out.
void main() {
  late Directory root;
  late FileHistoryRepository history;
  late LatencyLog latency;
  late FakeSpeechRecognizer recognizer;

  setUp(() async {
    root = Directory.systemTemp.createTempSync('anuvaad_text_scale');
    history = FileHistoryRepository(() async => root);
    latency = LatencyLog(() async => root);
    recognizer = FakeSpeechRecognizer();
    await history.save(savedConversation('a', DateTime(2026, 11, 5, 9), unclear: true));
    await latency.record(latencySample());
  });
  tearDown(() => root.deleteSync(recursive: true));

  Future<void> pumpSmallPhone(WidgetTester tester, String language, {Map<String, Object> prefs = const {}}) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpAnuvaadApp(
      tester,
      prefs: {'onboarding_complete': true, 'app_language': language, 'save_history': true, 'other_language': 'hi-IN', ...prefs},
      history: history,
      latency: latency,
      overrides: <Override>[
        speechRecognizerProvider.overrideWithValue(recognizer),
        microphonePermissionProvider.overrideWithValue(FakeMicrophonePermission()),
        translationServiceProvider.overrideWithValue(
          TranslationService(cloud: FakeTranslator(reply: (r) => 'A translation long enough to wrap: ${r.text}'), offline: FakeTranslator()),
        ),
      ],
    );
  }

  Future<void> scrollToEnd(WidgetTester tester) async {
    final scrollables = find.byType(Scrollable);
    if (scrollables.evaluate().isEmpty) return;
    for (var i = 0; i < 25; i++) {
      final state = tester.state<ScrollableState>(scrollables.first);
      final before = state.position.pixels;
      await tester.drag(scrollables.first, const Offset(0, -400), warnIfMissed: false);
      await tester.pumpAndSettle();
      if (state.position.pixels == before) break;
    }
  }

  Future<void> open(WidgetTester tester, String path) async {
    GoRouter.of(tester.element(find.byType(Scaffold).first)).push(path);
    await tester.pumpAndSettle();
  }

  for (final language in ['en', 'gu']) {
    group('200% text, $language:', () {
      testWidgets('Home', (tester) async {
        await pumpSmallPhone(tester, language);
        await scrollToEnd(tester);
      });

      testWidgets('Languages', (tester) async {
        await pumpSmallPhone(tester, language);
        GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/languages');
        await tester.pumpAndSettle();
        await scrollToEnd(tester);
      });

      testWidgets('Settings', (tester) async {
        await pumpSmallPhone(tester, language);
        GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/settings');
        await tester.pumpAndSettle();
        await scrollToEnd(tester);
      });

      testWidgets('Conversation with a translation and a reply under review', (tester) async {
        await pumpSmallPhone(tester, language, prefs: {'review_reply': true});
        await open(tester, '/conversation');
        await tester.tap(find.byKey(const Key('listen-button')));
        await tester.pumpAndSettle();
        recognizer.emit(const FinalResult('आप आज कहाँ जा रहे हैं? मुझे स्टेशन जाना है।'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('speak-button')));
        await tester.pumpAndSettle();
        recognizer.emit(const FinalResult("I'm going to the office, then home."));
        await tester.pumpAndSettle();
        await scrollToEnd(tester);
        await tester.tap(find.byKey(const Key('end-button')));
        await tester.pumpAndSettle();
      });

      testWidgets('Conversation with a card whose language is unclear', (tester) async {
        recognizer.detectionSupported = true;
        await pumpSmallPhone(tester, language, prefs: {'other_language': 'auto'});
        await open(tester, '/conversation');
        await tester.tap(find.byKey(const Key('listen-button')));
        await tester.pumpAndSettle();
        recognizer.emit(const FinalResult('नमस्ते'));
        await tester.pumpAndSettle();
        await scrollToEnd(tester);
      });

      for (final path in ['/audio-devices', '/history', '/history/a', '/voices', '/privacy', '/latency', '/meeting']) {
        testWidgets(path, (tester) async {
          await pumpSmallPhone(tester, language);
          await open(tester, path);
          await scrollToEnd(tester);
        });
      }

      testWidgets('Onboarding', (tester) async {
        await pumpSmallPhone(tester, language, prefs: {'onboarding_complete': false});
        for (var page = 0; page < 4; page++) {
          await scrollToEnd(tester);
          final next = find.byType(FilledButton);
          if (next.evaluate().isEmpty) break;
          await tester.tap(next.last, warnIfMissed: false);
          await tester.pumpAndSettle();
        }
      });
    });
  }
}
