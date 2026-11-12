import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_providers.dart';

/// "Review my reply before playing" (off by default): a translated reply waits for Edit, Play or Discard.
class ReviewReplyController extends Notifier<bool> {
  @override
  bool build() => ref.watch(settingsRepositoryProvider).reviewReply;

  Future<void> set(bool on) async {
    await ref.read(settingsRepositoryProvider).setReviewReply(on);
    state = on;
  }
}

final reviewReplyProvider = NotifierProvider<ReviewReplyController, bool>(ReviewReplyController.new);
