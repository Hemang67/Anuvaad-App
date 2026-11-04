import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_providers.dart';

final onboardingCompleteProvider = NotifierProvider<OnboardingController, bool>(OnboardingController.new);

class OnboardingController extends Notifier<bool> {
  @override
  bool build() => ref.watch(settingsRepositoryProvider).onboardingComplete;

  Future<void> complete() async {
    await ref.read(settingsRepositoryProvider).setOnboardingComplete();
    state = true;
  }
}
