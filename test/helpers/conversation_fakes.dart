import 'dart:async';

import 'package:anuvaad/core/permissions/microphone_permission.dart';
import 'package:anuvaad/features/conversation/data/offline_models.dart';
import 'package:anuvaad/features/conversation/domain/speech_recognition.dart';
import 'package:anuvaad/features/conversation/domain/translation.dart';
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
  final List<String> started = [];
  int stops = 0;
  int cancels = 0;

  void emit(RecognitionEvent event) => _events.add(event);

  @override
  Stream<RecognitionEvent> get events => _events.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> start(String locale) async => started.add(locale);

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
