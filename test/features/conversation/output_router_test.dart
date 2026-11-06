import 'package:anuvaad/core/settings/settings_providers.dart';
import 'package:anuvaad/features/conversation/application/output_router.dart';
import 'package:anuvaad/features/conversation/data/android_audio.dart';
import 'package:anuvaad/features/conversation/domain/audio_output.dart';
import 'package:anuvaad/l10n/app_localizations_en.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/conversation_fakes.dart';

const _usb = AudioOutput(id: 4, kind: OutputKind.usb, name: '');

void main() {
  group('resolveOutput', () {
    test('earphones prefers wired, then usb, then bluetooth, else the speaker', () {
      AudioOutput? pick(List<AudioOutput> outputs) => resolveOutput(OutputRole.forMe, OutputPreference.earphones, outputs);
      expect(pick([fakeSpeaker, fakeBuds, _usb, fakeWired]), fakeWired);
      expect(pick([fakeSpeaker, fakeBuds, _usb]), _usb);
      expect(pick([fakeSpeaker, fakeBuds]), fakeBuds);
      expect(pick([fakeSpeaker]), fakeSpeaker);
    });

    test('speaker preference always picks the speaker even with earphones connected', () {
      expect(resolveOutput(OutputRole.forOther, OutputPreference.speaker, [fakeBuds, fakeSpeaker, fakeWired]), fakeSpeaker);
    });

    test('an empty list resolves to null', () {
      expect(resolveOutput(OutputRole.forMe, OutputPreference.earphones, const []), isNull);
      expect(resolveOutput(OutputRole.forOther, OutputPreference.speaker, const []), isNull);
    });
  });

  test('labels fall back to the type when the device has no name', () {
    final l10n = AppLocalizationsEn();
    expect(outputLabel(fakeBuds, l10n), 'Galaxy Buds');
    expect(outputLabel(fakeSpeaker, l10n), 'Phone speaker');
    expect(outputLabel(const AudioOutput(id: 7, kind: OutputKind.wired, name: ''), l10n), 'Wired earphones');
    expect(outputLabel(const AudioOutput(id: 8, kind: OutputKind.bluetooth, name: ' '), l10n), 'Bluetooth earphones');
    expect(outputLabel(_usb, l10n), 'USB earphones');
  });

  test('preferences default to earphones for me and speaker for the other person, and persist', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    ProviderContainer make() => ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);

    final first = make();
    expect(first.read(outputPreferencesProvider), {
      OutputRole.forMe: OutputPreference.earphones,
      OutputRole.forOther: OutputPreference.speaker,
    });
    await first.read(outputPreferencesProvider.notifier).select(OutputRole.forMe, OutputPreference.speaker);
    expect(first.read(outputPreferencesProvider)[OutputRole.forMe], OutputPreference.speaker);
    first.dispose();

    final second = make();
    addTearDown(second.dispose);
    expect(second.read(outputPreferencesProvider)[OutputRole.forMe], OutputPreference.speaker);
    expect(second.read(outputPreferencesProvider)[OutputRole.forOther], OutputPreference.speaker);
  });

  test('connected outputs start from the list and follow OutputsChanged', () async {
    final port = FakeAudioOutput(connected: [fakeSpeaker]);
    final container = ProviderContainer(overrides: [audioOutputProvider.overrideWithValue(port)]);
    addTearDown(container.dispose);
    final seen = <List<AudioOutput>>[];
    container.listen(connectedOutputsProvider, (_, next) {
      if (next.value case final outputs?) seen.add(outputs);
    }, fireImmediately: true);
    await pumpEventQueue();
    port.setOutputs([fakeSpeaker, fakeBuds]);
    await pumpEventQueue();
    expect(seen.first, [fakeSpeaker]);
    expect(seen.last, [fakeSpeaker, fakeBuds]);
  });
}
