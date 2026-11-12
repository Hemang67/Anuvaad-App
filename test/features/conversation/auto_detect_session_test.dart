import 'package:anuvaad/features/conversation/application/conversation_controller.dart';
import 'package:anuvaad/features/conversation/application/language_detection.dart';
import 'package:anuvaad/features/conversation/application/session_status.dart';
import 'package:anuvaad/features/conversation/domain/segment.dart';
import 'package:anuvaad/features/conversation/domain/speech_recognition.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/conversation_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final h = ConversationHarness();

  setUp(() async {
    await h.setUp();
    h.other = 'auto';
    h.recognizer.detectionSupported = true;
    h.rebuild();
  });
  tearDown(() => h.tearDown());

  Future<String> detectAndSay(String locale, LanguageConfidence confidence, String text) async {
    h.recognizer.emit(LanguageDetected(locale, confidence));
    return h.say(text);
  }

  test('auto mode with detection starts in the first other language and passes detectAmong', () async {
    await h.controller.startListening();
    expect(h.recognizer.started, ['hi-IN']);
    expect(h.recognizer.startDetectAmong, ['hi-IN', 'gu-IN']);
  });

  test('a confident detection labels the card Detected and becomes the stable language', () async {
    await h.controller.startListening();
    final id = await detectAndSay('gu-IN', LanguageConfidence.confident, 'તમે ક્યાં જાઓ છો?');
    expect(h.seg(id).sourceLanguage, 'gu-IN');
    expect(h.seg(id).detected, isTrue);
    expect(h.seg(id).status, isNot(SegmentStatus.unclear));
    expect(h.state.otherLanguageOverride, 'gu-IN');
    expect(h.state.otherLanguageDetected, isTrue);

    await h.playThrough(id);
    expect(h.recognizer.started.last, 'gu-IN', reason: 'the next turn listens in the stable language');
    expect(h.recognizer.startDetectAmong, ['hi-IN', 'gu-IN'], reason: 'and still watches for a switch');
  });

  test('an unclear segment is not translated until the user picks', () async {
    await h.controller.startListening();
    final id = await h.say('नमस्ते');
    expect(h.seg(id).status, SegmentStatus.unclear);
    expect(h.cloud.requests, isEmpty);
    expect(sessionStatus(h.state), SessionStatus.choosingLanguage);
    expect(h.starts, 1, reason: 'listening waits for the choice');

    h.controller.confirmLanguage(id, 'hi-IN');
    await h.flush();
    expect(h.seg(id).status, SegmentStatus.translated);
    expect(h.cloud.requests.single.sourceLanguage, 'hi-IN');
    expect(h.state.otherLanguageOverride, 'hi-IN');
    expect(h.state.otherLanguageDetected, isFalse);
  });

  test('picking a different language drops the card and asks them to repeat', () async {
    await h.controller.startListening();
    final id = await h.say('नमस्ते');
    h.controller.confirmLanguage(id, 'gu-IN');
    await h.flush();
    expect(h.state.segments.where((s) => s.id == id), isEmpty);
    expect(h.state.notice, ConversationNotice.askToRepeat);
    expect(h.state.noticeLanguage, 'gu-IN');
    expect(h.recognizer.started.last, 'gu-IN');
    expect(h.starts, 2);
  });

  test('without detection support, auto asks once and remembers', () async {
    h.recognizer.detectionSupported = false;
    await h.controller.startListening();
    expect(h.starts, 0);
    expect(h.state.notice, ConversationNotice.chooseOtherLanguage);

    h.controller.chooseOtherLanguage('gu-IN');
    await h.flush();
    expect(h.recognizer.started, ['gu-IN']);
    expect(h.recognizer.startDetectAmong, isEmpty);
    final id = await h.say('નમસ્તે');
    expect(h.seg(id).status, isNot(SegmentStatus.unclear));
    await h.playThrough(id);
    expect(h.recognizer.started, ['gu-IN', 'gu-IN']);
  });

  test('auto-detect off in settings behaves like no support', () async {
    await h.container.read(autoDetectProvider.notifier).set(false);
    expect(h.prefs.getBool('auto_detect'), isFalse);
    await h.controller.startListening();
    expect(h.starts, 0);
    expect(h.state.notice, ConversationNotice.chooseOtherLanguage);
  });

  test('a strong detection of the other language switches the stable language', () async {
    await h.controller.startListening();
    final first = await detectAndSay('hi', LanguageConfidence.highlyConfident, 'आप कहाँ जा रहे हैं?');
    await h.playThrough(first);
    final second = await detectAndSay('gu-IN', LanguageConfidence.confident, 'હું ઓફિસ જાઉં છું');
    expect(h.seg(second).sourceLanguage, 'gu-IN');
    expect(h.state.otherLanguageOverride, 'gu-IN');
  });
}
