import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../domain/history_repository.dart';
import '../domain/saved_conversation.dart';

/// One JSON file per conversation in `<root>/history/`, in app-private storage.
///
/// File work is synchronous inside the async methods: the files are small, and widget tests' fake-async zone never
/// completes real asynchronous file IO. Writes go to a `.tmp` file first and are then renamed, so a write cut short
/// (app killed) never leaves a half-written conversation; anything unreadable is skipped, not fatal.
class FileHistoryRepository implements HistoryRepository {
  FileHistoryRepository(this._root);

  final Future<Directory> Function() _root;

  static final _safeId = RegExp(r'^[A-Za-z0-9_-]+$');

  Future<Directory> _folder() async {
    final folder = Directory('${(await _root()).path}${Platform.pathSeparator}history');
    if (!folder.existsSync()) folder.createSync(recursive: true);
    return folder;
  }

  Future<File> _file(String id) async {
    if (!_safeId.hasMatch(id)) throw ArgumentError.value(id, 'id', 'not a conversation id');
    return File('${(await _folder()).path}${Platform.pathSeparator}$id.json');
  }

  SavedConversation? _read(File file) {
    try {
      final json = jsonDecode(file.readAsStringSync());
      if (json is! Map) throw const FormatException('not an object');
      return SavedConversation.fromJson(json.cast<String, Object?>());
    } catch (error) {
      debugPrint('Skipping unreadable history file ${file.path}: $error');
      return null;
    }
  }

  @override
  Future<List<SavedConversation>> list() async {
    final folder = await _folder();
    final all = [
      for (final entry in folder.listSync())
        if (entry is File && entry.path.endsWith('.json')) ?_read(entry),
    ]..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return all;
  }

  @override
  Future<SavedConversation?> get(String id) async {
    if (!_safeId.hasMatch(id)) return null;
    final file = await _file(id);
    return file.existsSync() ? _read(file) : null;
  }

  @override
  Future<void> save(SavedConversation conversation) async {
    final file = await _file(conversation.id);
    final temp = File('${file.path}.tmp')..writeAsStringSync(jsonEncode(conversation.toJson()), flush: true);
    if (file.existsSync()) file.deleteSync();
    temp.renameSync(file.path);
  }

  @override
  Future<void> delete(String id) async {
    final file = await _file(id);
    if (file.existsSync()) file.deleteSync();
  }

  @override
  Future<void> deleteAll() async {
    final folder = await _folder();
    folder.deleteSync(recursive: true);
  }

  @override
  Future<List<SavedConversation>> search(String query) async {
    final needle = query.trim().toLowerCase();
    final all = await list();
    if (needle.isEmpty) return all;
    bool hit(String? text) => text != null && text.toLowerCase().contains(needle);
    return [
      for (final c in all)
        if (c.segments.any((s) => hit(s.text) || hit(s.translation))) c,
    ];
  }
}
