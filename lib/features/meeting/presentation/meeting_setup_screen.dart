import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap.dart';
import '../../../app/routes.dart';
import '../../../app/theme/anuvaad_colors.dart';
import '../../../core/permissions/microphone_permission.dart';
import '../../../l10n/app_localizations.dart';
import '../../conversation/application/language_detection.dart';
import '../../conversation/data/android_speech_recognizer.dart';
import '../../conversation/domain/speech_recognition.dart';
import '../../language_settings/application/language_preferences_controller.dart';

/// Meeting mode setup (spec §5-11, R25): what works on Android, the meeting's language, a microphone test, and
/// consent before anything listens.
class MeetingSetupScreen extends ConsumerStatefulWidget {
  const MeetingSetupScreen({super.key});

  @override
  ConsumerState<MeetingSetupScreen> createState() => _MeetingSetupScreenState();
}

enum _TestState { idle, listening, heard, silent, denied }

class _MeetingSetupScreenState extends ConsumerState<MeetingSetupScreen> {
  String? _language;
  bool _consent = false;
  _TestState _test = _TestState.idle;
  String _heard = '';

  // The microphone test in progress, if any.
  SpeechRecognizerPort? _testRecognizer;
  Completer<String>? _testDone;
  Timer? _testTimer;
  StreamSubscription<RecognitionEvent>? _testEvents;

  /// Start and leaving the screen end a test still listening, so its timer can't cancel the meeting's recognizer
  /// and the microphone doesn't stay open behind Home.
  Future<void> _stopTest() async {
    final done = _testDone;
    if (done == null) return;
    _testDone = null;
    _testTimer?.cancel();
    _testTimer = null;
    unawaited(_testEvents?.cancel());
    _testEvents = null;
    if (!done.isCompleted) done.complete('');
    await _testRecognizer?.cancel();
  }

  @override
  void dispose() {
    unawaited(_stopTest());
    super.dispose();
  }

  /// One short recognition in the meeting's language: proof the phone hears the meeting.
  Future<void> _testMicrophone(String locale) async {
    setState(() => _test = _TestState.listening);
    final mic = ref.read(microphonePermissionProvider);
    final granted = await mic.status() == MicPermission.granted || await mic.request() == MicPermission.granted;
    if (!mounted) return;
    if (!granted) {
      setState(() => _test = _TestState.denied);
      return;
    }
    final recognizer = ref.read(speechRecognizerProvider);
    _testRecognizer = recognizer;
    final done = _testDone = Completer<String>();
    var partial = '';
    void finish(String text) {
      if (!done.isCompleted) done.complete(text.trim());
    }

    _testEvents = recognizer.events.listen((event) {
      switch (event) {
        case PartialResult(:final text):
          partial = text;
        case FinalResult(:final text):
          finish(text.isEmpty ? partial : text);
        case RecognitionError():
          finish(partial);
        default:
          break;
      }
    });
    _testTimer = Timer(const Duration(seconds: 6), () {
      finish(partial);
      unawaited(recognizer.cancel());
    });
    try {
      await recognizer.start(locale);
      _heard = await done.future;
    } catch (_) {
      _heard = '';
    } finally {
      if (identical(_testDone, done)) {
        _testDone = null;
        _testTimer?.cancel();
        _testTimer = null;
        // Not awaited: the answer is in, and waiting on the cancel only delays showing it.
        unawaited(_testEvents?.cancel());
        _testEvents = null;
      }
    }
    if (mounted) setState(() => _test = _heard.isEmpty ? _TestState.silent : _TestState.heard);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    final registry = ref.watch(languageRegistryProvider);
    final prefs = ref.watch(languagePreferencesProvider);
    final detection = (ref.watch(detectionSupportedProvider).value ?? false) && ref.watch(autoDetectProvider);
    final choices = [for (final l in registry.coreLanguages) if (l.code != prefs.myLanguage) l];
    final fallback = prefs.otherLanguage == autoDetect ? (detection ? autoDetect : choices.first.code) : prefs.otherLanguage;
    final language = _language ?? fallback;
    // The test listens in the chosen language; Automatic tests in the first candidate.
    final testLocale = language == autoDetect ? choices.first.code : language;

    final testLine = switch (_test) {
      _TestState.idle => null,
      _TestState.listening => l10n.meetingTestListening,
      _TestState.heard => l10n.meetingHeard(_heard),
      _TestState.silent => l10n.meetingHeardNothing,
      _TestState.denied => l10n.noticeMicDenied,
    };

    return Scaffold(
      key: const Key('meeting-setup-screen'),
      appBar: AppBar(title: Text(l10n.meetingTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: tokens.blue),
                    const SizedBox(width: 12),
                    Expanded(child: Text(l10n.meetingExplain, style: TextStyle(color: tokens.ink, height: 1.4))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.meetingLanguage, style: TextStyle(fontWeight: FontWeight.w800, color: tokens.ink)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              key: const Key('meeting-language'),
              initialValue: language,
              isExpanded: true,
              items: [
                if (detection) DropdownMenuItem(value: autoDetect, child: Text(l10n.languagesAutoDetect)),
                for (final l in choices) DropdownMenuItem(value: l.code, child: Text(l.nativeFirstLabel)),
              ],
              onChanged: (code) => setState(() {
                _language = code;
                _test = _TestState.idle;
              }),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: const Key('test-mic'),
                onPressed: _test == _TestState.listening ? null : () => _testMicrophone(testLocale),
                icon: const Icon(Icons.mic_none),
                label: Text(l10n.meetingTestMic),
              ),
            ),
            if (testLine != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(testLine, style: TextStyle(color: _test == _TestState.heard ? tokens.ink : tokens.muted)),
              ),
            const SizedBox(height: 16),
            CheckboxListTile(
              key: const Key('meeting-consent'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _consent,
              onChanged: (on) => setState(() => _consent = on ?? false),
              title: Text(l10n.meetingConsent),
            ),
            const SizedBox(height: 8),
            KeyedSubtree(
              key: const Key('meeting-start'),
              child: FilledButton.icon(
                onPressed: _consent
                    ? () async {
                        await _stopTest();
                        if (!context.mounted) return;
                        context.pushReplacement(Routes.meetingConversation(language == autoDetect ? null : language));
                      }
                    : null,
                icon: const Icon(Icons.hearing),
                label: Text(l10n.meetingStart),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
