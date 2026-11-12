import 'package:anuvaad/features/conversation/data/android_audio.dart';
import 'package:anuvaad/features/conversation/data/android_speech_recognizer.dart';
import 'package:anuvaad/features/conversation/data/offline_models.dart';
import 'package:anuvaad/features/conversation/domain/voice.dart';
import 'package:anuvaad/features/language_settings/application/language_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/conversation_fakes.dart';

void main() {
  test('status reflects model, voice and recognizer', () async {
    final recognizer = FakeSpeechRecognizer();
    final synth = FakeSpeechSynth()..availabilityByLocale['gu-IN'] = VoiceAvailability.needsDownload;
    final container = ProviderContainer(overrides: [
      speechRecognizerProvider.overrideWithValue(recognizer),
      offlineModelsProvider.overrideWithValue(OfflineModels(FakeOfflineModelStore(downloaded: {'en'}))),
      speechSynthProvider.overrideWithValue(synth),
    ]);
    addTearDown(container.dispose);

    final en = await container.read(languageStatusProvider('en-IN').future);
    expect((en.speechInput, en.offlineModel, en.voice), (true, true, VoiceAvailability.available));
    final hi = await container.read(languageStatusProvider('hi-IN').future);
    expect(hi.offlineModel, isFalse);
    final gu = await container.read(languageStatusProvider('gu-IN').future);
    expect(gu.voice, VoiceAvailability.needsDownload);

    recognizer.available = false;
    container.invalidate(languageStatusProvider);
    expect((await container.read(languageStatusProvider('en-IN').future)).speechInput, isFalse);
  });
}
