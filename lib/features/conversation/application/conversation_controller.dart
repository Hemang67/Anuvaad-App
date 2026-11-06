import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/permissions/microphone_permission.dart';
import '../../app_update/application/update_controller.dart' show clockProvider;
import '../../language_settings/application/language_preferences_controller.dart';
import '../data/android_speech_recognizer.dart';
import '../domain/segment.dart';
import '../domain/speech_recognition.dart';
import '../domain/translation.dart';
import 'translation_service.dart';

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
}

class ConversationState {
  const ConversationState({
    this.segments = const [],
    this.activeSpeaker,
    this.notice,
    this.noticeLanguage,
    this.otherLanguageOverride,
  });

  /// In creation order (oldest first).
  final List<Segment> segments;

  /// Who is speaking now; null when no turn is active.
  final Speaker? activeSpeaker;
  final ConversationNotice? notice;

  /// The language a [ConversationNotice.languageUnsupported] notice is about.
  final String? noticeLanguage;

  /// The other person's language picked on this screen when Settings says Automatic.
  final String? otherLanguageOverride;

  static const _keep = Object();

  ConversationState copyWith({
    List<Segment>? segments,
    Object? activeSpeaker = _keep,
    Object? notice = _keep,
    Object? noticeLanguage = _keep,
    Object? otherLanguageOverride = _keep,
  }) =>
      ConversationState(
        segments: segments ?? this.segments,
        activeSpeaker: identical(activeSpeaker, _keep) ? this.activeSpeaker : activeSpeaker as Speaker?,
        notice: identical(notice, _keep) ? this.notice : notice as ConversationNotice?,
        noticeLanguage: identical(noticeLanguage, _keep) ? this.noticeLanguage : noticeLanguage as String?,
        otherLanguageOverride:
            identical(otherLanguageOverride, _keep) ? this.otherLanguageOverride : otherLanguageOverride as String?,
      );
}

/// Turns recognizer events into ordered segments and translates each finished one (spec §3.3, text half).
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

  @override
  ConversationState build() {
    final recognizer = _recognizer = ref.watch(speechRecognizerProvider);
    _events = recognizer.events.listen(_onEvent);
    // Backgrounding releases the microphone (spec §0.4).
    _lifecycle = AppLifecycleListener(onHide: _onBackground, onPause: _onBackground);
    ref.onDispose(() {
      if (_activeId != null) unawaited(recognizer.cancel());
      _activeId = null;
      _events?.cancel();
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
      if (!await _ensureMicrophone() || !ref.mounted) return;
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

  void _onBackground() => unawaited(cancelTurn());

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
    } on TranslationUnavailable catch (e) {
      if (ref.mounted) _update(id, (s) => s.copyWith(status: SegmentStatus.failed, offlineNotReady: e.offlineNotReady));
    } catch (error) {
      debugPrint('Translation failed: $error');
      if (ref.mounted) _update(id, (s) => s.copyWith(status: SegmentStatus.failed));
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
