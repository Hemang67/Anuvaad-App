import 'package:anuvaad/features/conversation/application/review_reply.dart';
import 'package:anuvaad/features/conversation/domain/segment.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/conversation_fakes.dart';
import '../../helpers/conversation_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final h = ConversationHarness();

  setUp(() => h.setUp(initialPrefs: {'review_reply': true}));
  tearDown(() => h.tearDown());

  Iterable<String> plays() => h.audio.calls.where((c) => c.startsWith('play:'));

  test('with review on, a reply waits instead of playing', () async {
    expect(h.container.read(reviewReplyProvider), isTrue);
    await h.controller.startSpeaking();
    final id = await h.say('Hello');
    expect(h.seg(id).status, SegmentStatus.translated);
    expect(h.seg(id).speech, SpeechStatus.awaitingReview);
    expect(plays(), isEmpty);
    expect(h.synth.synthesizedPaths, isEmpty);
  });

  test('editing a reply retranslates and keeps waiting', () async {
    await h.controller.startSpeaking();
    final id = await h.say('Hello');
    await h.controller.editReply(id, 'Hello there');
    await h.flush();
    expect(h.seg(id).text, 'Hello there');
    expect(h.cloud.requests.last.text, 'Hello there');
    expect(h.seg(id).translation!.text, 'EN:Hello there');
    expect(h.seg(id).speech, SpeechStatus.awaitingReview);
    expect(plays(), isEmpty);
  });

  test('Play speaks it on the speaker, then listening resumes', () async {
    await h.controller.startListening();
    await h.controller.startSpeaking();
    final id = await h.say('Hello');
    await h.flush();
    expect(h.starts, 2, reason: 'listening waits while the reply is under review');

    await h.controller.playReply(id);
    expect(plays(), ['play:$id:${fakeSpeaker.id}']);
    await h.playThrough(id);
    expect(h.recognizer.started, ['hi-IN', 'en-IN', 'hi-IN']);
  });

  test('Discard removes it and listening resumes', () async {
    await h.controller.startListening();
    await h.controller.startSpeaking();
    final id = await h.say('Hello');
    h.controller.discardReply(id);
    await h.flush();
    expect(h.state.segments.where((s) => s.id == id), isEmpty);
    expect(plays(), isEmpty);
    expect(h.recognizer.started, ['hi-IN', 'en-IN', 'hi-IN']);
  });

  test('the other person\'s translations never wait for review', () async {
    await h.controller.startListening();
    final id = await h.say('नमस्ते');
    expect(plays(), ['play:$id:${fakeSpeaker.id}']);
  });

  test('with review off, replies play straight away', () async {
    await h.container.read(reviewReplyProvider.notifier).set(false);
    expect(h.prefs.getBool('review_reply'), isFalse);
    await h.controller.startSpeaking();
    final id = await h.say('Hello');
    expect(plays(), ['play:$id:${fakeSpeaker.id}']);
  });
}
