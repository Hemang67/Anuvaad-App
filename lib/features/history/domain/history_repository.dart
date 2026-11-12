import 'saved_conversation.dart';

/// Saved conversations on this phone (spec R12, R22, R26). Nothing here ever leaves the phone.
abstract interface class HistoryRepository {
  /// Newest first.
  Future<List<SavedConversation>> list();

  Future<SavedConversation?> get(String id);

  /// Adds the conversation, or replaces the one with the same id.
  Future<void> save(SavedConversation conversation);

  Future<void> delete(String id);

  Future<void> deleteAll();

  /// Conversations whose original or translated text contains [query], ignoring case. Empty lists everything.
  Future<List<SavedConversation>> search(String query);
}
