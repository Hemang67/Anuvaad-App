import 'package:anuvaad/features/conversation/application/mic_level.dart';
import 'package:anuvaad/features/conversation/domain/audio_output.dart';
import 'package:anuvaad/features/conversation/domain/segment.dart';
import 'package:anuvaad/features/conversation/domain/speech_recognition.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/conversation_fakes.dart';
import '../../helpers/conversation_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final h = ConversationHarness();

  setUp(() async {
    await h.setUp();
    // Long enough not to fire before End on a slow run, short enough to wait out after it.
    h.watchdog = const Duration(milliseconds: 300);
    h.rebuild();
  });
  tearDown(() => h.tearDown());

  test('End releases everything: microphone, playback, level, and nothing fires afterwards', () async {
    await h.controller.startListening();
    final first = await h.say('नमस्ते');
    h.audio.emit(PlaybackStarted(first, fakeSpeaker));
    await h.flush();
    expect(h.starts, 1);

    await h.controller.endSession();
    expect(h.audio.calls.last, 'stop');
    expect(h.container.read(micLevelProvider), 0);
    expect(h.seg(first).speech, SpeechStatus.played);

    // The playback watchdog, a late completion and late recognizer events all find a closed session.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    h.audio.emit(PlaybackCompleted(first));
    h.recognizer.emit(const SoundLevel(0.9));
    h.recognizer.emit(const FinalResult('late'));
    await h.flush();
    expect(h.starts, 1);
    expect(h.container.read(micLevelProvider), 0);
    expect(h.state.segments, hasLength(1));
  });

  test('End while listening cancels the recognizer once', () async {
    await h.controller.startListening();
    h.recognizer.emit(const SoundLevel(0.7));
    await h.flush();
    await h.controller.endSession();
    expect(h.recognizer.cancels, 1);
    expect(h.container.read(micLevelProvider), 0);
    await h.controller.endSession();
    expect(h.recognizer.cancels, 1, reason: 'a second End does nothing');
  });
}
