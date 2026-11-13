import 'dart:async';
import 'dart:io';

import 'package:anuvaad/core/platform/screen_awake.dart';
import 'package:anuvaad/shared/transcript_sharer.dart';
import 'package:anuvaad/core/permissions/microphone_permission.dart';
import 'package:anuvaad/features/conversation/data/offline_models.dart';
import 'package:anuvaad/features/conversation/domain/audio_output.dart';
import 'package:anuvaad/features/conversation/domain/conversation_service.dart';
import 'package:anuvaad/features/conversation/domain/speech_recognition.dart';
import 'package:anuvaad/features/conversation/domain/translation.dart';
import 'package:anuvaad/features/conversation/domain/voice.dart';
import 'package:anuvaad/features/language_settings/application/language_preferences_controller.dart';

/// In-memory ML Kit model store. [downloaded] holds BCP codes ('en', 'hi', 'gu').
class FakeOfflineModelStore implements OfflineModelStore {
  FakeOfflineModelStore({Set<String>? downloaded, this.failing = const {}})
      : downloaded = downloaded ?? {'en', 'hi', 'gu'};

  final Set<String> downloaded;

  /// Codes whose download throws.
  final Set<String> failing;

  final List<({String code, bool wifiOnly})> downloads = [];

  @override
  Future<bool> isDownloaded(String bcpCode) async => downloaded.contains(bcpCode);

  @override
  Future<bool> download(String bcpCode, {required bool wifiOnly}) async {
    downloads.add((code: bcpCode, wifiOnly: wifiOnly));
    if (failing.contains(bcpCode)) throw StateError('download failed: $bcpCode');
    downloaded.add(bcpCode);
    return true;
  }
}

/// Counts startup download requests without touching the store.
class CountingOfflineModels extends OfflineModels {
  CountingOfflineModels() : super(FakeOfflineModelStore());

  int ensureCalls = 0;

  @override
  Future<void> ensureDownloaded() async => ensureCalls++;
}

/// Translator double: answers with [reply] (or throws [error]); [gates] hold answers until completed.
class FakeTranslator implements TranslatorPort {
  FakeTranslator({this.provenance = TranslationProvenance.online, this.provider = 'cloudflare', this.reply, this.error});

  final TranslationProvenance provenance;
  final String provider;

  /// Builds the translated text from the request; defaults to the source text plus ' (translated)'.
  String Function(TranslateRequest request)? reply;
  Object? error;

  /// Per-segment gates: the answer for that segment waits until its completer finishes.
  final Map<String, Completer<void>> gates = {};

  /// When set, every answer waits for it (for tests that don't know segment ids).
  Completer<void>? holdAll;
  final List<TranslateRequest> requests = [];

  @override
  Future<Translation> translate(TranslateRequest request) async {
    requests.add(request);
    final gate = gates[request.segmentId];
    if (gate != null) await gate.future;
    final hold = holdAll;
    if (hold != null) await hold.future;
    final failure = error;
    if (failure != null) throw failure;
    return Translation(
      segmentId: request.segmentId,
      text: reply?.call(request) ?? '${request.text} (translated)',
      provenance: provenance,
      provider: provider,
    );
  }
}

/// Speech recognizer double: tests push events with [emit].
class FakeSpeechRecognizer implements SpeechRecognizerPort {
  final _events = StreamController<RecognitionEvent>.broadcast();

  bool available = true;
  bool detectionSupported = false;
  final List<String> started = [];

  /// The detectAmong list of the last start (empty when detection wasn't asked for).
  List<String> startDetectAmong = const [];
  int stops = 0;
  int cancels = 0;

  /// Shared call log with other fakes, to check ordering across ports.
  List<String>? sharedLog;

  void emit(RecognitionEvent event) => _events.add(event);

  @override
  Stream<RecognitionEvent> get events => _events.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> supportsLanguageDetection() async => detectionSupported;

  /// When set, every start is answered with this error straight away (a broken or busy recognizer).
  RecognitionErrorCode? failOnStart;

  @override
  Future<void> start(String locale, {List<String> detectAmong = const []}) async {
    started.add(locale);
    startDetectAmong = detectAmong;
    final fail = failOnStart;
    if (fail != null) scheduleMicrotask(() => emit(RecognitionError(fail)));
    sharedLog?.add('start:$locale');
  }

  @override
  Future<void> stop() async => stops++;

  @override
  Future<void> cancel() async => cancels++;
}

class FakeMicrophonePermission implements MicrophonePermission {
  FakeMicrophonePermission({this.current = MicPermission.granted, this.onRequest = MicPermission.granted});

  MicPermission current;

  /// What the next request returns (and becomes the status when granted).
  MicPermission onRequest;
  int requests = 0;
  int settingsOpened = 0;

  @override
  Future<MicPermission> status() async => current;

  @override
  Future<MicPermission> request() async {
    requests++;
    if (onRequest == MicPermission.granted) current = MicPermission.granted;
    return onRequest;
  }

  @override
  Future<bool> openSettings() async {
    settingsOpened++;
    return true;
  }
}

/// Language preferences without the registry or storage.
class FixedLanguagePreferences extends LanguagePreferencesController {
  FixedLanguagePreferences(this.initial);

  final LanguagePreferences initial;

  @override
  LanguagePreferences build() => initial;
}

const fakeSpeaker = AudioOutput(id: 1, kind: OutputKind.speaker, name: '');
const fakeWired = AudioOutput(id: 2, kind: OutputKind.wired, name: 'Wired headset');
const fakeBuds = AudioOutput(id: 3, kind: OutputKind.bluetooth, name: 'Galaxy Buds');

