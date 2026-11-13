import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/app_language.dart';
import '../../../app/bootstrap.dart';
import '../../../core/permissions/microphone_permission.dart';
import '../../../core/settings/settings_providers.dart';
import '../../../core/settings/settings_repository.dart';
import '../../app_update/application/update_controller.dart' show clockProvider;
import '../../diagnostics/data/latency_log.dart';
import '../../diagnostics/domain/latency_sample.dart';
import '../../history/application/history_providers.dart';
import '../../history/domain/history_repository.dart';
import '../../history/domain/saved_conversation.dart';
import '../../../l10n/app_localizations.dart';
import '../../language_settings/application/language_preferences_controller.dart';
import '../data/android_conversation_service.dart';
import '../data/android_audio.dart';
import '../data/android_speech_recognizer.dart';
import '../data/offline_models.dart';
import '../domain/audio_output.dart';
import '../domain/conversation_service.dart';
import '../domain/segment.dart';
import '../domain/speech_recognition.dart';
import '../domain/translation.dart';
import '../domain/voice.dart';
import 'language_detection.dart';
import 'mic_level.dart';
import 'review_reply.dart';
import 'screen_off_settings.dart';
import 'session_notification.dart';
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
  askToRepeat,
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
    this.otherLanguageDetected = false,
    this.savedToHistory = false,
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

  /// [otherLanguageOverride] came from a confident detection, not the user's pick.
  final bool otherLanguageDetected;

  /// This conversation is in History (saved at End, or with the summary's Save).
  final bool savedToHistory;

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
    bool? otherLanguageDetected,
    bool? savedToHistory,
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
        otherLanguageDetected: otherLanguageDetected ?? this.otherLanguageDetected,
        savedToHistory: savedToHistory ?? this.savedToHistory,
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

  /// Asked once: whether this phone's recognizer can detect the spoken language.
  bool? _supportsDetection;

  /// Per Listen turn in Automatic mode: the languages it may detect, and the latest detection.
  final _allowedFor = <String, List<String>>{};
  final _detections = <String, ({String locale, LanguageConfidence confidence})>{};

  /// History: this conversation's id (from its first turn), my language, and where it is saved.
  String? _sessionId;
  String? _myLanguage;
  late HistoryRepository _history;
  late SettingsRepository _settings;

  /// The latest state, for saving when the screen closes (state can't be read once disposal starts).
  ConversationState? _lastState;

  /// Latency: one sample per segment, when its pipeline ends.
  late LatencyLog _latency;
  final _measured = <String>{};

  /// Replies that waited for review, and ones edited there: their later stages include reading or typing time.
  final _reviewed = <String>{};
  final _edited = <String>{};

  /// Bumped by Pause, End, the background and cancelTurn: a Listen turn still starting (permission, recognizer
  /// checks) gives up instead of opening the microphone afterwards.
  int _turnGen = 0;

  /// Completes when the turn in progress ends (final result, dropped or cancelled).
  Completer<void>? _turnEnded;

  /// Silence results that came back within a second of their turn starting, in a row: a recognizer that can't
  /// listen at all. Three pause the session instead of cycling the microphone.
  int _quickSilences = 0;

  /// The other person's language was picked by the user (Change, or a meeting language): detection doesn't override it.
  bool _languagePicked = false;

  /// Android's conversation service: while it runs, the conversation keeps its microphone with the screen off or the
  /// app in the background, and its notification shows what is happening (with buttons).
  late ConversationServicePort _service;
  StreamSubscription<SessionCommand>? _commands;
  bool _serviceRunning = false;
  bool _serviceStarting = false;
  SessionNotification? _shown;
  bool _notificationQueued = false;

  /// Listen turns that also listen for my own language ("Reply without tapping").
  final _replyDetectFor = <String>{};

  /// Captured at build for work that finishes after the screen has closed.
  late DateTime Function() _clock;
  late HistoryRevision _historyRevision;

  @override
  ConversationState build() {
    final recognizer = _recognizer = ref.watch(speechRecognizerProvider);
    _events = recognizer.events.listen(_onEvent);
    final audio = _audio = ref.watch(audioOutputProvider);
    final voice = _voice = ref.watch(voiceServiceProvider);
    final history = _history = ref.watch(historyRepositoryProvider);
    final settings = _settings = ref.watch(settingsRepositoryProvider);
    _latency = ref.watch(latencyLogProvider);
    final clock = _clock = ref.read(clockProvider);
    final revision = _historyRevision = ref.read(historyRevisionProvider.notifier);
    _audioEvents = audio.events.listen(_onAudio);
    final service = _service = ref.watch(conversationServiceProvider);
    // Backgrounding releases the microphone unless the conversation service is running (screen off, other apps).
    _lifecycle = AppLifecycleListener(
      onHide: _onBackground,
      onPause: _onBackground,
      onShow: _onForeground,
      onResume: _onForeground,
    );
    // Continuous Listen: when the last turn's work (translate, voice, playback) is done, listen again.
    listenSelf((previous, next) {
      _lastState = next;
      if (previous != null && _busy(previous) && !_busy(next)) scheduleMicrotask(_maybeRearm);
      if (_serviceRunning) _queueNotification();
    });
    // Files from a conversation the app never finished closing (killed, swiped away) go now.
    unawaited(voice.sweep().catchError((Object error) => debugPrint('Could not clear old voice files: $error')));
    ref.onDispose(() {
      if (_activeId != null) unawaited(recognizer.cancel());
      _activeId = null;
      _watchdog?.cancel();
      // Leaving without End counts as End: with history on, the conversation is kept.
      final last = _lastState;
      if (last != null && !last.ended && settings.saveHistory) {
        final saved = _toSaved(last, endedAt: clock());
        if (saved != null) {
          unawaited(history.save(saved).then((_) => revision.bump()).catchError((Object e) => debugPrint('Could not save history: $e')));
        }
      }
      // Leaving the screen ends playback and deletes the synthesized files.
      unawaited(audio.stop());
      unawaited(voice.clear());
      _events?.cancel();
      _audioEvents?.cancel();
      _lifecycle?.dispose();
      _commands?.cancel();
      // Leaving the conversation screen ends it: no notification, no microphone.
      if (_serviceRunning) {
        _serviceRunning = false;
        unawaited(service.stop());
      }
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
    _silenceSince = null; // counted from the first turn that really starts (not a permission prompt)
    _quickSilences = 0;
    state = state.copyWith(listenMode: true, paused: false);
    await startTurn(Speaker.other);
  }

  /// Meeting mode (spec §3.2, R25): a meeting played on a speaker in the room. Listen only, in [language] (null keeps
  /// the usual rules: the Languages setting, or Automatic).
  Future<void> startMeeting(String? language) async {
    if (state.ended) return;
    if (language != null) _languagePicked = true;
    state = state.copyWith(
      mode: ConversationMode.meeting,
      otherLanguageOverride: language ?? state.otherLanguageOverride,
      otherLanguageDetected: false,
    );
    await startListening();
  }

  /// Stops the microphone and any playback, and leaves Listen mode until Listen is tapped again.
  /// Words already heard in a Listen turn are kept (stopped, so the final result arrives and is translated, not
  /// spoken); an empty turn is cancelled.
  Future<void> pause() async {
    if (state.ended) return;
    _turnGen++;
    state = state.copyWith(listenMode: false, paused: true);
    final active = _activeId;
    if (active != null && state.activeSpeaker == Speaker.other && (_segment(active)?.text.trim().isNotEmpty ?? false)) {
      _setLevel(0);
      await _recognizer.stop();
    } else {
      await cancelTurn();
    }
    await stopSpeaking();
  }

  /// One reply turn. A Listen turn still waiting for the other person makes way; if they had started talking, their
  /// turn is finished (kept and translated) first. Listen mode resumes after the reply has played.
  Future<void> startSpeaking() async {
    if (state.ended || state.mode == ConversationMode.meeting) return;
    _holdRearm++;
    try {
      final active = _activeId;
      if (state.activeSpeaker == Speaker.other && active != null) {
        final partial = _segment(active)?.text.trim() ?? '';
        if (partial.isEmpty) {
          await cancelTurn();
        } else {
          final ended = _turnEnded;
          _setLevel(0);
          await _recognizer.stop();
          // The final result normally follows within a moment; if it doesn't, keep the words already heard.
          await ended?.future.timeout(const Duration(seconds: 1), onTimeout: () {
            if (_activeId == active) _finalize(active, partial);
          });
        }
      }
      await startTurn(Speaker.me);
    } finally {
      _holdRearm--;
    }
  }

  /// Ends the conversation: the microphone and playback stop, and nothing starts again.
  Future<void> endSession() async {
    if (state.ended) return;
    _turnGen++;
    state = state.copyWith(listenMode: false, paused: false, ended: true, sessionEndedAt: _now());
    _stopService();
    await cancelTurn();
    await stopSpeaking();
    if (ref.mounted && _settings.saveHistory) await _save();
  }

  /// The summary's Save: keeps this one conversation even with history off.
  Future<void> saveToHistory() => _save();

  /// This conversation as it would be saved, or null before anything final was said.
  SavedConversation? toSavedConversation() => _toSaved(state, endedAt: _now());

  Future<void> _save() async {
    final saved = _toSaved(state, endedAt: _now());
    if (saved == null) return;
    try {
      await _history.save(saved);
      _historyRevision.bump();
      if (ref.mounted) state = state.copyWith(savedToHistory: true);
    } catch (error) {
      debugPrint('Could not save history: $error');
    }
  }

  /// With history on, keeps what has been said so far: an app killed in the background never reaches End or dispose.
  void _checkpoint() {
    if (!ref.mounted || state.ended || !_settings.saveHistory) return;
    final saved = _toSaved(state, endedAt: _now());
    if (saved == null) return;
    unawaited(_history.save(saved).then((_) => _historyRevision.bump()).catchError((Object e) => debugPrint('Could not save history: $e')));
  }

  /// The screen closed (Done, Back) while this translation was on its way: the saved copy still gets it.
  void _afterClose(String id, Translation translation) {
    final last = _lastState;
    if (last == null || !(last.savedToHistory || _settings.saveHistory)) return;
    final updated = last.copyWith(segments: [
      for (final s in last.segments)
        s.id == id ? s.copyWith(translation: translation, status: SegmentStatus.translated) : s,
    ]);
    _lastState = updated;
    final saved = _toSaved(updated, endedAt: updated.sessionEndedAt ?? _clock());
    if (saved == null) return;
    unawaited(_history.save(saved).then((_) => _historyRevision.bump()).catchError((Object e) => debugPrint('Could not save history: $e')));
  }

  SavedConversation? _toSaved(ConversationState s, {required DateTime endedAt}) {
    final id = _sessionId;
    final started = s.sessionStartedAt;
    final my = _myLanguage;
    if (id == null || started == null || my == null) return null;
    final segments = [
      for (final x in s.segments)
        if (x.isFinal && x.text.trim().isNotEmpty)
          SavedSegment(
            id: x.id,
            seq: x.seq,
            speaker: x.speaker,
            sourceLanguage: x.sourceLanguage,
            targetLanguage: x.targetLanguage,
            text: x.text,
            translation: x.status == SegmentStatus.translated ? x.translation?.text : null,
            provenance: x.status == SegmentStatus.translated ? x.translation?.provenance : null,
            unclear: x.status == SegmentStatus.unclear,
            at: x.finalAt ?? x.startedAt,
          ),
    ];
    if (segments.isEmpty) return null;
    final others = {for (final x in segments) ...[x.sourceLanguage, x.targetLanguage]}..remove(my);
    return SavedConversation(
      id: id,
      startedAt: started,
      endedAt: s.sessionEndedAt ?? endedAt,
      myLanguage: my,
      otherLanguages: others.toList(),
      mode: s.mode,
      segments: segments,
    );
  }

  /// [clearNotice]: a tap clears the notice; an automatic Listen-mode turn keeps it ("Ask them to say it again",
  /// "Earphones disconnected" stay readable).
  Future<void> startTurn(Speaker speaker, {bool clearNotice = true}) async {
    if (_activeId != null || _starting || state.ended) return;
    _starting = true;
    final generation = _turnGen;
    // Pause, End or the background while this turn was still starting: it never opens the microphone.
    bool cancelled() => !ref.mounted || generation != _turnGen || state.ended;
    try {
      final my = ref.read(languagePreferencesProvider).myLanguage;
      final detection = speaker == Speaker.other ? await _detection(my) : _noDetection;
      final detectAmong = detection.detectAmong;
      if (cancelled()) return;
      // Automatic: the stable language if there is one, else the first candidate while the recognizer detects.
      final other = _otherLanguage() ?? (detectAmong.isEmpty ? null : detectAmong.first);
      if (other == null) {
        state = state.copyWith(notice: ConversationNotice.chooseOtherLanguage, noticeLanguage: null);
        return;
      }
      final source = speaker == Speaker.other ? other : my;
      final target = speaker == Speaker.other ? my : other;
      if (clearNotice) state = state.copyWith(notice: null, noticeLanguage: null);
      // The microphone never opens over a translation that is playing (R29).
      await stopSpeaking();
      if (cancelled()) return;
      if (!await _ensureMicrophone()) {
        if (ref.mounted) _leaveListenMode(); // never ask again and again for the microphone
        return;
      }
      if (cancelled()) return;
      await _ensureService();
      if (cancelled()) return;
      if (!await _recognizer.isAvailable()) {
        if (ref.mounted) {
          state = state.copyWith(notice: ConversationNotice.recognizerUnavailable);
          _leaveListenMode();
        }
        return;
      }
      if (cancelled()) return;
      final segment = Segment(
        id: _uuid.v4(),
        seq: ++_seq,
        speaker: speaker,
        sourceLanguage: source,
        targetLanguage: target,
        startedAt: _now(),
      );
      _activeId = segment.id;
      _turnEnded = Completer<void>();
      _silenceSince ??= segment.startedAt;
      _sessionId ??= _uuid.v4();
      _myLanguage ??= my;
      if (detection.decide) _allowedFor[segment.id] = [for (final c in detectAmong) if (c != my) c];
      if (detection.mine) _replyDetectFor.add(segment.id);
      state = state.copyWith(
        segments: [...state.segments, segment],
        activeSpeaker: speaker,
        sessionStartedAt: state.sessionStartedAt ?? segment.startedAt,
      );
      try {
        await _recognizer.start(source, detectAmong: detectAmong);
      } catch (error) {
        debugPrint('Speech recognizer failed to start: $error');
        _leaveListenMode();
        _drop(segment.id, ConversationNotice.generic);
      }
    } finally {
      _starting = false;
    }
  }

  static const _noDetection = (detectAmong: <String>[], decide: false, mine: false);

  /// What a Listen turn asks the recognizer to detect (only where it can: Android 14+). [decide]: their language is
  /// Automatic, so detection picks it among the core languages that aren't mine (unless the user picked one).
  /// [mine]: "Reply without tapping" is on, so my own language is listened for too (never in a meeting).
  Future<({List<String> detectAmong, bool decide, bool mine})> _detection(String my) async {
    final decide = !_languagePicked &&
        ref.read(languagePreferencesProvider).otherLanguage == autoDetect &&
        ref.read(autoDetectProvider);
    final mine = ref.read(autoReplyProvider) && state.mode != ConversationMode.meeting;
    if (!decide && !mine) return _noDetection;
    final supported = _supportsDetection ??= await _recognizer.supportsLanguageDetection();
    if (!supported || !ref.mounted) return _noDetection;
    final theirs = decide
        ? [for (final l in ref.read(languageRegistryProvider).coreLanguages) if (l.code != my) l.code]
        : [?_otherLanguage()];
    if (theirs.isEmpty) return _noDetection; // nothing to listen in: Listen asks for their language
    return (detectAmong: [...theirs, if (mine) my], decide: decide, mine: mine);
  }

  /// The user's answer to "Language unclear": the same language translates the card; another one drops it
  /// (its text was heard in the wrong language) and asks them to say it again.
  void confirmLanguage(String segmentId, String code) {
    final segment = _segment(segmentId);
    if (segment == null || segment.status != SegmentStatus.unclear) return;
    state = state.copyWith(otherLanguageOverride: code, otherLanguageDetected: false);
    if (code == segment.sourceLanguage) {
      _update(segmentId, (s) => s.copyWith(status: SegmentStatus.translating));
      unawaited(_translate(segmentId));
    } else {
      state = state.copyWith(
        segments: [for (final s in state.segments) if (s.id != segmentId) s],
        notice: ConversationNotice.askToRepeat,
        noticeLanguage: code,
      );
    }
  }

  /// Ends listening; the recognizer then sends its final result.
  Future<void> stopTurn() async {
    if (_activeId == null) return;
    await _recognizer.stop();
  }

  /// Ends listening and discards the unfinished card.
  Future<void> cancelTurn() async {
    _turnGen++;
    final id = _activeId;
    if (id == null) return;
    _activeId = null;
    _completeTurn();
    _setLevel(0);
    state = state.copyWith(
      segments: [for (final s in state.segments) if (s.id != id || s.isFinal) s],
      activeSpeaker: null,
    );
    await _recognizer.cancel();
  }

  void chooseOtherLanguage(String code) {
    if (code == ref.read(languagePreferencesProvider).myLanguage) return;
    _languagePicked = true;
    state = state.copyWith(otherLanguageOverride: code, otherLanguageDetected: false, notice: null, noticeLanguage: null);
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
    _checkpoint();
    // With the conversation service running, the conversation carries on: screen off, or another app on top.
    if (_serviceRunning && !state.ended) return;
    _turnGen++;
    // A running session pauses (Listen resumes it); otherwise just release the microphone and stop playback.
    if (!state.ended && (state.listenMode || _activeId != null || _playing != null)) {
      unawaited(pause());
    } else {
      unawaited(cancelTurn());
      unawaited(stopSpeaking());
    }
  }

  void _onForeground() => _foreground = true;

  /// Starts the conversation service on the first turn the user starts (Android allows that only while the app is on
  /// screen). If Android refuses, the conversation pauses in the background as before.
  Future<void> _ensureService() async {
    if (_serviceRunning || _serviceStarting || !_foreground || !ref.read(screenOffListeningProvider)) return;
    _serviceStarting = true;
    try {
      final notification = _notification();
      final started = await _service.start(
        notification,
        channelName: _strings().notifChannel,
        earphoneButton: ref.read(earphoneButtonProvider),
      );
      if (!started) return;
      if (!ref.mounted || state.ended) {
        unawaited(_service.stop()); // closed or ended meanwhile
        return;
      }
      _serviceRunning = true;
      _shown = notification;
      _commands ??= _service.commands.listen(_onCommand);
      _queueNotification(); // the conversation may have moved on while it started
    } catch (error) {
      // An extra: the conversation itself never depends on it.
      debugPrint('Could not keep the conversation going with the screen off: $error');
    } finally {
      _serviceStarting = false;
    }
  }

  void _stopService() {
    if (!_serviceRunning) return;
    _serviceRunning = false;
    _shown = null;
    unawaited(_service.stop());
  }

  /// One notification update per burst of changes, and none when what it shows is the same.
  void _queueNotification() {
    if (_notificationQueued) return;
    _notificationQueued = true;
    scheduleMicrotask(() {
      _notificationQueued = false;
      if (!ref.mounted || !_serviceRunning) return;
      try {
        final next = _notification();
        if (next == _shown) return;
        _shown = next;
        unawaited(_service.update(next));
      } catch (error) {
        debugPrint('Could not update the conversation notification: $error');
      }
    });
  }

  SessionNotification _notification() {
    final registry = ref.read(languageRegistryProvider);
    final my = _myLanguage ?? ref.read(languagePreferencesProvider).myLanguage;
    final other = _otherLanguage();
    return sessionNotificationFor(
      state,
      l10n: _strings(),
      myName: registry.byCode(my)?.displayName ?? my,
      otherName: other == null ? null : registry.byCode(other)?.displayName ?? other,
    );
  }

  /// The app's own language (Settings → App language, else the phone's), for text outside any screen.
  AppLocalizations _strings() {
    final chosen = ref.read(appLanguageProvider);
    final code = chosen == 'system' ? WidgetsBinding.instance.platformDispatcher.locale.languageCode : chosen;
    return lookupAppLocalizations(Locale(appLanguages.contains(code) ? code : 'en'));
  }

  /// The notification's buttons and the earphones' play/pause button.
  void _onCommand(SessionCommand command) {
    if (!ref.mounted) return;
    switch (command) {
      case SessionCommand.listen:
        unawaited(startListening());
      case SessionCommand.speak:
        unawaited(startSpeaking());
      case SessionCommand.finishReply:
        unawaited(finishReply());
      case SessionCommand.pause:
        unawaited(pause());
      case SessionCommand.end:
        unawaited(endSession());
      case SessionCommand.playReply:
        final waiting = _awaitingReview();
        if (waiting != null) unawaited(playReply(waiting.id));
      case SessionCommand.discardReply:
        final waiting = _awaitingReview();
        if (waiting != null) discardReply(waiting.id);
      case SessionCommand.earphoneButton:
        unawaited(onEarphoneButton());
      case SessionCommand.stopped:
        // Android ended the service: from now on the background pauses the conversation, as before.
        _serviceRunning = false;
        _shown = null;
    }
  }

  void _onEvent(RecognitionEvent event) {
    final id = _activeId;
    if (id == null || !ref.mounted) return; // late events after stop/cancel, or a duplicate final
    switch (event) {
      case PartialResult(:final text):
        _quickSilences = 0;
        _update(id, (s) => s.copyWith(text: text, firstPartialAt: s.firstPartialAt ?? _now()));
      case FinalResult(:final text) when text.trim().isNotEmpty:
        _finalize(id, text.trim());
      case FinalResult():
        _silence(id);
      case RecognitionError(code: RecognitionErrorCode.noMatch || RecognitionErrorCode.speechTimeout):
        // Android can report no-match after partial words: they were heard, so that's a turn, not silence.
        final partial = _segment(id)?.text.trim() ?? '';
        if (partial.isEmpty) {
          _silence(id);
        } else {
          _finalize(id, partial);
        }
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
      case LanguageDetected(:final locale, :final confidence):
        _detections[id] = (locale: locale, confidence: confidence);
      case SpeechStarted():
        _update(id, (s) => s.copyWith(speechStartAt: s.speechStartAt ?? _now()));
      case EndOfSpeech():
        _update(id, (s) => s.copyWith(speechEndAt: _now()));
      case RecognitionReady():
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
    final started = _segment(id)?.startedAt;
    _quickSilences = started != null && _now().difference(started) < const Duration(seconds: 1) ? _quickSilences + 1 : 0;
    if (_quickSilences >= 3) {
      // Silence the moment it starts, again and again: the recognizer can't listen. Stop cycling the microphone.
      _quickSilences = 0;
      _leaveListenMode();
      _drop(id, ConversationNotice.generic);
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
    _completeTurn();
    _quickSilences = 0;
    _silenceSince = _now();
    _setLevel(0);
    final allowed = _allowedFor.remove(id) ?? const <String>[];
    final detection = _detections.remove(id);
    final listenedForMine = _replyDetectFor.remove(id);
    final segment = _segment(id);
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final my = _myLanguage ?? ref.read(languagePreferencesProvider).myLanguage;
    final theirs = _otherLanguage();
    if (segment != null &&
        segment.speaker == Speaker.other &&
        listenedForMine &&
        theirs != null &&
        spokeIn(my, detection: detection, wordCount: words)) {
      // "Reply without tapping": I spoke, not them. My words go to them, in their language; theirs stays as it was.
      state = state.copyWith(
        segments: [
          for (final s in state.segments)
            s.id == id
                ? s.copyWith(
                    speaker: Speaker.me,
                    sourceLanguage: my,
                    targetLanguage: theirs,
                    text: text,
                    isFinal: true,
                    status: SegmentStatus.translating,
                    finalAt: _now(),
                  )
                : s,
        ],
        activeSpeaker: null,
      );
      unawaited(_translate(id));
      return;
    }
    var status = SegmentStatus.translating;
    String? source;
    var detected = false;
    if (segment != null && segment.speaker == Speaker.other && allowed.isNotEmpty) {
      final outcome = decideSourceLanguage(
        recognizedIn: segment.sourceLanguage,
        stable: state.otherLanguageOverride,
        detection: detection,
        allowed: allowed,
        wordCount: words,
      );
      switch (outcome) {
        case UseLanguage(:final code, detected: final isDetected):
          source = code;
          detected = isDetected;
          // Only a detection moves the stable language; a language the user picked mid-turn stays for the next one.
          if (isDetected) state = state.copyWith(otherLanguageOverride: code, otherLanguageDetected: true);
        case Unclear():
          status = SegmentStatus.unclear; // never translated with a guessed source (§9.4)
      }
    }
    state = state.copyWith(
      segments: [
        for (final s in state.segments)
          s.id == id
              ? s.copyWith(
                  text: text,
                  isFinal: true,
                  status: status,
                  finalAt: _now(),
                  sourceLanguage: source,
                  detected: detected,
                )
              : s,
      ],
      activeSpeaker: null,
    );
    if (status == SegmentStatus.translating) unawaited(_translate(id));
  }

  /// Removes an unfinished card. A null [notice] keeps whatever notice is showing.
  void _drop(String id, ConversationNotice? notice, {String? language}) {
    _activeId = null;
    _replyDetectFor.remove(id);
    _completeTurn();
    _setLevel(0);
    final segments = [for (final s in state.segments) if (s.id != id) s];
    state = notice == null
        ? state.copyWith(segments: segments, activeSpeaker: null)
        : state.copyWith(segments: segments, activeSpeaker: null, notice: notice, noticeLanguage: language);
  }

  void _setLevel(double level) => ref.read(micLevelProvider.notifier).set(level);

  void _completeTurn() {
    final ended = _turnEnded;
    _turnEnded = null;
    if (ended != null && !ended.isCompleted) ended.complete();
  }

  /// Listen mode stops (it would only fail again); Listen resumes it.
  void _leaveListenMode() {
    if (state.listenMode) state = state.copyWith(listenMode: false, paused: true);
  }

  /// Work that must finish before the microphone may open again: a turn, a translation, a voice, a playback,
  /// a reply under review, a card waiting for its language.
  static bool _busy(ConversationState s) =>
      s.activeSpeaker != null ||
      s.segments.any((x) =>
          x.status == SegmentStatus.translating ||
          x.status == SegmentStatus.unclear ||
          x.speech == SpeechStatus.preparing ||
          x.speech == SpeechStatus.playing ||
          x.speech == SpeechStatus.awaitingReview);

  /// Starts the next Listen turn when Listen mode is on and nothing else is going on (R29: never over playback).
  void _maybeRearm() {
    if (!ref.mounted || !state.listenMode || state.paused || state.ended || !_canRun) return;
    if (_holdRearm > 0 || _activeId != null || _starting || _playing != null || _busy(state)) return;
    unawaited(startTurn(Speaker.other, clearNotice: false));
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
      if (!ref.mounted) {
        _afterClose(id, translation);
        return;
      }
      _update(id, (s) => s.copyWith(
            translation: translation,
            status: SegmentStatus.translated,
            offlineNotReady: false,
            translatedAt: _now(),
          ));
      // A translation that lands after End belongs in the saved copy too (it is never spoken: the session ended).
      if (state.ended && state.savedToHistory) unawaited(_save());
      _checkpoint();
      // With "Review my reply before playing" on, my reply waits for Play (or Edit, Discard).
      if (segment.speaker == Speaker.me && ref.read(reviewReplyProvider)) {
        _reviewed.add(id);
        _update(id, (s) => s.copyWith(speech: SpeechStatus.awaitingReview));
        return;
      }
      unawaited(_speak(id, auto: true));
    } on TranslationUnavailable catch (e) {
      if (ref.mounted) _translationFailed(id, offlineNotReady: e.offlineNotReady);
    } catch (error) {
      debugPrint('Translation failed: $error');
      if (ref.mounted) _translationFailed(id);
    }
  }

  /// A failed reply under review stops waiting for Play (it would block listening): Retry brings the review back.
  void _translationFailed(String id, {bool offlineNotReady = false}) {
    _update(id, (s) => s.copyWith(
          status: SegmentStatus.failed,
          offlineNotReady: offlineNotReady,
          speech: s.speech == SpeechStatus.awaitingReview ? SpeechStatus.none : null,
        ));
    _measure(id);
    _checkpoint();
  }

  /// Review: corrects what was heard and translates it again; the reply keeps waiting for Play.
  Future<void> editReply(String id, String text) async {
    final segment = _segment(id);
    final trimmed = text.trim();
    if (segment == null || segment.speech != SpeechStatus.awaitingReview || trimmed.isEmpty) return;
    _paths.remove(id); // any old voice is for the old words
    _edited.add(id);
    _update(id, (s) => s.copyWith(text: trimmed, status: SegmentStatus.translating));
    await _translate(id);
  }

  /// Review: plays the reply to the other person.
  Future<void> playReply(String id) async {
    if (_segment(id)?.speech != SpeechStatus.awaitingReview) return;
    await _speak(id, auto: false);
  }

  /// Review: throws the reply away; Listen mode carries on.
  void discardReply(String id) {
    if (_segment(id)?.speech != SpeechStatus.awaitingReview) return;
    state = state.copyWith(segments: [for (final s in state.segments) if (s.id != id) s]);
  }

  /// Sends my reply now (the notification's Done, the earphone button) instead of waiting for me to go quiet.
  Future<void> finishReply() async {
    if (state.activeSpeaker != Speaker.me || _activeId == null) return;
    _setLevel(0);
    await _recognizer.stop();
  }

  /// The earphones' play/pause button: plays a reply waiting for review, else sends the reply being spoken, else
  /// starts one. Meetings have no replies.
  Future<void> onEarphoneButton() async {
    if (state.ended || state.mode == ConversationMode.meeting || !ref.read(earphoneButtonProvider)) return;
    final waiting = _awaitingReview();
    if (waiting != null) return playReply(waiting.id);
    if (state.activeSpeaker == Speaker.me) return finishReply();
    await startSpeaking();
  }

  Segment? _awaitingReview() {
    Segment? found;
    for (final s in state.segments) {
      if (s.speech == SpeechStatus.awaitingReview) found = s;
    }
    return found;
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
  bool _mayStillPlay(int generation) => generation == _speechGen && _canRun && _activeId == null && !_starting;

  /// On screen, or carrying on with the screen off under the conversation service.
  bool get _canRun => _foreground || _serviceRunning;

  Future<void> _speak(String id, {required bool auto}) async {
    final segment = _segment(id);
    final translation = segment?.translation;
    if (segment == null || translation == null) return;
    if (auto && !_mayAutoPlay(segment)) {
      _measure(id);
      return; // stays SpeechStatus.none; Replay plays it
    }
    if (!_canRun || (!auto && (_activeId != null || _starting))) return;
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
      if (ref.mounted) {
        _update(id, (s) => s.copyWith(speech: SpeechStatus.noVoice));
        _measure(id);
      }
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
    _update(id, (s) => s.copyWith(synthesizedAt: s.synthesizedAt ?? _now()));
    // The user may have started a turn, or left the app, while the voice was being prepared.
    if (!_mayStillPlay(generation)) {
      _update(id, (s) => s.copyWith(speech: SpeechStatus.none));
      _measure(id);
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
  /// [extra]: once Android reports the playback started, its length is known roughly: the watchdog allows for it.
  void _startWatchdog(String id, {Duration extra = Duration.zero}) {
    _watchdog?.cancel();
    _watchdog = Timer(ref.read(playbackWatchdogProvider) + extra, () {
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

  /// Records the segment's stage timings once, when its pipeline is over (played, or never will be).
  void _measure(String id, {OutputKind? output}) {
    final segment = _segment(id);
    if (segment == null || !_measured.add(id)) return;
    unawaited(_latency
        .record(LatencySample.fromSegment(
          segment,
          at: _now(),
          output: output,
          reviewed: _reviewed.contains(id),
          edited: _edited.contains(id),
        ))
        .catchError((Object e) => debugPrint('Could not record latency: $e')));
  }

  void _speechFailed(String id) {
    _update(id, (s) => s.copyWith(speech: SpeechStatus.failed));
    _measure(id);
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
        _update(playbackId, (s) => s.copyWith(
              speech: SpeechStatus.playing,
              output: routed,
              playbackStartedAt: s.playbackStartedAt ?? _now(),
            ));
        if (!moved) {
          _measure(playbackId, output: routed.kind);
          // A long translation must not be cut off: about 100 ms per character on top of the base wait.
          final chars = _segment(playbackId)?.translation?.text.length ?? 0;
          _startWatchdog(playbackId, extra: Duration(milliseconds: chars * 100));
        }
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
