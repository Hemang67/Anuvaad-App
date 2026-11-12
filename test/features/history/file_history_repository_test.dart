import 'dart:io';

import 'package:anuvaad/features/conversation/domain/segment.dart';
import 'package:anuvaad/features/conversation/domain/translation.dart';
import 'package:anuvaad/features/history/data/file_history_repository.dart';
import 'package:anuvaad/features/history/domain/saved_conversation.dart';
import 'package:flutter_test/flutter_test.dart';

SavedConversation conversation(String id, DateTime startedAt, {String text = 'नमस्ते', String? translation = 'Hello'}) =>
    SavedConversation(
      id: id,
      startedAt: startedAt,
      endedAt: startedAt.add(const Duration(minutes: 3)),
      myLanguage: 'en-IN',
      otherLanguages: const ['hi-IN'],
      mode: ConversationMode.inPerson,
      segments: [
        SavedSegment(
          id: '$id-1',
          seq: 1,
          speaker: Speaker.other,
          sourceLanguage: 'hi-IN',
          targetLanguage: 'en-IN',
          text: text,
          translation: translation,
          provenance: translation == null ? null : TranslationProvenance.online,
          at: startedAt.add(const Duration(seconds: 5)),
        ),
        SavedSegment(
          id: '$id-2',
          seq: 2,
          speaker: Speaker.me,
          sourceLanguage: 'en-IN',
          targetLanguage: 'hi-IN',
          text: 'Fine',
          unclear: false,
          at: startedAt.add(const Duration(seconds: 20)),
        ),
      ],
    );

void main() {
  late Directory root;
  late FileHistoryRepository repo;

  setUp(() {
    root = Directory.systemTemp.createTempSync('anuvaad_history_test');
    repo = FileHistoryRepository(() async => root);
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  File file(String name) => File('${root.path}${Platform.pathSeparator}history${Platform.pathSeparator}$name');

  test('save, list newest first, get, delete, deleteAll', () async {
    await repo.save(conversation('a', DateTime(2026, 11, 5, 9)));
    await repo.save(conversation('b', DateTime(2026, 11, 6, 9)));
    expect((await repo.list()).map((c) => c.id), ['b', 'a']);

    final a = await repo.get('a');
    expect(a!.segments.first.text, 'नमस्ते');
    expect(a.segments.first.translation, 'Hello');
    expect(a.segments.first.provenance, TranslationProvenance.online);
    expect(a.segments.last.speaker, Speaker.me);
    expect(a.segments.last.translation, isNull);
    expect(a.endedAt, DateTime(2026, 11, 5, 9, 3));
    expect(await repo.get('missing'), isNull);

    await repo.delete('a');
    expect((await repo.list()).map((c) => c.id), ['b']);
    await repo.deleteAll();
    expect(await repo.list(), isEmpty);
  });

  test('saving again replaces the conversation', () async {
    await repo.save(conversation('a', DateTime(2026, 11, 5, 9), translation: null));
    await repo.save(conversation('a', DateTime(2026, 11, 5, 9)));
    final all = await repo.list();
    expect(all, hasLength(1));
    expect(all.single.segments.first.translation, 'Hello');
  });

  test('search matches original and translation text, any case', () async {
    await repo.save(conversation('a', DateTime(2026, 11, 5, 9), text: 'Where is the STATION?', translation: 'स्टेशन कहाँ है?'));
    await repo.save(conversation('b', DateTime(2026, 11, 6, 9)));
    expect((await repo.search('station')).map((c) => c.id), ['a']);
    expect((await repo.search('स्टेशन')).map((c) => c.id), ['a']);
    expect((await repo.search('hello')).map((c) => c.id), ['b']);
    expect((await repo.search('  ')).map((c) => c.id), ['b', 'a'], reason: 'an empty search lists everything');
  });

  test('a corrupt history file is skipped, the rest still load', () async {
    await repo.save(conversation('a', DateTime(2026, 11, 5, 9)));
    file('broken.json').writeAsStringSync('{"schema": 1, "id": "broken", "startedAt": ');
    file('wrong.json').writeAsStringSync('{"schema": 99}');
    final all = await repo.list();
    expect(all.map((c) => c.id), ['a']);
    expect(await repo.get('broken'), isNull);
  });

  test('a leftover .tmp file is ignored', () async {
    await repo.save(conversation('a', DateTime(2026, 11, 5, 9)));
    file('z.json.tmp').writeAsStringSync('{"half": ');
    expect((await repo.list()).map((c) => c.id), ['a']);
  });

  test('ids that would escape the folder are refused', () async {
    expect(() => repo.save(conversation('../evil', DateTime(2026, 11, 5, 9))), throwsArgumentError);
  });
}
