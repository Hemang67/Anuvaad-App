import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/settings/settings_providers.dart';
import '../data/file_history_repository.dart';
import '../domain/history_repository.dart';
import '../domain/saved_conversation.dart';

final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => FileHistoryRepository(getApplicationSupportDirectory),
);

/// Saved conversations, newest first. Invalidate after saving or deleting.
final historyListProvider = FutureProvider.autoDispose<List<SavedConversation>>(
  (ref) => ref.watch(historyRepositoryProvider).list(),
);

/// "Save conversations" in Settings: off by default; on means every ended conversation is kept on the phone.
class SaveHistoryController extends Notifier<bool> {
  @override
  bool build() => ref.watch(settingsRepositoryProvider).saveHistory;

  Future<void> set(bool on) async {
    await ref.read(settingsRepositoryProvider).setSaveHistory(on);
    state = on;
  }
}

final saveHistoryProvider = NotifierProvider<SaveHistoryController, bool>(SaveHistoryController.new);
