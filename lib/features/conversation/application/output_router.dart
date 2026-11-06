import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../data/android_audio.dart';
import '../domain/audio_output.dart';

/// Where a role's spoken translations should go.
enum OutputPreference { earphones, speaker }

/// Earphone kinds in order of preference when several are connected: a plugged-in cable is the clearest choice.
const _earphoneOrder = [OutputKind.wired, OutputKind.usb, OutputKind.bluetooth];

/// The output for [role] given the user's [preference] and what is connected now.
/// Earphones fall back to the speaker; null only when Android lists no outputs (then Android chooses).
AudioOutput? resolveOutput(OutputRole role, OutputPreference preference, List<AudioOutput> outputs) {
  if (outputs.isEmpty) return null;
  AudioOutput? firstOf(OutputKind kind) {
    for (final output in outputs) {
      if (output.kind == kind) return output;
    }
    return null;
  }

  if (preference == OutputPreference.earphones) {
    for (final kind in _earphoneOrder) {
      if (firstOf(kind) case final earphones?) return earphones;
    }
  }
  return firstOf(OutputKind.speaker) ?? outputs.first;
}

/// The device's own name, or a type label when Android gives none.
String outputLabel(AudioOutput output, AppLocalizations l10n) {
  final name = output.name.trim();
  return switch (output.kind) {
    // Android names these after the phone model or a kernel switch ("h2w"); the app's labels are clearer.
    OutputKind.speaker => l10n.audioDeviceSpeaker,
    OutputKind.wired => l10n.audioDeviceWired,
    OutputKind.bluetooth => name.isNotEmpty ? name : l10n.audioDeviceBluetooth,
    OutputKind.usb => name.isNotEmpty ? name : l10n.audioDeviceUsb,
  };
}

/// Per-role preferences: earphones for you, speaker for the other person, unless changed in Audio devices.
class OutputPreferencesController extends Notifier<Map<OutputRole, OutputPreference>> {
  static const _defaults = {OutputRole.forMe: OutputPreference.earphones, OutputRole.forOther: OutputPreference.speaker};

  @override
  Map<OutputRole, OutputPreference> build() {
    final settings = ref.watch(settingsRepositoryProvider);
    return {
      for (final role in OutputRole.values)
        role: switch (settings.outputPreference(role.name)) {
          'earphones' => OutputPreference.earphones,
          'speaker' => OutputPreference.speaker,
          _ => _defaults[role]!,
        },
    };
  }

  Future<void> select(OutputRole role, OutputPreference preference) async {
    await ref.read(settingsRepositoryProvider).setOutputPreference(role.name, preference.name);
    state = {...state, role: preference};
  }
}

final outputPreferencesProvider =
    NotifierProvider<OutputPreferencesController, Map<OutputRole, OutputPreference>>(OutputPreferencesController.new);

/// Outputs connected right now: the current list, then every change Android reports.
final connectedOutputsProvider = StreamProvider<List<AudioOutput>>((ref) {
  final port = ref.watch(audioOutputProvider);
  final controller = StreamController<List<AudioOutput>>();
  var changed = false;
  final subscription = port.events.listen((event) {
    if (event is OutputsChanged) {
      changed = true;
      controller.add(event.outputs);
    }
  });
  port.outputs().then((outputs) {
    // A change that arrived first is newer than this initial read.
    if (!changed && !controller.isClosed) controller.add(outputs);
  }, onError: (Object error) {
    if (!controller.isClosed) controller.addError(error);
  });
  ref.onDispose(() {
    subscription.cancel();
    controller.close();
  });
  return controller.stream;
});
