import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_providers.dart';

/// Speech speed for translations (spec §5-10): Android's speech rate.
enum SpeechRate {
  slow(0.8),
  normal(1.0),
  fast(1.25);

  const SpeechRate(this.value);
  final double value;
}

class VoicePreferences {
  const VoicePreferences({this.rate = SpeechRate.normal, this.voices = const {}});

  final SpeechRate rate;

  /// Chosen voice name per language code; missing means the engine's default.
  final Map<String, String> voices;
}

class VoicePreferencesController extends Notifier<VoicePreferences> {
  @override
  VoicePreferences build() {
    final settings = ref.watch(settingsRepositoryProvider);
    return VoicePreferences(
      rate: SpeechRate.values.firstWhere((r) => r.name == settings.speechRate, orElse: () => SpeechRate.normal),
      voices: settings.voices,
    );
  }

  Future<void> setRate(SpeechRate rate) async {
    await ref.read(settingsRepositoryProvider).setSpeechRate(rate.name);
    state = VoicePreferences(rate: rate, voices: state.voices);
  }

  /// [name] null goes back to the engine's default voice.
  Future<void> setVoice(String language, String? name) async {
    await ref.read(settingsRepositoryProvider).setVoice(language, name);
    final voices = {...state.voices}..remove(language);
    if (name != null) voices[language] = name;
    state = VoicePreferences(rate: state.rate, voices: voices);
  }
}

final voicePreferencesProvider = NotifierProvider<VoicePreferencesController, VoicePreferences>(VoicePreferencesController.new);
