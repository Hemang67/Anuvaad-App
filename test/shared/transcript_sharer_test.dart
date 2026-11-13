import 'dart:io';

import 'package:anuvaad/shared/transcript_sharer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late List<String> handedOver;
  late FileTranscriptSharer sharer;

  setUp(() {
    root = Directory.systemTemp.createTempSync('anuvaad_share_test');
    handedOver = [];
    sharer = FileTranscriptSharer(cacheDir: () async => root, open: (path) async => handedOver.add(path));
  });
  tearDown(() => root.deleteSync(recursive: true));

  List<String> files() => [
        for (final f in Directory('${root.path}${Platform.pathSeparator}share').listSync()) f.uri.pathSegments.last,
      ];

  test('shares a file of our own, and only the latest share stays on the phone (M6)', () async {
    await sharer.shareText('first', fileName: 'anuvaad-a.txt');
    expect(File(handedOver.single).readAsStringSync(), 'first');
    await sharer.shareText('second', fileName: 'anuvaad-b.txt');
    expect(files(), ['anuvaad-b.txt']);
  });

  test('clearShared removes shared copies (deleting a conversation leaves none behind)', () async {
    await sharer.shareText('words', fileName: 'anuvaad-a.txt');
    await sharer.clearShared();
    expect(Directory('${root.path}${Platform.pathSeparator}share').existsSync(), isFalse);
    await sharer.clearShared();
  });
}
