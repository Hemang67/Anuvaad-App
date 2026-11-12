import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Microphone loudness 0..1 while a turn is listening; 0 otherwise. Kept apart from the conversation state so the
/// waveform's frequent updates don't rebuild the whole screen.
class MicLevel extends Notifier<double> {
  @override
  double build() => 0;

  void set(double level) {
    if (level != state) state = level;
  }
}

final micLevelProvider = NotifierProvider<MicLevel, double>(MicLevel.new);
