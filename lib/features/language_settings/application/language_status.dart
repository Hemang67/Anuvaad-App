import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/dio_provider.dart';
import '../../../services/language_registry/language.dart';
import '../../conversation/data/android_audio.dart';
import '../../conversation/data/android_speech_recognizer.dart';
import '../../conversation/data/offline_models.dart';
import '../../conversation/domain/voice.dart';
import '../data/catalog_client.dart';

/// What actually works for a core language on this phone (spec R23: real status, not "installed").
class LanguageStatus {
  const LanguageStatus({required this.speechInput, required this.offlineModel, required this.voice});

  /// The phone has a speech recognizer (online recognition; on-device depends on Android's packs).
  final bool speechInput;

  /// The ML Kit offline translation model is downloaded.
  final bool offlineModel;
  final VoiceAvailability voice;
}

final languageStatusProvider = FutureProvider.autoDispose.family<LanguageStatus, String>((ref, code) async {
  final recognizer = ref.watch(speechRecognizerProvider);
  final models = ref.watch(offlineModelsProvider);
  final synth = ref.watch(speechSynthProvider);
  final speech = await recognizer.isAvailable();
  final model = await models.isReady(code);
  VoiceAvailability voice;
  try {
    voice = await synth.availability(code);
  } catch (_) {
    voice = VoiceAvailability.unsupported; // no speech engine, or it wouldn't start
  }
  return LanguageStatus(speechInput: speech, offlineModel: model, voice: voice);
});

/// Future languages: from the backend's catalogue when reachable, else the bundled list.
final plannedLanguagesProvider = FutureProvider.autoDispose<List<Language>>((ref) async {
  final bundled = ref.watch(languageRegistryProvider).plannedLanguages;
  final api = ref.watch(appConfigProvider).apiBaseUrl;
  if (api == null) return bundled;
  final fetched = await CatalogClient(dio: ref.watch(dioProvider), apiBaseUrl: api).fetchPlanned();
  return fetched == null || fetched.isEmpty ? bundled : fetched;
});
