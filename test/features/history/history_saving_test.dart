import 'dart:async';

import 'package:anuvaad/features/conversation/domain/segment.dart';
import 'package:anuvaad/features/history/application/history_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/conversation_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final h = ConversationHarness();

  tearDown(() => h.tearDown());

  Future<void> talk() async {
    await h.controller.startListening();
    final id = await h.say('नमस्ते');
    await h.playThrough(id);
  }

  test('with history off, End saves nothing', () async {
    await h.setUp();
    expect(h.container.read(saveHistoryProvider), isFalse);
    await talk();
    await h.controller.endSession();
    await h.flush();
    expect(await h.history.list(), isEmpty);
    expect(h.state.savedToHistory, isFalse);
  });

  test('with history on, End saves the conversation', () async {
    await h.setUp(initialPrefs: {'save_history': true});
    await talk();
    h.now = h.now.add(const Duration(minutes: 2));
    await h.controller.endSession();
    await h.flush();
    final saved = (await h.history.list()).single;
    expect(saved.startedAt, DateTime(2026, 11, 6, 10));
    expect(saved.endedAt, DateTime(2026, 11, 6, 10, 2));
    expect(saved.myLanguage, 'en-IN');
    expect(saved.otherLanguages, ['hi-IN']);
    expect(saved.segments.single.text, 'नमस्ते');
    expect(saved.segments.single.translation, 'EN:नमस्ते');
    expect(saved.segments.single.speaker, Speaker.other);
    expect(h.state.savedToHistory, isTrue);
  });

  test('Save from the summary saves one conversation while history is off', () async {
    await h.setUp();
    await talk();
    await h.controller.endSession();
    await h.controller.saveToHistory();
    expect(await h.history.list(), hasLength(1));
    expect(h.state.savedToHistory, isTrue);
    expect(h.container.read(saveHistoryProvider), isFalse, reason: 'saving one is not turning history on');
  });

  test('a translation that arrives after End is saved but not spoken', () async {
    await h.setUp(initialPrefs: {'save_history': true});
    await h.controller.startListening();
    final id = h.activeId;
    h.cloud.gates[id] = Completer<void>();
    await h.say('नमस्ते');
    await h.controller.endSession();
    await h.flush();
    expect((await h.history.list()).single.segments.single.translation, isNull);

    h.cloud.gates[id]!.complete();
    await h.flush();
    expect(h.seg(id).status, SegmentStatus.translated);
    expect(h.audio.calls.where((c) => c.startsWith('play:')), isEmpty);
    expect((await h.history.list()).single.segments.single.translation, 'EN:नमस्ते');
  });

  test('leaving the screen without End still saves when history is on', () async {
    await h.setUp(initialPrefs: {'save_history': true});
    await talk();
    h.close();
    await h.flush();
    expect((await h.history.list()).single.segments.single.text, 'नमस्ते');
    h.container = h.build();
  });

  test('a conversation with nothing said is not saved', () async {
    await h.setUp(initialPrefs: {'save_history': true});
    await h.controller.startListening();
    await h.controller.endSession();
    await h.flush();
    expect(await h.history.list(), isEmpty);
  });

  test('history can be switched on and off', () async {
    await h.setUp();
    await h.container.read(saveHistoryProvider.notifier).set(true);
    expect(h.prefs.getBool('save_history'), isTrue);
    expect(h.container.read(saveHistoryProvider), isTrue);
  });
}
