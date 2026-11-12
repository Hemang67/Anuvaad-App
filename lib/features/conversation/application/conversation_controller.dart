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
import 'mic_level.dart';
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
  pausedForSilence,
  pausedForInterruption,
}

class ConversationState {
  const ConversationState({
    this.segments = const [],
    this.activeSpeaker,
    this.notice,
    this.noticeLanguage,
    this.noticeOutput,
    this.otherLanguageOverride,
    this.listenMode = false,
    this.paused = false,
    this.ended = false,
    this.sessionStartedAt,
    this.sessionEndedAt,
    this.mode = ConversationMode.inPerson,
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

  /// Continuous Listen is on: a new Listen turn starts each time the last one has been translated and played.
  final bool listenMode;

  /// Stopped by Pause, the app going to the background, silence or an error; Listen resumes.
  final bool paused;

  /// End was tapped: nothing listens or plays any more.
  final bool ended;

  final DateTime? sessionStartedAt;
  final DateTime? sessionEndedAt;
  final ConversationMode mode;

  static const _keep = Object();

  ConversationState copyWith({
    List<Segment>? segments,
    Object? activeSpeaker = _keep,
    Object? notice = _keep,
    Object? noticeLanguage = _keep,
    Object? noticeOutput = _keep,
    Object? otherLanguageOverride = _keep,
    bool? listenMode,
    bool? paused,
    bool? ended,
    Object? sessionStartedAt = _keep,
    Object? sessionEndedAt = _keep,
    ConversationMode? mode,
  }) =>
      ConversationState(
        segments: segments ?? this.segments,
        activeSpeaker: identical(activeSpeaker, _keep) ? this.activeSpeaker : activeSpeaker as Speaker?,
        notice: identical(notice, _keep) ? this.notice : notice as ConversationNotice?,
        noticeLanguage: identical(noticeLanguage, _keep) ? this.noticeLanguage : noticeLanguage as String?,
        noticeOutput: identical(noticeOutput, _keep) ? this.noticeOutput : noticeOutput as AudioOutput?,
        otherLanguageOverride:
            identical(otherLanguageOverride, _keep) ? this.otherLanguageOverride : otherLanguageOverride as String?,
        listenMode: listenMode ?? this.listenMode,
        paused: paused ?? this.paused,
        ended: ended ?? this.ended,
        sessionStartedAt: identical(sessionStartedAt, _keep) ? this.sessionStartedAt : sessionStartedAt as DateTime?,
        sessionEndedAt: identical(sessionEndedAt, _keep) ? this.sessionEndedAt : sessionEndedAt as DateTime?,
        mode: mode ?? this.mode,
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

  /// The playback Android is running now, who it is for, and the kind of output it was sent to.
  ({String id, OutputRole role, OutputKind? target})? _playing;

  /// Bumped whenever speech is stopped: a translation still being prepared from before never starts playing.
  int _speechGen = 0;

  /// False while the app is in the background: nothing starts playing there.
  bool _foreground = true;

  /// Highest segment seq auto-played so far: an older segment's late translation never plays over a newer one.
  int _lastSpokenSeq = 0;

  /// Synthesized files by segment, for Replay.
  final _paths = <String, String>{};

  /// Whether the last translation for you played in earphones (to notice them disconnecting).
  bool _forMeOnEarphones = false;

  /// Ends a playback that never reports back, so it can't block listening for ever.
  Timer? _watchdog;

  /// Above zero while Speak or Replay hands the microphone over: the waiting Listen turn must not come back.
  int _holdRearm = 0;

  /// When speech was last heard in Listen mode; a minute of silence after it pauses the session.
  DateTime? _silenceSince;

  static const _silencePause = Duration(minutes: 1);

  @override
  ConversationState build() {
    final recognizer = _recognizer = ref.watch(speechRecognizerProvider);
    _events = recognizer.events.listen(_onEvent);
    final audio = _audio = ref.watch(audioOutputProvider);
    final voice = _voice = ref.watch(voiceServiceProvider);
    _audioEvents = audio.events.listen(_onAudio);
    // Backgrounding releases the microphone (spec §0.4).
    _lifecycle = AppLifecycleListener(
      onHide: _onBackground,
      onPause: _onBackground,
      onShow: _onForeground,
      onResume: _onForeground,
    );
    // Continuous Listen: when the last turn's work (translate, voice, playback) is done, listen again.
    listenSelf((previous, next) {
      if (previous != null && _busy(previous) && !_busy(next)) scheduleMicrotask(_maybeRearm);
    });
    // Files from a conversation the app never finished closing (killed, swiped away) go now.
    unawaited(voice.sweep().catchError((Object error) => debugPrint('Could not clear old voice files: $error')));
    ref.onDispose(() {
      if (_activeId != null) unawaited(recognizer.cancel());
      _activeId = null;
      _watchdog?.cancel();
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

  /// Starts continuous listening: Listen turns follow each other until Pause, End, silence or an error.
  /// Tapping it stops any translation that is playing, as a single Listen did.
  Future<void> startListening() async {
    if (state.ended) return;
    _silenceSince = _now();
    state = state.copyWith(listenMode: true, paused: false);
    await startTurn(Speaker.other);
  }

  /// Stops the microphone and any playback, and leaves Listen mode until Listen is tapped again.
  Future<void> pause() async {
    if (state.ended) return;
    state = state.copyWith(listenMode: false, paused: true);
    await cancelTurn();
    await stopSpeaking();
  }

  /// One reply turn. A Listen turn still waiting for the other person makes way; Listen mode resumes after the
  /// reply has played.
  Future<void> startSpeaking() async {
    if (state.ended || state.mode == ConversationMode.meeting) return;
    _holdRearm++;
    try {
      if (state.activeSpeaker == Speaker.other) await cancelTurn();
      await startTurn(Speaker.me);
    } finally {
      _holdRearm--;
    }
  }

  /// Ends the conversation: the microphone and playback stop, and nothing starts again.
  Future<void> endSession() async {
    if (state.ended) return;
    state = state.copyWith(listenMode: false, paused: false, ended: true, sessionEndedAt: _now());
    await cancelTurn();
    await stopSpeaking();
  }

  Future<void> startTurn(Speaker speaker) async {
    if (_activeId != null || _starting || state.ended) return;
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
      if (!ref.mounted) return;
      if (!await _ensureMicrophone()) {
        if (ref.mounted) _leaveListenMode(); // never ask again and again for the microphone
        return;
      }
      if (!ref.mounted) return;
      if (!await _recognizer.isAvailable()) {
        if (ref.mounted) {
          state = state.copyWith(notice: ConversationNotice.recognizerUnavailable);
          _leaveListenMode();
        }
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
      state = state.copyWith(
        segments: [...state.segments, segment],
        activeSpeaker: speaker,
        sessionStartedAt: state.sessionStartedAt ?? segment.startedAt,
      );
      try {
        await _recognizer.start(source);
      } catch (error) {
        debugPrint('Speech recognizer failed to start: $error');
        _leaveListenMode();
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
    _setLevel(0);
    state = state.copyWith(
      segments: [for (final s in state.segments) if (s.id != id || s.isFinal) s],
      activeSpeaker: null,
    );
    await _recognizer.cancel();
  }

  void chooseOtherLanguage(String code) {
    if (code == ref.read(languagePreferencesProvider).myLanguage) return;
    state = state.copyWith(otherLanguageOverride: code, notice: null, noticeLanguage: null);
    scheduleMicrotask(_maybeRearm); // Listen mode was waiting for this choice
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
    _foreground = false;
    // A running session pauses (Listen resumes it); otherwise just release the microphone and stop playback.
    if (!state.ended && (state.listenMode || _activeId != null || _playing != null)) {
      unawaited(pause());
    } else {
      unawaited(cancelTurn());
      unawaited(stopSpeaking());
    }
  }

  void _onForeground() => _foreground = true;

  void _onEvent(RecognitionEvent event) {
    final id = _activeId;
    if (id == null || !ref.mounted) return; // late events after stop/cancel, or a duplicate final
    switch (event) {
      case PartialResult(:final text):
        _update(id, (s) => s.copyWith(text: text));
      case FinalResult(:final text) when text.trim().isNotEmpty:
        _finalize(id, text.trim());
      case FinalResult():
        _silence(id);
      case RecognitionError(code: RecognitionErrorCode.noMatch || RecognitionErrorCode.speechTimeout)
          when (_segment(id)?.text.trim() ?? '').isEmpty:
        _silence(id);
      case RecognitionError(:final code):
        final partial = _segment(id)?.text.trim() ?? '';
        // In Listen mode an error would only repeat on the next turn: pause, say why, and let Listen resume.
        final wasListening = state.listenMode;
        _leaveListenMode();
        if (partial.isNotEmpty) {
          _finalize(id, partial); // keep what was heard before the error
          if (wasListening) state = state.copyWith(notice: _noticeFor(code), noticeLanguage: null);
        } else {
          final language = code == RecognitionErrorCode.languageUnsupported || code == RecognitionErrorCode.languageUnavailable
              ? _segment(id)?.sourceLanguage
              : null;
          _drop(id, _noticeFor(code), language: language);
        }
      case SoundLevel(:final level):
        _setLevel(level);
      case RecognitionReady() || EndOfSpeech() || SpeechStarted() || LanguageDetected():
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

  /// Nothing was heard. Outside Listen mode that's a notice; in Listen mode the empty card goes quietly and
  /// listening resumes, until a minute has passed without speech.
  void _silence(String id) {
    if (!state.listenMode) {
      _drop(id, ConversationNotice.noSpeech);
      return;
    }
    final since = _silenceSince ?? _now();
    if (_now().difference(since) >= _silencePause) {
      _leaveListenMode();
      _drop(id, ConversationNotice.pausedForSilence);
    } else {
      _drop(id, null);
    }
  }

  void _finalize(String id, String text) {
    _activeId = null;
    _silenceSince = _now();
    _setLevel(0);
    state = state.copyWith(
      segments: [
        for (final s in state.segments)
          s.id == id ? s.copyWith(text: text, isFinal: true, status: SegmentStatus.translating, finalAt: _now()) : s,
      ],
      activeSpeaker: null,
    );
    unawaited(_translate(id));
  }

  /// Removes an unfinished card. A null [notice] keeps whatever notice is showing.
  void _drop(String id, ConversationNotice? notice, {String? language}) {
    _activeId = null;
    _setLevel(0);
    final segments = [for (final s in state.segments) if (s.id != id) s];
    state = notice == null
        ? state.copyWith(segments: segments, activeSpeaker: null)
        : state.copyWith(segments: segments, activeSpeaker: null, notice: notice, noticeLanguage: language);
  }

  void _setLevel(double level) => ref.read(micLevelProvider.notifier).set(level);

  /// Listen mode stops (it would only fail again); Listen resumes it.
  void _leaveListenMode() {
    if (state.listenMode) state = state.copyWith(listenMode: false, paused: true);
  }

  /// Work that must finish before the microphone may open again: a turn, a translation, a voice, a playback,
  /// a reply under review.
  static bool _busy(ConversationState s) =>
      s.activeSpeaker != null ||
      s.segments.any((x) =>
          x.status == SegmentStatus.translating ||
          x.speech == SpeechStatus.preparing ||
          x.speech == SpeechStatus.playing ||
          x.speech == SpeechStatus.awaitingReview);

  /// Starts the next Listen turn when Listen mode is on and nothing else is going on (R29: never over playback).
  void _maybeRearm() {
    if (!ref.mounted || !state.listenMode || state.paused || state.ended || !_foreground) return;
    if (_holdRearm > 0 || _activeId != null || _starting || _playing != null || _busy(state)) return;
    unawaited(startTurn(Speaker.other));
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
    _holdRearm++;
    try {
      // In Listen mode a turn is usually waiting; if nobody has started talking, it makes way for the replay.
      final active = _activeId;
      if (active != null) {
        if (state.activeSpeaker != Speaker.other || (_segment(active)?.text.isNotEmpty ?? false)) return;
        await cancelTurn();
      }
      await _speak(segmentId, auto: false);
    } finally {
      _holdRearm--;
      scheduleMicrotask(_maybeRearm);
    }
  }

  /// Stops any translation that is playing; returns once Android has stopped it.
  Future<void> stopSpeaking() async {
    _speechGen++;
    final playing = _playing;
    _clearPlaying();
    await _audio.stop();
    if (playing != null && ref.mounted) _update(playing.id, (s) => s.copyWith(speech: SpeechStatus.played));
  }

  /// The no-voice card's "Install voice" button.
  Future<void> installVoice(String language) => _voice.installVoice(language);

  OutputRole _roleOf(Segment segment) => segment.speaker == Speaker.other ? OutputRole.forMe : OutputRole.forOther;

  /// Whether an automatic playback may start now: never over an open microphone or a newer segment's speech.
  bool _mayAutoPlay(Segment segment) =>
      _activeId == null && !_starting && !state.paused && !state.ended && segment.seq >= _lastSpokenSeq;

  /// Checked again just before playing: nothing was stopped meanwhile (a turn, Home), and the microphone is closed.
  bool _mayStillPlay(int generation) => generation == _speechGen && _foreground && _activeId == null && !_starting;

  Future<void> _speak(String id, {required bool auto}) async {
    final segment = _segment(id);
    final translation = segment?.translation;
    if (segment == null || translation == null) return;
    if (auto && !_mayAutoPlay(segment)) return; // stays SpeechStatus.none; Replay plays it
    if (!_foreground || (!auto && (_activeId != null || _starting))) return;
    if (auto) _lastSpokenSeq = segment.seq;
    final generation = _speechGen;
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
    if (!ref.mounted) {
      _deleteQuietly(path); // the conversation closed (and cleared its files) meanwhile
      return;
    }
    _paths[id] = path;
    // The user may have started a turn, or left the app, while the voice was being prepared.
    if (!_mayStillPlay(generation)) {
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
    if (!_mayStillPlay(generation)) {
      _update(id, (s) => s.copyWith(speech: SpeechStatus.none));
      return;
    }
    final target = resolveOutput(role, ref.read(outputPreferencesProvider)[role]!, outputs);

    final previous = _playing;
    if (previous != null && previous.id != id) _update(previous.id, (s) => s.copyWith(speech: SpeechStatus.played));
    _playing = (id: id, role: role, target: target?.kind);
    try {
      await _audio.play(path: path, deviceId: target?.id, playbackId: id);
      if (ref.mounted && _playing?.id == id) _startWatchdog(id);
    } catch (error) {
      debugPrint('Playback failed to start: $error');
      if (ref.mounted && _playing?.id == id) {
        _clearPlaying();
        _speechFailed(id);
      }
    }
  }

  /// If Android never reports the end of a playback, treat it as finished after a while (Listen mode waits for it).
  void _startWatchdog(String id) {
    _watchdog?.cancel();
    _watchdog = Timer(ref.read(playbackWatchdogProvider), () {
      if (!ref.mounted || _playing?.id != id) return;
      debugPrint('Playback $id never reported completion');
      _clearPlaying();
      _update(id, (s) => s.copyWith(speech: SpeechStatus.played));
    });
  }

  void _clearPlaying() {
    _playing = null;
    _watchdog?.cancel();
    _watchdog = null;
  }

  static void _deleteQuietly(String path) {
    try {
      File(path).deleteSync();
    } on FileSystemException {
      // already gone
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
        if (_forMeOnEarphones && !outputs.any((o) => o.isEarphones)) {
          _forMeOnEarphones = false;
          state = state.copyWith(notice: ConversationNotice.earphonesDisconnected, noticeLanguage: null, noticeOutput: null);
          // An audible cue too (R09): the user may not be looking at the screen. While a translation plays,
          // Android moves it to the speaker and that is the cue; a tone would cut it off.
          if (_playing == null) {
            final speaker = outputs.where((o) => o.kind == OutputKind.speaker).firstOrNull;
            unawaited(_audio.playTestTone(deviceId: speaker?.id).catchError((Object _) => null));
          }
        }
      case PlaybackStarted(:final playbackId, :final routed):
        final playing = _playing;
        if (playing == null || playing.id != playbackId) return; // a late event for an interrupted playback
        // A second report means Android moved a playback under way (earphones disconnected): the card follows.
        final moved = _segment(playbackId)?.speech == SpeechStatus.playing;
        _update(playbackId, (s) => s.copyWith(speech: SpeechStatus.playing, output: routed));
        // A move off the earphones keeps the flag, so the device-list change still shows the notice.
        if (playing.role == OutputRole.forMe && (!moved || routed.isEarphones)) _forMeOnEarphones = routed.isEarphones;
        final missedSpeaker = playing.target == OutputKind.speaker && routed.kind != OutputKind.speaker;
        if (playing.role == OutputRole.forOther && missedSpeaker) {
          state = state.copyWith(notice: ConversationNotice.speakerUnavailable, noticeLanguage: null, noticeOutput: routed);
        }
      case PlaybackCompleted(:final playbackId):
        if (_playing?.id != playbackId) return;
        _clearPlaying();
        _update(playbackId, (s) => s.copyWith(speech: SpeechStatus.played));
      case PlaybackFocusLost(:final playbackId):
        if (_playing?.id != playbackId) return;
        _clearPlaying();
        // A call or alarm took the audio: the session pauses (spec R30) instead of listening over it.
        if (state.listenMode) {
          state = state.copyWith(listenMode: false, paused: true, notice: ConversationNotice.pausedForInterruption);
        }
        _update(playbackId, (s) => s.copyWith(speech: SpeechStatus.played));
      case PlaybackFailed(:final playbackId):
        if (_playing?.id != playbackId) return;
        _clearPlaying();
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

/// How long a playback may go without reporting back before Listen mode stops waiting for it.
final playbackWatchdogProvider = Provider<Duration>((ref) => const Duration(seconds: 30));

final conversationControllerProvider =
    NotifierProvider.autoDispose<ConversationController, ConversationState>(ConversationController.new);
