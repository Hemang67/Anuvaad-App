import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_providers.dart';
import '../data/android_speech_recognizer.dart';
import '../domain/speech_recognition.dart';

/// Maps whatever Android reports ("hi", "hi-in", "HI_IN") to one of [allowed] by its language part, or null.
String? matchCoreLanguage(String reported, List<String> allowed) {
  final language = reported.trim().toLowerCase().split(RegExp('[-_]')).first;
  if (language.isEmpty) return null;
  for (final code in allowed) {
    if (code.toLowerCase().split('-').first == language) return code;
  }
  return null;
}

/// What a finished Listen turn's language turned out to be.
sealed class DetectionOutcome {
  const DetectionOutcome();
}

/// Translate from [code]. [detected]: a confident detection said so. [switched]: it replaced the stable language.
class UseLanguage extends DetectionOutcome {
  const UseLanguage(this.code, {required this.detected, required this.switched});
  final String code;
  final bool detected;
  final bool switched;
}

/// Not sure enough to translate: the user picks (spec §9.4 "Language unclear").
class Unclear extends DetectionOutcome {
  const Unclear();
}

bool _counts(LanguageConfidence c) => c == LanguageConfidence.confident || c == LanguageConfidence.highlyConfident;

/// The stable-language rule (spec §9.4, R03):
/// - only a detection that is at least `confident` counts;
/// - with a stable language, it holds unless a counting detection of the other allowed language is strong
///   (highly confident, or at least three words); a sure detection of a language outside the pair is unclear,
///   a merely confident one is code-switching and ignored;
/// - without one, a counting detection decides, and nothing else does.
DetectionOutcome decideSourceLanguage({
  required String recognizedIn,
  required String? stable,
  required ({String locale, LanguageConfidence confidence})? detection,
  required List<String> allowed,
  required int wordCount,
}) {
  final counts = detection != null && _counts(detection.confidence);
  final detected = counts ? matchCoreLanguage(detection.locale, allowed) : null;
  final sure = detection?.confidence == LanguageConfidence.highlyConfident;
  if (stable != null) {
    // No real evidence: the text is in the language the recognizer listened in (the user may have changed the
    // stable language mid-turn; the next turn uses it).
    if (!counts) return UseLanguage(recognizedIn, detected: false, switched: false);
    if (detected == null) return sure ? const Unclear() : UseLanguage(recognizedIn, detected: false, switched: false);
    if (detected == stable) return UseLanguage(stable, detected: true, switched: false);
    if (sure || wordCount >= 3) return UseLanguage(detected, detected: true, switched: true);
    return const Unclear();
  }
  if (detected != null) return UseLanguage(detected, detected: true, switched: false);
  return const Unclear();
}

/// "Automatic language detection" in Settings (on by default, as in the prototype).
class AutoDetectController extends Notifier<bool> {
  @override
  bool build() => ref.watch(settingsRepositoryProvider).autoDetect;

  Future<void> set(bool on) async {
    await ref.read(settingsRepositoryProvider).setAutoDetect(on);
    state = on;
  }
}

final autoDetectProvider = NotifierProvider<AutoDetectController, bool>(AutoDetectController.new);

/// Whether this phone's recognizer can detect the spoken language at all (Android 14+).
final detectionSupportedProvider = FutureProvider<bool>(
  (ref) => ref.watch(speechRecognizerProvider).supportsLanguageDetection(),
);