/// Output device and playback double: records calls; tests push events with [emit] / [setOutputs].
class FakeAudioOutput implements AudioOutputPort {
  FakeAudioOutput({List<AudioOutput>? connected}) : connected = connected ?? [fakeSpeaker];

  final _events = StreamController<AudioEvent>.broadcast();
  List<AudioOutput> connected;

  /// Calls in order: `play:{playbackId}:{deviceId}`, `stop`, `tone:{deviceId}`.
  final List<String> calls = [];
  final List<String> playedPaths = [];
  Object? playError;

  /// Shared call log with other fakes, to check ordering across ports.
  List<String>? sharedLog;

  void emit(AudioEvent event) => _events.add(event);

  void setOutputs(List<AudioOutput> outputs) {
    connected = outputs;
    emit(OutputsChanged(outputs));
  }

  void _log(String entry) {
    calls.add(entry);
    sharedLog?.add(entry);
  }

  @override
  Stream<AudioEvent> get events => _events.stream;

  /// While set and not completed, [outputs] waits for it.
  Completer<void>? outputsGate;

  @override
  Future<List<AudioOutput>> outputs() async {
    final gate = outputsGate;
    if (gate != null) await gate.future;
    return connected;
  }

  @override
  Future<void> play({required String path, required int? deviceId, required String playbackId}) async {
    _log('play:$playbackId:$deviceId');
    playedPaths.add(path);
    final error = playError;
    if (error != null) throw error;
  }

  @override
  Future<void> stop() async => _log('stop');

  @override
  Future<AudioOutput?> playTestTone({required int? deviceId}) async {
    _log('tone:$deviceId');
    for (final output in connected) {
      if (output.id == deviceId) return output;
    }
    return connected.isEmpty ? null : connected.first;
  }
}

/// Text-to-speech double that writes small real files, so cleanup can be checked.
class FakeSpeechSynth implements SpeechSynthPort {
  final Map<String, VoiceAvailability> availabilityByLocale = {};
  final Map<String, List<VoiceOption>> voicesByLocale = {};
  final List<String> synthesizedTexts = [];
  double? lastRate;
  String? lastVoice;
  final List<String> synthesizedPaths = [];
  int availabilityChecks = 0;
  int installsOpened = 0;
  Object? synthesisError;

  /// Per-text gates: synthesis of that text waits until its completer finishes.
  final Map<String, Completer<void>> gates = {};
  Object? availabilityError;

  /// Shared call log with other fakes, to check ordering across ports.
  List<String>? sharedLog;

  @override
  Future<VoiceAvailability> availability(String locale) async {
    availabilityChecks++;
    final error = availabilityError;
    if (error != null) throw error;
    return availabilityByLocale[locale] ?? VoiceAvailability.available;
  }

  @override
  Future<List<VoiceOption>> voices(String locale) async => voicesByLocale[locale] ?? const [];

  @override
  Future<void> synthesize({
    required String text,
    required String locale,
    required String path,
    double rate = 1.0,
    String? voice,
  }) async {
    sharedLog?.add('synthesize:$locale');
    synthesizedTexts.add(text);
    lastRate = rate;
    lastVoice = voice;
    final gate = gates[text];
    if (gate != null) await gate.future;
    final error = synthesisError;
    if (error != null) throw error;
    File(path)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('wav:$locale:$text');
    synthesizedPaths.add(path);
  }

  @override
  Future<bool> openVoiceInstall(String locale) async {
    installsOpened++;
    return true;
  }
}

/// Records whether the screen was asked to stay on.
class FakeScreenAwake implements ScreenAwake {
  bool on = false;
  final List<bool> calls = [];

  @override
  Future<void> keepOn(bool on) async {
    calls.add(on);
    this.on = on;
  }
}

/// Records what would have been handed to Android's share sheet.
class FakeTranscriptSharer implements TranscriptSharer {
  final List<({String text, String fileName})> shared = [];

  @override
  Future<void> shareText(String text, {required String fileName}) async => shared.add((text: text, fileName: fileName));

  int clears = 0;

  @override
  Future<void> clearShared() async => clears++;
}

/// Android's ongoing-conversation service: records starts, notifications and stops; [send] taps a button.
class FakeConversationService implements ConversationServicePort {
  /// False: Android refuses to start it (as it does from the background).
  bool accept = true;
  int startCalls = 0;
  int stops = 0;
  bool running = false;
  bool? earphoneButton;
  String? channelName;

  /// Every notification shown, in order (the one at start first).
  final shown = <SessionNotification>[];
  final _commands = StreamController<SessionCommand>.broadcast();

  SessionNotification? get notification => shown.isEmpty ? null : shown.last;
  List<SessionCommand> get buttons => [for (final a in notification?.actions ?? const <SessionAction>[]) a.command];

  void send(SessionCommand command) => _commands.add(command);

  @override
  Future<bool> start(SessionNotification notification, {required String channelName, required bool earphoneButton}) async {
    startCalls++;
    if (!accept) return false;
    running = true;
    this.channelName = channelName;
    this.earphoneButton = earphoneButton;
    shown.add(notification);
    return true;
  }

  @override
  Future<void> update(SessionNotification notification) async {
    if (running) shown.add(notification);
  }

  @override
  Future<void> stop() async {
    stops++;
    running = false;
  }

  @override
  Stream<SessionCommand> get commands => _commands.stream;
}
