import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen on while a conversation is running (spec §0.4: sessions run only while the app is on screen).
abstract interface class ScreenAwake {
  Future<void> keepOn(bool on);
}

class WakelockScreenAwake implements ScreenAwake {
  @override
  Future<void> keepOn(bool on) async {
    try {
      await WakelockPlus.toggle(enable: on);
    } catch (error) {
      // Not worth interrupting a conversation over: the screen may just turn off by itself.
      debugPrint('Could not ${on ? 'keep the screen on' : 'release the screen'}: $error');
    }
  }
}

final screenAwakeProvider = Provider<ScreenAwake>((ref) => WakelockScreenAwake());
