import 'dart:async';
import 'dart:io';

import 'package:anuvaad/core/permissions/microphone_permission.dart';
import 'package:anuvaad/core/settings/settings_providers.dart';
import 'package:anuvaad/features/app_update/application/update_controller.dart' show clockProvider;
import 'package:anuvaad/features/conversation/application/conversation_controller.dart';
import 'package:anuvaad/features/conversation/application/output_router.dart';
import 'package:anuvaad/features/conversation/application/translation_service.dart';
import 'package:anuvaad/features/conversation/application/voice_service.dart';
import 'package:anuvaad/features/conversation/data/android_audio.dart';
import 'package:anuvaad/features/conversation/data/android_speech_recognizer.dart';
import 'package:anuvaad/features/conversation/data/mlkit_translator.dart';
import 'package:anuvaad/features/conversation/data/offline_models.dart';
import 'package:anuvaad/features/conversation/domain/audio_output.dart';
import 'package:anuvaad/features/conversation/domain/segment.dart';
import 'package:anuvaad/features/conversation/domain/speech_recognition.dart';
import 'package:anuvaad/features/conversation/domain/translation.dart';
import 'package:anuvaad/features/conversation/domain/voice.dart';
import 'package:anuvaad/features/language_settings/application/language_preferences_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/conversation_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSpeechRecognizer recognizer;
  late FakeTranslator cloud;
  late FakeTranslator offline;
  late FakeMicrophonePermission mic;
  late ProviderContainer container;
  late ProviderSubscription<ConversationState> keepAlive;
  late CountingOfflineModels models;
  late FakeAudioOutput audio;
  late FakeSpeechSynth synth;
  late Directory cache;
  late SharedPreferences prefs;
  var now = DateTime(2026, 11, 6, 10);

  ProviderContainer build({String my = 'en-IN', String other = 'hi-IN'}) {
    final c = ProviderContainer(overrides: [
      speechRecognizerProvider.overrideWithValue(recognizer),
      microphonePermissionProvider.overrideWithValue(mic),
      translationServiceProvider.overrideWithValue(TranslationService(cloud: cloud, offline: offline)),
      languagePreferencesProvider.overrideWith(
        () => FixedLanguagePreferences(LanguagePreferences(myLanguage: my, otherLanguage: other)),
      ),
      clockProvider.overrideWithValue(() => now),
      offlineModelsProvider.overrideWithValue(models),
      audioOutputProvider.overrideWithValue(audio),
      speechSynthProvider.overrideWithValue(synth),
      voiceServiceProvider.overrideWith((ref) => VoiceService(synth: synth, cacheDir: () async => cache)),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    keepAlive = c.listen(conversationControllerProvider, (_, _) {});
    return c;
  }

  ConversationController controller() => container.read(conversationControllerProvider.notifier);
  ConversationState state() => container.read(conversationControllerProvider);
  Future<void> flush() => pumpEventQueue();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    audio = FakeAudioOutput(connected: [fakeSpeaker]);
    synth = FakeSpeechSynth();
    cache = Directory.systemTemp.createTempSync('anuvaad_controller_test');
    recognizer = FakeSpeechRecognizer();
    cloud = FakeTranslator(reply: (r) => 'Where are you going today?');
    offline = FakeTranslator(provenance: TranslationProvenance.offline, provider: 'mlkit');
    mic = FakeMicrophonePermission();
    models = CountingOfflineModels();
    container = build();
  });

  tearDown(() {
    keepAlive.close();
    container.dispose();
    if (cache.existsSync()) cache.deleteSync(recursive: true);
  });

  test('listen turn shows partials then the translation', () async {
    await controller().startTurn(Speaker.other);
    expect(recognizer.started, ['hi-IN']);
    expect(state().activeSpeaker, Speaker.other);
    expect(state().segments.single.status, SegmentStatus.listening);

    recognizer.emit(const PartialResult('आप'));
    await flush();
    expect(state().segments.single.text, 'आप');
    expect(state().segments.single.isFinal, isFalse);

    now = now.add(const Duration(seconds: 2));
    recognizer.emit(const FinalResult('आप आज कहाँ जा रहे हैं?'));
    await flush();

    final segment = state().segments.single;
    expect(state().activeSpeaker, isNull);
    expect(segment.seq, 1);
    expect(segment.speaker, Speaker.other);
    expect(segment.sourceLanguage, 'hi-IN');
    expect(segment.targetLanguage, 'en-IN');
    expect(segment.text, 'आप आज कहाँ जा रहे हैं?');
    expect(segment.isFinal, isTrue);
    expect(segment.status, SegmentStatus.translated);
    expect(segment.translation!.text, 'Where are you going today?');
    expect(segment.translation!.provenance, TranslationProvenance.online);
    expect(segment.finalAt, DateTime(2026, 11, 6, 10, 0, 2));
    expect(segment.translatedAt, isNotNull);
    expect(cloud.requests.single.segmentId, segment.id);
    expect(cloud.requests.single.sourceLanguage, 'hi-IN');
    expect(cloud.requests.single.targetLanguage, 'en-IN');
  });

  test('speak turn translates my language into theirs', () async {
    await controller().startTurn(Speaker.me);
    expect(recognizer.started, ['en-IN']);
    recognizer.emit(const FinalResult("I'm going to the office."));
    await flush();
    final segment = state().segments.single;
    expect(segment.speaker, Speaker.me);
    expect((segment.sourceLanguage, segment.targetLanguage), ('en-IN', 'hi-IN'));
  });

  test('automatic other language asks for a choice, and the choice is used', () async {
    keepAlive.close();
    container.dispose();
    container = build(other: autoDetect);

    await controller().startTurn(Speaker.other);
    expect(state().notice, ConversationNotice.chooseOtherLanguage);
    expect(recognizer.started, isEmpty);
    expect(state().segments, isEmpty);

    controller().chooseOtherLanguage('gu-IN');
    expect(state().notice, isNull);
    expect(state().otherLanguageOverride, 'gu-IN');
    await controller().startTurn(Speaker.other);
    expect(recognizer.started, ['gu-IN']);
  });

  test('silence removes the listening card and shows the no-speech notice', () async {
    for (final code in [RecognitionErrorCode.noMatch, RecognitionErrorCode.speechTimeout]) {
      await controller().startTurn(Speaker.other);
      recognizer.emit(RecognitionError(code));
      await flush();
      expect(state().segments, isEmpty, reason: '$code');
      expect(state().activeSpeaker, isNull);
      expect(state().notice, ConversationNotice.noSpeech);
    }
  });

  test('an error after partial text keeps the partial as final', () async {
    await controller().startTurn(Speaker.other);
    recognizer.emit(const PartialResult('आप कहाँ'));
    recognizer.emit(const RecognitionError(RecognitionErrorCode.network));
    await flush();
    final segment = state().segments.single;
    expect(segment.text, 'आप कहाँ');
    expect(segment.isFinal, isTrue);
    expect(segment.status, SegmentStatus.translated);
    expect(state().notice, isNull);
  });

  test('duplicate finals are ignored', () async {
    await controller().startTurn(Speaker.other);
    recognizer.emit(const FinalResult('आप कहाँ हैं?'));
    recognizer.emit(const FinalResult('आप कहाँ हैं?'));
    await flush();
    expect(state().segments, hasLength(1));
    expect(cloud.requests, hasLength(1));
  });

  test('out-of-order translations land on their own segments', () async {
    cloud.reply = (r) => 'EN:${r.text}';
    await controller().startTurn(Speaker.other);
    final firstId = state().segments.single.id;
    cloud.gates[firstId] = Completer<void>();
    recognizer.emit(const FinalResult('पहला'));
    await flush();

    await controller().startTurn(Speaker.other);
    final secondId = state().segments.last.id;
    recognizer.emit(const FinalResult('दूसरा'));
    await flush();
    expect(state().segments.last.translation!.text, 'EN:दूसरा');
    expect(state().segments.first.status, SegmentStatus.translating);

    cloud.gates[firstId]!.complete();
    await flush();
    final byId = {for (final s in state().segments) s.id: s};
    expect(byId[firstId]!.translation!.text, 'EN:पहला');
    expect(byId[secondId]!.translation!.text, 'EN:दूसरा');
    expect(state().segments.map((s) => s.seq), [1, 2]);
  });

  test('offline result is marked offline; missing models mark the segment failed with offlineNotReady; retry succeeds later',
      () async {
    cloud.error = Exception('offline');
    await controller().startTurn(Speaker.other);
    recognizer.emit(const FinalResult('आप कहाँ हैं?'));
    await flush();
    expect(state().segments.single.translation!.provenance, TranslationProvenance.offline);

    offline.error = const OfflineModelMissing(['hi-IN']);
    await controller().startTurn(Speaker.other);
    recognizer.emit(const FinalResult('नमस्ते'));
    await flush();
    final failed = state().segments.last;
    expect(failed.status, SegmentStatus.failed);
    expect(failed.offlineNotReady, isTrue);
    expect(failed.translation, isNull);

    offline.error = null;
    await controller().retryTranslation(failed.id);
    await flush();
    expect(state().segments.last.status, SegmentStatus.translated);
    expect(state().segments.last.offlineNotReady, isFalse);
  });

  test('retrying a segment that failed for missing models starts the model download again', () async {
    cloud.error = Exception('offline');
    offline.error = const OfflineModelMissing(['hi-IN']);
    await controller().startTurn(Speaker.other);
    recognizer.emit(const FinalResult('नमस्ते'));
    await flush();
    expect(models.ensureCalls, 0);

    await controller().retryTranslation(state().segments.single.id);
    await flush();
    expect(models.ensureCalls, 1);
    expect(offline.requests, hasLength(2));
  });

  test('denied microphone is requested once; permanently denied is never requested', () async {
    mic
      ..current = MicPermission.denied
      ..onRequest = MicPermission.denied;
    await controller().startTurn(Speaker.other);
    expect(mic.requests, 1);
    expect(state().notice, ConversationNotice.micDenied);
    expect(recognizer.started, isEmpty);

    mic.current = MicPermission.permanentlyDenied;
    await controller().startTurn(Speaker.other);
    expect(mic.requests, 1);
    expect(state().notice, ConversationNotice.micPermanentlyDenied);
  });

  test('a permanent denial from a request is remembered for the session (Android reports it only then)', () async {
    mic
      ..current = MicPermission.denied
      ..onRequest = MicPermission.permanentlyDenied;
    await controller().startTurn(Speaker.other);
    expect(state().notice, ConversationNotice.micPermanentlyDenied);
    await controller().startTurn(Speaker.other);
    expect(mic.requests, 1, reason: 'no second request: Android would just say no again');

    await controller().openMicrophoneSettings();
    expect(mic.settingsOpened, 1);
    mic.current = MicPermission.granted; // the user turned it on in Settings
    await controller().startTurn(Speaker.other);
    expect(recognizer.started, ['hi-IN']);
  });

  test('allowMicrophone asks again and clears the notice when granted', () async {
    mic
      ..current = MicPermission.denied
      ..onRequest = MicPermission.denied;
    await controller().startTurn(Speaker.other);
    mic.onRequest = MicPermission.granted;
    await controller().allowMicrophone();
    expect(mic.requests, 2);
    expect(state().notice, isNull);
  });

  test('recognizer unavailable shows the notice and starts nothing', () async {
    recognizer.available = false;
    await controller().startTurn(Speaker.other);
    expect(state().notice, ConversationNotice.recognizerUnavailable);
    expect(recognizer.started, isEmpty);
    expect(state().segments, isEmpty);
    expect(state().activeSpeaker, isNull);
  });

  test('unsupported recognizer language shows the language notice', () async {
    keepAlive.close();
    container.dispose();
    container = build(other: 'gu-IN');
    for (final code in [RecognitionErrorCode.languageUnavailable, RecognitionErrorCode.languageUnsupported]) {
      await controller().startTurn(Speaker.other);
      recognizer.emit(RecognitionError(code));
      await flush();
      expect(state().notice, ConversationNotice.languageUnsupported);
      expect(state().noticeLanguage, 'gu-IN');
      expect(state().segments, isEmpty);
    }
  });

  test('other recognizer errors map to notices', () async {
    final expected = {
      RecognitionErrorCode.network: ConversationNotice.network,
      RecognitionErrorCode.server: ConversationNotice.network,
      RecognitionErrorCode.busy: ConversationNotice.busy,
      RecognitionErrorCode.permission: ConversationNotice.micDenied,
      RecognitionErrorCode.audio: ConversationNotice.generic,
      RecognitionErrorCode.client: ConversationNotice.generic,
      RecognitionErrorCode.unknown: ConversationNotice.generic,
    };
    for (final MapEntry(key: code, value: notice) in expected.entries) {
      await controller().startTurn(Speaker.me);
      recognizer.emit(RecognitionError(code));
      await flush();
      expect(state().notice, notice, reason: '$code');
    }
  });

  test('a second start while listening is ignored; stop asks for the final; cancel drops the card', () async {
    await controller().startTurn(Speaker.other);
    await controller().startTurn(Speaker.me);
    expect(recognizer.started, ['hi-IN']);

    await controller().stopTurn();
    expect(recognizer.stops, 1);
    expect(state().activeSpeaker, Speaker.other, reason: 'still waiting for the final result');

    await controller().cancelTurn();
    expect(recognizer.cancels, 1);
    expect(state().segments, isEmpty);
    expect(state().activeSpeaker, isNull);
  });

  testWidgets('going to the background cancels an active turn', (tester) async {
    await tester.runAsync(() => controller().startTurn(Speaker.other));
    expect(state().activeSpeaker, Speaker.other);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(recognizer.cancels, greaterThanOrEqualTo(1));
    expect(state().activeSpeaker, isNull);
    expect(state().segments, isEmpty);
    // Back to the foreground through valid transitions.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  test('disposing the controller cancels the recognizer', () async {
    await controller().startTurn(Speaker.other);
    keepAlive.close();
    container.dispose();
    expect(recognizer.cancels, 1);
    container = build(); // for tearDown
  });

  test('a translation arriving after dispose is ignored without errors', () async {
    await controller().startTurn(Speaker.other);
    final id = state().segments.single.id;
    cloud.gates[id] = Completer<void>();
    recognizer.emit(const FinalResult('आप कहाँ हैं?'));
    await flush();
    keepAlive.close();
    container.dispose();
    cloud.gates[id]!.complete();
    await flush(); // must not throw "used after dispose"
    container = build();
  });

  group('speaking', () {
    Future<String> translatedTurn(Speaker speaker, String text) async {
      await controller().startTurn(speaker);
      final id = state().segments.last.id;
      recognizer.emit(FinalResult(text));
      await flush();
      return id;
    }

    Segment seg(String id) => state().segments.firstWhere((s) => s.id == id);

    test("a listen turn's translation plays for me in the earphones", () async {
      audio.connected = [fakeSpeaker, fakeWired];
      final id = await translatedTurn(Speaker.other, 'आप कहाँ जा रहे हैं?');
      expect(audio.calls, contains('play:$id:${fakeWired.id}'));
      expect(seg(id).speech, SpeechStatus.preparing);
      expect(File(audio.playedPaths.single).existsSync(), isTrue);

      audio.emit(PlaybackStarted(id, fakeWired));
      await flush();
      expect(seg(id).speech, SpeechStatus.playing);
      expect(seg(id).output, fakeWired);
      audio.emit(PlaybackCompleted(id));
      await flush();
      expect(seg(id).speech, SpeechStatus.played);
    });

    test("a speak turn's translation plays on the speaker", () async {
      audio.connected = [fakeSpeaker, fakeBuds];
      final id = await translatedTurn(Speaker.me, "I'm going to the office.");
      expect(audio.calls, contains('play:$id:${fakeSpeaker.id}'));
      expect(synth.synthesizedPaths.single, endsWith('$id.wav'));
    });

    test('starting a turn stops playback before the recognizer starts', () async {
      final id = await translatedTurn(Speaker.other, 'नमस्ते');
      audio.emit(PlaybackStarted(id, fakeSpeaker));
      await flush();
      final log = <String>[];
      audio.sharedLog = log;
      recognizer.sharedLog = log;
      await controller().startTurn(Speaker.me);
      expect(log, ['stop', 'start:en-IN']);
      expect(seg(id).speech, SpeechStatus.played);
    });

    test('late events for an old playback are ignored', () async {
      final first = await translatedTurn(Speaker.other, 'पहला');
      audio.emit(PlaybackStarted(first, fakeSpeaker));
      await flush();
      final second = await translatedTurn(Speaker.other, 'दूसरा');
      audio.emit(PlaybackStarted(second, fakeSpeaker));
      audio.emit(PlaybackCompleted(first)); // late, for the interrupted playback
      audio.emit(PlaybackFailed(first, '1:-1'));
      await flush();
      expect(seg(second).speech, SpeechStatus.playing);
      expect(seg(first).speech, SpeechStatus.played);
      expect(state().notice, isNull);
    });

    test("a late translation of an older segment doesn't play over a newer one", () async {
      cloud.reply = (r) => 'EN:${r.text}';
      await controller().startTurn(Speaker.other);
      final older = state().segments.last.id;
      cloud.gates[older] = Completer<void>();
      recognizer.emit(const FinalResult('पहला'));
      await flush();
      final newer = await translatedTurn(Speaker.other, 'दूसरा');
      expect(audio.calls.where((c) => c.startsWith('play:')), ['play:$newer:${fakeSpeaker.id}']);

      cloud.gates[older]!.complete();
      await flush();
      expect(audio.calls.where((c) => c.startsWith('play:$older')), isEmpty);
      expect(seg(older).speech, SpeechStatus.none);
    });

    test('a missing voice marks the segment noVoice and nothing plays', () async {
      synth.availabilityByLocale['en-IN'] = VoiceAvailability.needsDownload;
      final id = await translatedTurn(Speaker.other, 'नमस्ते');
      expect(seg(id).speech, SpeechStatus.noVoice);
      expect(audio.calls.where((c) => c.startsWith('play:')), isEmpty);
      expect(synth.synthesizedPaths, isEmpty);
    });

    test('earphones disconnecting shows the notice, sounds the tone on the speaker, and the next translation uses the speaker',
        () async {
      audio.connected = [fakeSpeaker, fakeBuds];
      final first = await translatedTurn(Speaker.other, 'पहला');
      expect(audio.calls, contains('play:$first:${fakeBuds.id}'));
      audio.emit(PlaybackStarted(first, fakeBuds));
      audio.emit(PlaybackCompleted(first));
      await flush();

      audio.setOutputs([fakeSpeaker]);
      await flush();
      expect(state().notice, ConversationNotice.earphonesDisconnected);
      expect(audio.calls, contains('tone:${fakeSpeaker.id}'));

      final second = await translatedTurn(Speaker.other, 'दूसरा');
      expect(audio.calls, contains('play:$second:${fakeSpeaker.id}'));
    });

    test('the reply landing on earphones while a speaker exists shows speakerUnavailable with the device', () async {
      audio.connected = [fakeSpeaker, fakeBuds];
      final id = await translatedTurn(Speaker.me, 'Hello');
      expect(audio.calls, contains('play:$id:${fakeSpeaker.id}'));
      audio.emit(PlaybackStarted(id, fakeBuds));
      await flush();
      expect(state().notice, ConversationNotice.speakerUnavailable);
      expect(state().noticeOutput, fakeBuds);
      expect(seg(id).output, fakeBuds);
    });

    test('losing audio focus ends playback', () async {
      final id = await translatedTurn(Speaker.other, 'नमस्ते');
      audio.emit(PlaybackStarted(id, fakeSpeaker));
      audio.emit(PlaybackFocusLost(id));
      await flush();
      expect(seg(id).speech, SpeechStatus.played);
      expect(state().notice, isNull);
    });

    test('playback failure shows the notice and replay succeeds', () async {
      audio.playError = Exception('playbackFailed');
      final id = await translatedTurn(Speaker.other, 'नमस्ते');
      expect(seg(id).speech, SpeechStatus.failed);
      expect(state().notice, ConversationNotice.playbackFailed);

      audio.playError = null;
      await controller().replay(id);
      await flush();
      expect(audio.calls.where((c) => c == 'play:$id:${fakeSpeaker.id}'), hasLength(2));
      expect(synth.synthesizedPaths, hasLength(1), reason: 'replay reuses the file');
      expect(seg(id).speech, SpeechStatus.preparing);

      audio.emit(PlaybackFailed(id, '1:-1004'));
      await flush();
      expect(seg(id).speech, SpeechStatus.failed);
      expect(state().notice, ConversationNotice.playbackFailed);
    });

    testWidgets('going to the background stops playback', (tester) async {
      final id = await tester.runAsync(() => translatedTurn(Speaker.other, 'नमस्ते'));
      audio.emit(PlaybackStarted(id!, fakeSpeaker));
      await tester.runAsync(flush);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.runAsync(flush);
      expect(audio.calls.last, 'stop');
      expect(seg(id).speech, SpeechStatus.played);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });

    test('disposing stops playback and deletes synthesized files', () async {
      final id = await translatedTurn(Speaker.other, 'नमस्ते');
      audio.emit(PlaybackStarted(id, fakeSpeaker));
      await flush();
      final path = audio.playedPaths.single;
      expect(File(path).existsSync(), isTrue);
      keepAlive.close();
      container.dispose();
      await flush();
      expect(audio.calls.last, 'stop');
      expect(File(path).existsSync(), isFalse);
      container = build();
    });

    test('installVoice opens the installer and re-checks availability', () async {
      synth.availabilityByLocale['en-IN'] = VoiceAvailability.needsDownload;
      final id = await translatedTurn(Speaker.other, 'नमस्ते');
      expect(seg(id).speech, SpeechStatus.noVoice);

      await controller().installVoice('en-IN');
      expect(synth.installsOpened, 1);
      synth.availabilityByLocale['en-IN'] = VoiceAvailability.available;
      await controller().replay(id);
      await flush();
      expect(audio.calls, contains('play:$id:${fakeSpeaker.id}'));
      expect(synth.availabilityChecks, 2);
    });

    test('earphones disconnecting mid-playback skips the tone, and the card follows Android to the speaker', () async {
      audio.connected = [fakeSpeaker, fakeBuds];
      final id = await translatedTurn(Speaker.other, 'नमस्ते');
      audio.emit(PlaybackStarted(id, fakeBuds));
      await flush();

      audio.setOutputs([fakeSpeaker]);
      await flush();
      expect(state().notice, ConversationNotice.earphonesDisconnected);
      expect(audio.calls.where((c) => c.startsWith('tone:')), isEmpty,
          reason: 'a tone would cut the translation off; the translation itself, now on the speaker, is the cue');
      expect(seg(id).speech, SpeechStatus.playing);

      audio.emit(PlaybackStarted(id, fakeSpeaker)); // Android moved the rest of it
      await flush();
      expect(seg(id).output, fakeSpeaker);
      expect(seg(id).speech, SpeechStatus.playing);
      audio.emit(PlaybackCompleted(id));
      await flush();
      expect(seg(id).speech, SpeechStatus.played);
    });

    test('Android moving playback off the earphones before the device list changes still shows the notice', () async {
      audio.connected = [fakeSpeaker, fakeBuds];
      final id = await translatedTurn(Speaker.other, 'नमस्ते');
      audio.emit(PlaybackStarted(id, fakeBuds));
      audio.emit(PlaybackStarted(id, fakeSpeaker));
      await flush();
      audio.setOutputs([fakeSpeaker]);
      await flush();
      expect(state().notice, ConversationNotice.earphonesDisconnected);
    });

    test('a turn started while outputs are being listed never plays over the microphone', () async {
      final log = <String>[];
      audio.sharedLog = log;
      recognizer.sharedLog = log;
      audio.outputsGate = Completer<void>();
      await controller().startTurn(Speaker.other);
      final id = state().segments.last.id;
      recognizer.emit(const FinalResult('नमस्ते'));
      await flush(); // translated and voiced; now waiting for the output list

      final turn = controller().startTurn(Speaker.me);
      await flush();
      audio.outputsGate!.complete();
      await turn;
      await flush();
      expect(log.where((e) => e.startsWith('play:')), isEmpty, reason: '$log');
      expect(seg(id).speech, SpeechStatus.none, reason: 'Replay plays it later');
    });

    testWidgets('a reply still being translated when the app is hidden is not spoken', (tester) async {
      late String id;
      await tester.runAsync(() async {
        await controller().startTurn(Speaker.me);
        id = state().segments.last.id;
        cloud.gates[id] = Completer<void>();
        recognizer.emit(const FinalResult('Hello'));
        await flush();
      });
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.runAsync(() async {
        cloud.gates[id]!.complete();
        await flush();
      });
      expect(audio.calls.where((c) => c.startsWith('play:')), isEmpty);
      expect(seg(id).speech, SpeechStatus.none);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.runAsync(() async {
        await controller().replay(id);
        await flush();
      });
      expect(audio.calls, contains('play:$id:${fakeSpeaker.id}'), reason: 'back in the app, Replay plays it');
    });

    testWidgets('a reply still being voiced when the app is hidden is not spoken', (tester) async {
      synth.gates['Where are you going today?'] = Completer<void>();
      final id = await tester.runAsync(() => translatedTurn(Speaker.me, 'Hello'));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.runAsync(() async {
        synth.gates['Where are you going today?']!.complete();
        await flush();
      });
      expect(audio.calls.where((c) => c.startsWith('play:')), isEmpty);
      expect(seg(id!).speech, SpeechStatus.none);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });

    test('a reply set to Earphones on purpose does not claim the speaker failed', () async {
      audio.connected = [fakeSpeaker, fakeBuds];
      await container.read(outputPreferencesProvider.notifier).select(OutputRole.forOther, OutputPreference.earphones);
      final id = await translatedTurn(Speaker.me, 'Hello');
      expect(audio.calls, contains('play:$id:${fakeBuds.id}'));
      audio.emit(PlaybackStarted(id, fakeBuds));
      await flush();
      expect(state().notice, isNull);
      expect(seg(id).output, fakeBuds);
    });

    test('a missing voice is checked again on the next translation', () async {
      synth.availabilityByLocale['en-IN'] = VoiceAvailability.needsDownload;
      final first = await translatedTurn(Speaker.other, 'पहला');
      expect(seg(first).speech, SpeechStatus.noVoice);

      synth.availabilityByLocale['en-IN'] = VoiceAvailability.available; // downloaded in Android's settings
      final second = await translatedTurn(Speaker.other, 'दूसरा');
      expect(audio.calls, contains('play:$second:${fakeSpeaker.id}'));
    });

    test('opening a conversation deletes voice files left by an earlier one', () async {
      keepAlive.close();
      container.dispose();
      await flush();
      final leftover = File('${cache.path}${Platform.pathSeparator}tts${Platform.pathSeparator}old.wav')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('wav');
      container = build();
      await flush();
      expect(leftover.existsSync(), isFalse);
    });

    test('a voice finished after the conversation closed is deleted', () async {
      synth.gates['Where are you going today?'] = Completer<void>();
      final id = await translatedTurn(Speaker.other, 'नमस्ते');
      keepAlive.close();
      container.dispose();
      await flush();
      synth.gates['Where are you going today?']!.complete();
      await flush();
      final file = File('${cache.path}${Platform.pathSeparator}tts${Platform.pathSeparator}$id.wav');
      expect(file.existsSync(), isFalse);
      container = build();
    });
  });
}
