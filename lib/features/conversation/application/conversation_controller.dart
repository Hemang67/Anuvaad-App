import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/permissions/microphone_permission.dart';
import '../../app_update/application/update_controller.dart' show clockProvider;
import '../../language_settings/application/language_preferences_controller.dart';
import '../data/android_audio.dart';
import '../data/android_speech_recognizer.dart';
import '../data/offline_models.dart';
import '../domain/audio_output.dart';
import '../domain/segment.dart';
import '../domain/speech_recognition.dart';
import '../domain/translation.dart';
import '../domain/voice.dart';
import 'output_router.dart';
import 'translation_service.dart';
import 'voice_service.dart';

/// A message the conversation screen shows above the Listen/Speak buttons.
enum ConversationNotice {
  chooseOtherLanguage,
  micDenied,
  micPermanentlyDenied,
  recognizerUnavailable,
  noSpeech,
  network,
  languageUnsupported,
  busy,
  generic,
  earphonesDisconnected,
  speakerUnavailable,
  playbackFailed,
}

class ConversationState {
  const ConversationState({
    this.segments = const [],
    this.activeSpeaker,
    this.notice,
    this.noticeLanguage,
    this.noticeOutput,
    this.otherLanguageOverride,
  });

  /// In creation order (oldest first).
  final List<Segment> segments;

  /// Who is speaking now; null when no turn is active.
  final Speaker? activeSpeaker;
  final ConversationNotice? notice;

  /// The language a [ConversationNotice.languageUnsupported] notice is about.
  final String? noticeLanguage;

  /// The device a [ConversationNotice.speakerUnavailable] notice is about.
  final AudioOutput? noticeOutput;

  /// The other person's language picked on this screen when Settings says Automatic.
  final String? otherLanguageOverride;

  static const _keep = Object();

  ConversationState copyWith({
    List<Segment>? segments,
    Object? activeSpeaker = _keep,
    Object? notice = _keep,
    Object? noticeLanguage = _keep,
    Object? noticeOutput = _keep,
    Object? otherLanguageOverride = _keep,
  }) =>
      ConversationState(
        segments: segments ?? this.segments,
        activeSpeaker: identical(activeSpeaker, _keep) ? this.activeSpeaker : activeSpeaker as Speaker?,
        notice: identical(notice, _keep) ? this.notice : notice as ConversationNotice?,
        noticeLanguage: identical(noticeLanguage, _keep) ? this.noticeLanguage : noticeLanguage as String?,
        noticeOutput: identical(noticeOutput, _keep) ? this.noticeOutput : noticeOutput as AudioOutput?,
        otherLanguageOverride:
            identical(otherLanguageOverride, _keep) ? this.otherLanguageOverride : otherLanguageOverride as String?,
      );
}

/// Turns recognizer events into ordered segments, translates each finished one and speaks the translation
/// on the right output (spec §3.3).
class ConversationController extends Notifier<ConversationState> {
  static const _uuid = Uuid();

  late SpeechRecognizerPort _recognizer;
  StreamSubscription<RecognitionEvent>? _events;
  AppLifecycleListener? _lifecycle;

  /// The segment the recognizer is currently filling.
  String? _activeId;
  bool _starting = false;

  /// Android reports a permanent denial only in answer to a request, so remember it for this session.
  bool _micBlocked = false;
  int _seq = 0;

  late AudioOutputPort _audio;
  late VoiceService _voice;
  StreamSubscription<AudioEvent>? _audioEvents;

  /// The playback Android is running now, and who it is for.
  ({String id, OutputRole role})? _playing;

  /// Highest segment seq auto-played so far: an older segment's late translation never plays over a newer one.
  int _lastSpokenSeq = 0;

  /// Synthesized files by segment, for Replay.
  final _paths = <String, String>{};

  /// Whether the last translation for you played in earphones (to notice them disconnecting).
  bool _forMeOnEarphones = false;
  List<AudioOutput> _outputs = const [];

  @override
  ConversationState build() {
    final recognizer = _recognizer = ref.watch(speechRecognizerProvider);
    _events = recognizer.events.listen(_onEvent);
    final audio = _audio = ref.watch(audioOutputProvider);
    final voice = _voice = ref.watch(voiceServiceProvider);
    _audioEvents = audio.events.listen(_onAudio);
    // Backgrounding releases the microphone (spec §0.4).
    _lifecycle = AppLifecycleListener(onHide: _onBackground, onPause: _onBackground);
    ref.onDispose(() {
      if (_activeId != null) unawaited(recognizer.cancel());
      _activeId = null;
      // Leaving the screen ends playback and deletes the synthesized files.
      unawaited(audio.stop());
      unawaited(voice.clear());
      _events?.cancel();
      _audioEvents?.cancel();
      _lifecycle?.dispose();
    });
    return const ConversationState();
  }

