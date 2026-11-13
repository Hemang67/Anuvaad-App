import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/settings/settings_providers.dart';
import '../data/file_history_repository.dart';
import '../domain/history_repository.dart';
import '../domain/saved_conversation.dart';

final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => FileHistoryRepository(getApplicationSupportDirectory),
);

/// Bumped after a conversation is saved away from the history screens (End, Done, the app going to the
/// background, a translation arriving after Done): every list and detail watching it reads the files again.
class HistoryRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final historyRevisionProvider = NotifierProvider<HistoryRevision, int>(HistoryRevision.new);

/// Saved conversations, newest first. Invalidate after saving or deleting.
final historyListProvider = FutureProvider.autoDispose<List<SavedConversation>>((ref) {
  ref.watch(historyRevisionProvider);
  return ref.watch(historyRepositoryProvider).list();
});

/// Conversations matching a search ('' lists all), newest first.
final historySearchProvider = FutureProvider.autoDispose.family<List<SavedConversation>, String>((ref, query) {
  ref.watch(historyRevisionProvider);
  return ref.watch(historyRepositoryProvider).search(query);
});

/// One saved conversation, or null once deleted.
final savedConversationProvider = FutureProvider.autoDispose.family<SavedConversation?, String>((ref, id) {
  ref.watch(historyRevisionProvider);
  return ref.watch(historyRepositoryProvider).get(id);
});

/// After saving or deleting: every list and detail reads the files again.
void invalidateHistory(WidgetRef ref) {
  ref
    ..invalidate(historyListProvider)
    ..invalidate(historySearchProvider)
    ..invalidate(savedConversationProvider);
}

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
