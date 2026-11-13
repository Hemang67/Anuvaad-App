import 'package:anuvaad/core/permissions/microphone_permission.dart';
import 'package:anuvaad/features/conversation/application/conversation_controller.dart';
import 'package:anuvaad/features/conversation/data/android_conversation_service.dart';
import 'package:anuvaad/features/conversation/domain/conversation_service.dart';
import 'package:anuvaad/features/conversation/domain/segment.dart';
import 'package:anuvaad/features/conversation/domain/speech_recognition.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/conversation_fakes.dart';
import '../../helpers/conversation_harness.dart';

/// Conversations with the screen off: Android's conversation service, its notification and buttons, the earphone
/// button, and replies without tapping.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final h = ConversationHarness();
  late FakeConversationService service;

  setUp(() async {
    await h.setUp();
    service = FakeConversationService();
    h.overrides = [conversationServiceProvider.overrideWithValue(service)];
    h.rebuild();
  });

  /// Saves these settings and opens the conversation again (settings are read when it opens).
  Future<void> setUpWith([Map<String, bool> prefs = const {}]) async {
    for (final e in prefs.entries) {
      await h.prefs.setBool(e.key, e.value);
    }
    h.rebuild();
  }
  tearDown(() => h.tearDown());

  void toBackground(WidgetTester tester) {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
  }

  void toForeground(WidgetTester tester) {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  }

  group('the conversation service', () {
    test('Listen starts it once the microphone is allowed, with its notification; End stops it', () async {
      await h.controller.startListening();
      expect(service.startCalls, 1);
      expect(service.channelName, 'Conversations');
      expect(service.earphoneButton, isTrue);
      expect(service.notification!.title, 'Listening to Hindi');
      expect(service.notification!.text, 'English ↔ Hindi');
      expect(service.buttons, [SessionCommand.speak, SessionCommand.pause, SessionCommand.end]);

      final id = await h.say('नमस्ते');
      await h.playThrough(id);
      expect(h.starts, 2);
      expect(service.startCalls, 1, reason: 'one service for the whole conversation');

      await h.controller.endSession();
      await h.flush();
      expect(service.stops, 1);
      expect(service.running, isFalse);
    });

    test('a denied microphone never starts it', () async {
      h.mic.current = MicPermission.denied;
      h.mic.onRequest = MicPermission.denied;
      await h.controller.startListening();
      expect(service.startCalls, 0);
    });

    test('leaving the conversation screen stops it', () async {
      await h.controller.startListening();
      h.rebuild();
      await h.flush();
      expect(service.stops, 1);
    });

    test('with "Keep listening with the screen off" off, it never starts', () async {
      await setUpWith({'screen_off_listening': false});
      await h.controller.startListening();
      expect(service.startCalls, 0);
      expect(h.starts, 1, reason: 'the conversation itself works as before');
    });

    test('the earphone button is handed over only when its setting is on', () async {
      await setUpWith({'earphone_button': false});
      await h.controller.startListening();
      expect(service.earphoneButton, isFalse);
    });
  });

  group('in the background', () {
    testWidgets('the conversation keeps listening, translating and speaking with the screen off', (tester) async {
      await tester.runAsync(() => h.controller.startListening());
      toBackground(tester);
      await tester.runAsync(h.flush);
      expect(h.state.paused, isFalse);
      expect(h.state.listenMode, isTrue);
      expect(h.recognizer.cancels, 0, reason: 'the turn that was listening keeps listening');

      final id = (await tester.runAsync(() => h.say('नमस्ते')))!;
      expect(h.audio.calls.where((c) => c.startsWith('play:')), hasLength(1), reason: 'the translation plays');
      await tester.runAsync(() => h.playThrough(id));
      expect(h.starts, 2, reason: 'and the next turn starts listening');
      toForeground(tester);
    });

    testWidgets('when Android refused the service, the background pauses as before', (tester) async {
      service.accept = false;
      await tester.runAsync(() => h.controller.startListening());
      toBackground(tester);
      await tester.runAsync(h.flush);
      expect(h.state.paused, isTrue);
      expect(h.recognizer.cancels, 1);
      toForeground(tester);
    });

    testWidgets('when Android stopped the service, the background pauses as before', (tester) async {
      await tester.runAsync(() async {
        await h.controller.startListening();
        service.send(SessionCommand.stopped);
        await h.flush();
      });
      toBackground(tester);
      await tester.runAsync(h.flush);
      expect(h.state.paused, isTrue);
      toForeground(tester);
    });
  });

  group('the notification', () {
    test('follows the session: paused, then your turn', () async {
      await h.controller.startListening();
      expect(service.notification!.active, isTrue);

      await h.controller.pause();
      await h.flush();
      expect(service.notification!.title, 'Paused');
      expect(service.buttons, [SessionCommand.listen, SessionCommand.speak, SessionCommand.end]);
      expect(service.notification!.active, isFalse, reason: 'nothing to keep the processor awake for');

      await h.controller.startSpeaking();
      await h.flush();
      expect(service.notification!.title, 'Your turn: speak now');
      expect(service.buttons, [SessionCommand.finishReply, SessionCommand.end]);
    });

    test('shows the latest translation only as private text', () async {
      await h.controller.startListening();
      await h.say('नमस्ते');
      expect(service.notification!.privateText, 'EN:नमस्ते');
      expect(service.notification!.text, 'English ↔ Hindi');
    });

    test('a reply waiting for review offers Play and Discard', () async {
      await setUpWith({'review_reply': true});
      await h.controller.startSpeaking();
      await h.say('Hello');
      expect(service.notification!.title, 'Your reply is ready');
      expect(service.buttons, [SessionCommand.playReply, SessionCommand.discardReply, SessionCommand.end]);
    });

    test('keeps the processor awake only while something is happening, not while it waits for you', () async {
      await setUpWith({'review_reply': true});
      await h.controller.startSpeaking();
      expect(service.notification!.active, isTrue, reason: 'your turn');
      await h.say('Hello');
      expect(service.notification!.title, 'Your reply is ready');
      expect(service.notification!.active, isFalse, reason: 'waiting for Play or Discard');

      h.other = 'auto';
      await setUpWith();
      await h.controller.startListening();
      expect(h.state.notice, ConversationNotice.chooseOtherLanguage);
      expect(service.notification!.active, isFalse, reason: 'waiting for their language');
    });

    test('a meeting has no Speak button, and leaves the earphone button to music', () async {
      await h.controller.startMeeting('hi-IN');
      expect(service.notification!.text, 'Meeting · Hindi');
      expect(service.buttons, [SessionCommand.pause, SessionCommand.end]);
      expect(service.earphoneButton, isFalse);
    });

    test('is not sent again when nothing it shows changed', () async {
      await h.controller.startListening();
      final before = service.shown.length;
      h.recognizer.emit(const SoundLevel(0.5));
      h.recognizer.emit(const PartialResult('नम'));
      await h.flush();
      expect(service.shown.length, before);
    });
  });

  group('notification buttons', () {
    test('Speak starts your reply, Done sends it', () async {
      await h.controller.startListening();
      service.send(SessionCommand.speak);
      await h.flush();
      expect(h.state.activeSpeaker, Speaker.me);
      expect(h.recognizer.started.last, 'en-IN');
      service.send(SessionCommand.finishReply);
      await h.flush();
      expect(h.recognizer.stops, 1, reason: 'stopping the recognizer sends what was said so far');
    });

    test('Pause, Listen and End', () async {
      await h.controller.startListening();
      service.send(SessionCommand.pause);
      await h.flush();
      expect(h.state.paused, isTrue);
      service.send(SessionCommand.listen);
      await h.flush();
      expect(h.state.listenMode, isTrue);
      expect(h.starts, 2);
      service.send(SessionCommand.end);
      await h.flush();
      expect(h.state.ended, isTrue);
      expect(service.stops, 1);
    });

    test('Play and Discard act on the reply waiting for review', () async {
      await setUpWith({'review_reply': true});
      await h.controller.startSpeaking();
      final id = await h.say('Hello');
      service.send(SessionCommand.playReply);
      await h.flush();
      expect(h.audio.calls.where((c) => c.startsWith('play:$id')), hasLength(1));

      await h.playThrough(id);
      await h.controller.startSpeaking();
      final second = await h.say('Thank you');
      service.send(SessionCommand.discardReply);
      await h.flush();
      expect(h.state.segments.where((s) => s.id == second), isEmpty);
    });
  });

  group('the earphone button', () {
    test('starts your reply, and a second press sends it', () async {
      await h.controller.startListening();
      service.send(SessionCommand.earphoneButton);
      await h.flush();
      expect(h.state.activeSpeaker, Speaker.me);
      service.send(SessionCommand.earphoneButton);
      await h.flush();
      expect(h.recognizer.stops, 1);
    });

    test('plays a reply waiting for review', () async {
      await setUpWith({'review_reply': true});
      await h.controller.startSpeaking();
      final id = await h.say('Hello');
      service.send(SessionCommand.earphoneButton);
      await h.flush();
      expect(h.audio.calls.where((c) => c.startsWith('play:$id')), hasLength(1));
    });

    test('does nothing in a meeting', () async {
      await h.controller.startMeeting('hi-IN');
      service.send(SessionCommand.earphoneButton);
      await h.flush();
      expect(h.state.activeSpeaker, Speaker.other);
      expect(h.recognizer.started, ['hi-IN']);
    });
  });

  group('replies without tapping (Android 14 and later)', () {
    Future<void> autoReply({bool on = true, bool supported = true}) async {
      h.recognizer.detectionSupported = supported;
      await setUpWith({'auto_reply': on});
    }

    test('off by default: Listen does not listen for your language', () async {
      h.recognizer.detectionSupported = true;
      await setUpWith();
      await h.controller.startListening();
      expect(h.recognizer.startDetectAmong, isEmpty);
    });

    test('Listen also listens for your language', () async {
      await autoReply();
      await h.controller.startListening();
      expect(h.recognizer.started.last, 'hi-IN');
      expect(h.recognizer.startDetectAmong, ['hi-IN', 'en-IN']);
    });

    test('a confident detection of your language makes the turn your reply', () async {
      await autoReply();
      await h.controller.startListening();
      final id = h.activeId;
      h.recognizer.emit(const LanguageDetected('en-IN', LanguageConfidence.confident));
      h.recognizer.emit(const FinalResult('where is the station'));
      await h.flush();
      final s = h.seg(id);
      expect(s.speaker, Speaker.me);
      expect(s.sourceLanguage, 'en-IN');
      expect(s.targetLanguage, 'hi-IN');
      expect(h.cloud.requests.last.targetLanguage, 'hi-IN');
      expect(h.state.otherLanguageOverride, isNull, reason: 'their language stays as it was');
      await h.playThrough(id);
      expect(h.starts, 2, reason: 'listening carries on after your reply');
    });

    test('a weak detection keeps it their turn', () async {
      await autoReply();
      await h.controller.startListening();
      final id = h.activeId;
      h.recognizer.emit(const LanguageDetected('en-IN', LanguageConfidence.confident));
      h.recognizer.emit(const FinalResult('ok station'));
      await h.flush();
      expect(h.seg(id).speaker, Speaker.other);
      expect(h.seg(id).sourceLanguage, 'hi-IN');
      expect(h.seg(id).status, isNot(SegmentStatus.unclear), reason: 'a fixed language never asks');
    });

    test('while their language is still unknown, your language is not taken as a reply', () async {
      h.other = 'auto';
      await autoReply();
      await h.controller.startListening();
      expect(h.recognizer.startDetectAmong, ['hi-IN', 'gu-IN', 'en-IN']);
      final id = h.activeId;
      h.recognizer.emit(const LanguageDetected('en-IN', LanguageConfidence.highlyConfident));
      h.recognizer.emit(const FinalResult('where is the station'));
      await h.flush();
      expect(h.seg(id).speaker, Speaker.other);
    });

    test('not in a meeting, and not without detection', () async {
      await autoReply();
      await h.controller.startMeeting('hi-IN');
      expect(h.recognizer.startDetectAmong, isEmpty);

      await autoReply(supported: false);
      await h.controller.startListening();
      expect(h.recognizer.startDetectAmong, isEmpty);
    });
  });
}