  DateTime _now() => ref.read(clockProvider)();

  /// The other person's language, or null while it is Automatic and not yet picked here.
  String? _otherLanguage() {
    final other = state.otherLanguageOverride ?? ref.read(languagePreferencesProvider).otherLanguage;
    return other == autoDetect ? null : other;
  }

  Future<void> startTurn(Speaker speaker) async {
    if (_activeId != null || _starting) return;
    final my = ref.read(languagePreferencesProvider).myLanguage;
    final other = _otherLanguage();
    if (other == null) {
      state = state.copyWith(notice: ConversationNotice.chooseOtherLanguage, noticeLanguage: null);
      return;
    }
    final source = speaker == Speaker.other ? other : my;
    final target = speaker == Speaker.other ? my : other;

    _starting = true;
    try {
      state = state.copyWith(notice: null, noticeLanguage: null);
      // The microphone never opens over a translation that is playing (R29).
      await stopSpeaking();
      if (!ref.mounted || !await _ensureMicrophone() || !ref.mounted) return;
      if (!await _recognizer.isAvailable()) {
        if (ref.mounted) state = state.copyWith(notice: ConversationNotice.recognizerUnavailable);
        return;
      }
      if (!ref.mounted) return;
      final segment = Segment(
        id: _uuid.v4(),
        seq: ++_seq,
        speaker: speaker,
        sourceLanguage: source,
        targetLanguage: target,
        startedAt: _now(),
      );
      _activeId = segment.id;
      state = state.copyWith(segments: [...state.segments, segment], activeSpeaker: speaker);
      try {
        await _recognizer.start(source);
      } catch (error) {
        debugPrint('Speech recognizer failed to start: $error');
        _drop(segment.id, ConversationNotice.generic);
      }
    } finally {
      _starting = false;
    }
  }

  /// Ends listening; the recognizer then sends its final result.
  Future<void> stopTurn() async {
    if (_activeId == null) return;
    await _recognizer.stop();
  }

  /// Ends listening and discards the unfinished card.
  Future<void> cancelTurn() async {
    final id = _activeId;
    if (id == null) return;
    _activeId = null;
    state = state.copyWith(
      segments: [for (final s in state.segments) if (s.id != id || s.isFinal) s],
      activeSpeaker: null,
    );
    await _recognizer.cancel();
  }

  void chooseOtherLanguage(String code) {
    if (code == ref.read(languagePreferencesProvider).myLanguage) return;
    state = state.copyWith(otherLanguageOverride: code, notice: null, noticeLanguage: null);
  }

  Future<void> retryTranslation(String segmentId) async {
    final segment = _segment(segmentId);
    if (segment == null || segment.status != SegmentStatus.failed) return;
    // The card asked for Wi-Fi: try the model download again (Wi-Fi only; skips models already present).
    if (segment.offlineNotReady) unawaited(ref.read(offlineModelsProvider).ensureDownloaded());
    _update(segmentId, (s) => s.copyWith(status: SegmentStatus.translating, offlineNotReady: false));
    await _translate(segmentId);
  }

  /// The notice's "Allow" button: ask for the microphone again.
  Future<void> allowMicrophone() async {
    final granted = _afterRequest(await ref.read(microphonePermissionProvider).request());
    if (granted && ref.mounted) state = state.copyWith(notice: null);
  }

  /// The notice's "Open settings" button, for a permanent denial.
  Future<void> openMicrophoneSettings() => ref.read(microphonePermissionProvider).openSettings();

  void dismissNotice() => state = state.copyWith(notice: null, noticeLanguage: null);

  Future<bool> _ensureMicrophone() async {
    final mic = ref.read(microphonePermissionProvider);
    final status = await mic.status();
    if (status == MicPermission.granted) {
      _micBlocked = false;
      return true;
    }
    if (status == MicPermission.permanentlyDenied || _micBlocked) {
      if (ref.mounted) state = state.copyWith(notice: ConversationNotice.micPermanentlyDenied);
      return false;
    }
    return _afterRequest(await mic.request());
  }

  bool _afterRequest(MicPermission result) {
    if (result == MicPermission.granted) {
      _micBlocked = false;
      return true;
    }
    if (result == MicPermission.permanentlyDenied) _micBlocked = true;
    if (ref.mounted) {
      state = state.copyWith(
        notice: result == MicPermission.permanentlyDenied
            ? ConversationNotice.micPermanentlyDenied
            : ConversationNotice.micDenied,
      );
    }
    return false;
  }

