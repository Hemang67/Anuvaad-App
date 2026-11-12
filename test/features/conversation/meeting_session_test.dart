import 'package:anuvaad/features/conversation/domain/segment.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/conversation_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final h = ConversationHarness();

  setUp(() => h.setUp());
  tearDown(() => h.tearDown());

  test('startMeeting listens in the meeting language, and Speak does nothing', () async {
    await h.controller.startMeeting('gu-IN');
    expect(h.state.mode, ConversationMode.meeting);
    expect(h.state.listenMode, isTrue);
    expect(h.recognizer.started, ['gu-IN']);
    await h.controller.startSpeaking();
    expect(h.recognizer.started, ['gu-IN']);
    expect(h.state.activeSpeaker, Speaker.other);
  });

  test('a meeting in Automatic keeps the configured language rules', () async {
    await h.controller.startMeeting(null);
    expect(h.state.mode, ConversationMode.meeting);
    expect(h.recognizer.started, ['hi-IN'], reason: 'the other language from Languages');
  });
}
