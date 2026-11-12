import 'dart:io';

import 'package:anuvaad/core/permissions/microphone_permission.dart';
import 'package:anuvaad/core/settings/settings_providers.dart';
import 'package:anuvaad/features/app_update/application/update_controller.dart' show clockProvider;
import 'package:anuvaad/features/conversation/application/conversation_controller.dart';
import 'package:anuvaad/features/conversation/application/translation_service.dart';
import 'package:anuvaad/features/conversation/application/voice_service.dart';
import 'package:anuvaad/features/conversation/data/android_audio.dart';
import 'package:anuvaad/features/conversation/data/android_speech_recognizer.dart';
import 'package:anuvaad/features/conversation/data/offline_models.dart';
import 'package:anuvaad/features/conversation/domain/audio_output.dart';
import 'package:anuvaad/features/conversation/domain/segment.dart';
import 'package:anuvaad/features/conversation/domain/speech_recognition.dart';
import 'package:anuvaad/features/conversation/domain/translation.dart';
import 'package:anuvaad/features/language_settings/application/language_preferences_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'conversation_fakes.dart';

/// A ProviderContainer wired with every conversation fake, for controller-level tests.
class ConversationHarness {
  late FakeSpeechRecognizer recognizer;
  late FakeTranslator cloud;
  late FakeTranslator offline;
  late FakeMicrophonePermission mic;
  late CountingOfflineModels models;
  late FakeAudioOutput audio;
  late FakeSpeechSynth synth;
  late Directory cache;
  late SharedPreferences prefs;
  late ProviderContainer container;
  ProviderSubscription<ConversationState>? _keepAlive;

  DateTime now = DateTime(2026, 11, 6, 10);

  /// How long a playback may go without reporting before it no longer blocks listening.
  Duration watchdog = const Duration(seconds: 30);

  /// Extra overrides for the next [build].
  List<Override> overrides = const [];

  String my = 'en-IN';
  String other = 'hi-IN';

  Future<void> setUp({Map<String, Object> initialPrefs = const {}}) async {
    now = DateTime(2026, 11, 6, 10);
    watchdog = const Duration(seconds: 30);
    overrides = const [];
    my = 'en-IN';
    other = 'hi-IN';
    SharedPreferences.setMockInitialValues(initialPrefs);
    prefs = await SharedPreferences.getInstance();
    audio = FakeAudioOutput(connected: [fakeSpeaker]);
    synth = FakeSpeechSynth();
    cache = Directory.systemTemp.createTempSync('anuvaad_session_test');
    recognizer = FakeSpeechRecognizer();
    cloud = FakeTranslator(reply: (r) => 'EN:${r.text}');
    offline = FakeTranslator(provenance: TranslationProvenance.offline, provider: 'mlkit');
    mic = FakeMicrophonePermission();
    models = CountingOfflineModels();
    container = build();
  }

  ProviderContainer build() {
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
      playbackWatchdogProvider.overrideWithValue(watchdog),
      ...overrides,
    ]);
    _keepAlive = c.listen(conversationControllerProvider, (_, _) {});
    return c;
  }

  /// Disposes the container (as leaving the screen does) without building a new one.
  void close() {
    _keepAlive?.close();
    _keepAlive = null;
    container.dispose();
  }

  /// Rebuilds the container with the current fakes, [overrides] and [watchdog].
  void rebuild() {
    close();
    container = build();
  }

  void tearDown() {
    _keepAlive?.close();
    container.dispose();
    if (cache.existsSync()) cache.deleteSync(recursive: true);
  }

  ConversationController get controller => container.read(conversationControllerProvider.notifier);
  ConversationState get state => container.read(conversationControllerProvider);
  Segment seg(String id) => state.segments.firstWhere((s) => s.id == id);
  Future<void> flush() => pumpEventQueue();

  /// The id of the segment the recognizer is filling now.
  String get activeId => state.segments.lastWhere((s) => !s.isFinal).id;

  /// Says [text] into the active turn and lets translation and synthesis run; returns the segment id.
  Future<String> say(String text) async {
    final id = activeId;
    recognizer.emit(FinalResult(text));
    await flush();
    return id;
  }

  /// Reports that Android started and finished playing [id].
  Future<void> playThrough(String id) async {
    audio.emit(PlaybackStarted(id, fakeSpeaker));
    audio.emit(PlaybackCompleted(id));
    await flush();
  }

  int get starts => recognizer.started.length;
}