  void _onBackground() {
    unawaited(cancelTurn());
    unawaited(stopSpeaking());
  }

  void _onEvent(RecognitionEvent event) {
    final id = _activeId;
    if (id == null || !ref.mounted) return; // late events after stop/cancel, or a duplicate final
    switch (event) {
      case PartialResult(:final text):
        _update(id, (s) => s.copyWith(text: text));
      case FinalResult(:final text) when text.trim().isNotEmpty:
        _finalize(id, text.trim());
      case FinalResult():
        _drop(id, ConversationNotice.noSpeech);
      case RecognitionError(:final code):
        final partial = _segment(id)?.text.trim() ?? '';
        if (partial.isNotEmpty) {
          _finalize(id, partial); // keep what was heard before the error
        } else {
          final language = code == RecognitionErrorCode.languageUnsupported || code == RecognitionErrorCode.languageUnavailable
              ? _segment(id)?.sourceLanguage
              : null;
          _drop(id, _noticeFor(code), language: language);
        }
      case RecognitionReady() || EndOfSpeech():
        break;
    }
  }

  static ConversationNotice _noticeFor(RecognitionErrorCode code) => switch (code) {
        RecognitionErrorCode.noMatch || RecognitionErrorCode.speechTimeout => ConversationNotice.noSpeech,
        RecognitionErrorCode.network || RecognitionErrorCode.server => ConversationNotice.network,
        RecognitionErrorCode.busy => ConversationNotice.busy,
        RecognitionErrorCode.permission => ConversationNotice.micDenied,
        RecognitionErrorCode.languageUnsupported ||
        RecognitionErrorCode.languageUnavailable =>
          ConversationNotice.languageUnsupported,
        RecognitionErrorCode.audio || RecognitionErrorCode.client || RecognitionErrorCode.unknown => ConversationNotice.generic,
      };

  void _finalize(String id, String text) {
    _activeId = null;
    state = state.copyWith(
      segments: [
        for (final s in state.segments)
          s.id == id ? s.copyWith(text: text, isFinal: true, status: SegmentStatus.translating, finalAt: _now()) : s,
      ],
      activeSpeaker: null,
    );
    unawaited(_translate(id));
  }

  void _drop(String id, ConversationNotice notice, {String? language}) {
    _activeId = null;
    state = state.copyWith(
      segments: [for (final s in state.segments) if (s.id != id) s],
      activeSpeaker: null,
      notice: notice,
      noticeLanguage: language,
    );
  }

  Future<void> _translate(String id) async {
    final segment = _segment(id);
    if (segment == null) return;
    final service = ref.read(translationServiceProvider);
    try {
      final translation = await service.translate(TranslateRequest(
        segmentId: id,
        text: segment.text,
        sourceLanguage: segment.sourceLanguage,
        targetLanguage: segment.targetLanguage,
      ));
      if (!ref.mounted) return;
      _update(id, (s) => s.copyWith(
            translation: translation,
            status: SegmentStatus.translated,
            offlineNotReady: false,
            translatedAt: _now(),
          ));
      unawaited(_speak(id, auto: true));
    } on TranslationUnavailable catch (e) {
      if (ref.mounted) _update(id, (s) => s.copyWith(status: SegmentStatus.failed, offlineNotReady: e.offlineNotReady));
    } catch (error) {
      debugPrint('Translation failed: $error');
      if (ref.mounted) _update(id, (s) => s.copyWith(status: SegmentStatus.failed));
    }
  }

  /// Plays a segment's translation again (the card's Replay button).
  Future<void> replay(String segmentId) async {
    final segment = _segment(segmentId);
    if (segment == null || segment.translation == null || segment.speech == SpeechStatus.preparing) return;
    await _speak(segmentId, auto: false);
  }

  /// Stops any translation that is playing; returns once Android has stopped it.
  Future<void> stopSpeaking() async {
    final playing = _playing;
    _playing = null;
    await _audio.stop();
    if (playing != null && ref.mounted) _update(playing.id, (s) => s.copyWith(speech: SpeechStatus.played));
  }

  /// The no-voice card's "Install voice" button.
  Future<void> installVoice(String language) => _voice.installVoice(language);

  OutputRole _roleOf(Segment segment) => segment.speaker == Speaker.other ? OutputRole.forMe : OutputRole.forOther;

  /// Whether an automatic playback may start now: never over an open microphone or a newer segment's speech.
  bool _mayAutoPlay(Segment segment) => _activeId == null && !_starting && segment.seq >= _lastSpokenSeq;

