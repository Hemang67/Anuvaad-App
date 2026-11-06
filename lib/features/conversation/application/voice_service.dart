import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../data/android_audio.dart';
import '../domain/voice.dart';

/// Turns a translated segment into a WAV file in the cache, ready to play and replay.
/// Files live in `<cache>/tts/` and are deleted by [clear] when the conversation closes, and by [sweep] when the
/// next one opens, in case the app was closed before it could clean up.
class VoiceService {
  VoiceService({required this._synth, required this._cacheDir});

  final SpeechSynthPort _synth;
  final Future<Directory> Function() _cacheDir;
  final _available = <String>{};
  Future<void>? _swept;

  /// Only an available voice is remembered: a missing one is asked again, so a voice downloaded meanwhile is used.
  Future<VoiceAvailability> availability(String language) async {
    if (_available.contains(language)) return VoiceAvailability.available;
    final VoiceAvailability answer;
    try {
      answer = await _synth.availability(language);
    } on SynthesisFailed {
      // No speech engine, or it wouldn't start: no voice for now (the card offers Install voice).
      return VoiceAvailability.unsupported;
    }
    if (answer == VoiceAvailability.available) _available.add(language);
    return answer;
  }

  /// Re-check a language later (after the user installs its voice).
  void forgetAvailability(String language) => _available.remove(language);

  /// Deletes files left by an earlier conversation; runs once, and synthesis waits for it.
  Future<void> sweep() => _swept ??= clear();

  /// Writes speech for [text] and returns the file path. Throws [VoiceMissing] when the phone can't speak [language].
  Future<String> synthesize({required String segmentId, required String text, required String language}) async {
    await sweep();
    if (await availability(language) != VoiceAvailability.available) throw VoiceMissing(language);
    final path = '${(await _folder()).path}${Platform.pathSeparator}$segmentId.wav';
    await _synth.synthesize(text: text, locale: language, path: path);
    return path;
  }

  /// Opens the phone's voice install screen, then forgets the cached answer so the next check is fresh.
  Future<bool> installVoice(String language) async {
    final opened = await _synth.openVoiceInstall(language);
    forgetAvailability(language);
    return opened;
  }

  Future<void> clear() async {
    final folder = await _folder();
    // Synchronous on purpose: it runs from dispose, and the files are small.
    if (folder.existsSync()) folder.deleteSync(recursive: true);
  }

  Future<Directory> _folder() async => Directory('${(await _cacheDir()).path}${Platform.pathSeparator}tts');
}

final voiceServiceProvider = Provider.autoDispose<VoiceService>(
  (ref) => VoiceService(synth: ref.watch(speechSynthProvider), cacheDir: getTemporaryDirectory),
);
