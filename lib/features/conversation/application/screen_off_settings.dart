import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_providers.dart';

/// "Keep listening with the screen off" (on by default): the conversation service keeps the microphone when the
/// screen turns off or another app opens, with a notification while it runs.
class ScreenOffListeningController extends Notifier<bool> {
  @override
  bool build() => ref.watch(settingsRepositoryProvider).screenOffListening;

  Future<void> set(bool on) async {
    await ref.read(settingsRepositoryProvider).setScreenOffListening(on);
    state = on;
  }
}

final screenOffListeningProvider = NotifierProvider<ScreenOffListeningController, bool>(ScreenOffListeningController.new);

/// "Reply with your earphone button" (on by default): play/pause on the earphones starts and sends a reply.
class EarphoneButtonController extends Notifier<bool> {
  @override
  bool build() => ref.watch(settingsRepositoryProvider).earphoneButton;

  Future<void> set(bool on) async {
    await ref.read(settingsRepositoryProvider).setEarphoneButton(on);
    state = on;
  }
}

final earphoneButtonProvider = NotifierProvider<EarphoneButtonController, bool>(EarphoneButtonController.new);

/// "Reply without tapping" (off by default; needs language detection, Android 14+): when Listen hears my language,
/// that turn is my reply.
class AutoReplyController extends Notifier<bool> {
  @override
  bool build() => ref.watch(settingsRepositoryProvider).autoReply;

  Future<void> set(bool on) async {
    await ref.read(settingsRepositoryProvider).setAutoReply(on);
    state = on;
  }
}

final autoReplyProvider = NotifierProvider<AutoReplyController, bool>(AutoReplyController.new);