  Future<void> _speak(String id, {required bool auto}) async {
    final segment = _segment(id);
    final translation = segment?.translation;
    if (segment == null || translation == null) return;
    if (auto && !_mayAutoPlay(segment)) return; // stays SpeechStatus.none; Replay plays it
    if (!auto && (_activeId != null || _starting)) return;
    if (auto) _lastSpokenSeq = segment.seq;
    _update(id, (s) => s.copyWith(speech: SpeechStatus.preparing));

    final String path;
    try {
      final cached = _paths[id];
      path = cached != null && File(cached).existsSync()
          ? cached
          : await _voice.synthesize(segmentId: id, text: translation.text, language: segment.targetLanguage);
    } on VoiceMissing {
      if (ref.mounted) _update(id, (s) => s.copyWith(speech: SpeechStatus.noVoice));
      return;
    } catch (error) {
      debugPrint('Speech synthesis failed: $error');
      if (ref.mounted) _speechFailed(id);
      return;
    }
    if (!ref.mounted) return;
    _paths[id] = path;
    // The user may have started a turn while the voice was being prepared.
    if (_activeId != null || _starting) {
      _update(id, (s) => s.copyWith(speech: SpeechStatus.none));
      return;
    }

    final role = _roleOf(segment);
    final List<AudioOutput> outputs;
    try {
      outputs = await _audio.outputs();
    } catch (error) {
      debugPrint('Could not list outputs: $error');
      if (ref.mounted) _speechFailed(id);
      return;
    }
    if (!ref.mounted) return;
    _outputs = outputs;
    final target = resolveOutput(role, ref.read(outputPreferencesProvider)[role]!, outputs);

    final previous = _playing;
    if (previous != null && previous.id != id) _update(previous.id, (s) => s.copyWith(speech: SpeechStatus.played));
    _playing = (id: id, role: role);
    try {
      await _audio.play(path: path, deviceId: target?.id, playbackId: id);
    } catch (error) {
      debugPrint('Playback failed to start: $error');
      if (ref.mounted && _playing?.id == id) {
        _playing = null;
        _speechFailed(id);
      }
    }
  }

  void _speechFailed(String id) {
    _update(id, (s) => s.copyWith(speech: SpeechStatus.failed));
    state = state.copyWith(notice: ConversationNotice.playbackFailed, noticeLanguage: null, noticeOutput: null);
  }

  void _onAudio(AudioEvent event) {
    if (!ref.mounted) return;
    switch (event) {
      case OutputsChanged(:final outputs):
        _outputs = outputs;
        if (_forMeOnEarphones && !outputs.any((o) => o.isEarphones)) {
          _forMeOnEarphones = false;
          state = state.copyWith(notice: ConversationNotice.earphonesDisconnected, noticeLanguage: null, noticeOutput: null);
          // An audible cue too (R09): the user may not be looking at the screen.
          final speaker = outputs.where((o) => o.kind == OutputKind.speaker).firstOrNull;
          unawaited(_audio.playTestTone(deviceId: speaker?.id).catchError((Object _) => null));
        }
      case PlaybackStarted(:final playbackId, :final routed):
        final playing = _playing;
        if (playing == null || playing.id != playbackId) return; // a late event for an interrupted playback
        _update(playbackId, (s) => s.copyWith(speech: SpeechStatus.playing, output: routed));
        if (playing.role == OutputRole.forMe) _forMeOnEarphones = routed.isEarphones;
        final speakerExists = _outputs.any((o) => o.kind == OutputKind.speaker);
        if (playing.role == OutputRole.forOther && routed.kind != OutputKind.speaker && speakerExists) {
          state = state.copyWith(notice: ConversationNotice.speakerUnavailable, noticeLanguage: null, noticeOutput: routed);
        }
      case PlaybackCompleted(:final playbackId) || PlaybackFocusLost(:final playbackId):
        if (_playing?.id != playbackId) return;
        _playing = null;
        _update(playbackId, (s) => s.copyWith(speech: SpeechStatus.played));
      case PlaybackFailed(:final playbackId):
        if (_playing?.id != playbackId) return;
        _playing = null;
        _speechFailed(playbackId);
    }
  }

  Segment? _segment(String id) {
    for (final s in state.segments) {
      if (s.id == id) return s;
    }
    return null;
  }

  void _update(String id, Segment Function(Segment) change) {
    state = state.copyWith(segments: [for (final s in state.segments) s.id == id ? change(s) : s]);
  }
}

final conversationControllerProvider =
    NotifierProvider.autoDispose<ConversationController, ConversationState>(ConversationController.new);
