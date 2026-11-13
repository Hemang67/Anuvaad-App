import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Hands text to Android's share sheet as a file (a transcript `.txt`, a latency `.csv`).
abstract interface class TranscriptSharer {
  Future<void> shareText(String text, {required String fileName});

  /// Removes any shared copy left in the app's cache (deleting conversations leaves no transcript behind).
  Future<void> clearShared();
}

/// Writes the text to `<cache>/share/<fileName>` and hands that file to the share sheet. Each share replaces the
/// previous file, so at most the latest one is on the phone, and [clearShared] removes it.
class FileTranscriptSharer implements TranscriptSharer {
  FileTranscriptSharer({Future<Directory> Function()? cacheDir, Future<void> Function(String path)? open})
      : _cacheDir = cacheDir ?? getTemporaryDirectory,
        _open = open ?? _shareFile;

  final Future<Directory> Function() _cacheDir;
  final Future<void> Function(String path) _open;

  static final _sep = Platform.pathSeparator;

  /// share_plus copies the file into its own cache folder, which it empties on the next share.
  static Future<void> _shareFile(String path) async {
    final name = path.split(_sep).last;
    final type = name.endsWith('.csv') ? 'text/csv' : 'text/plain';
    await SharePlus.instance.share(ShareParams(files: [XFile(path, mimeType: type)], fileNameOverrides: [name]));
  }

  @override
  Future<void> shareText(String text, {required String fileName}) async {
    // Synchronous file work: it is tiny, and widget tests can't finish real async file IO.
    final dir = Directory('${(await _cacheDir()).path}${_sep}share');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
    final safeName = fileName.replaceAll(RegExp(r'[\\/]'), '_');
    final file = File('${dir.path}$_sep$safeName')..writeAsStringSync(text, flush: true);
    await _open(file.path);
  }

  @override
  Future<void> clearShared() async {
    final root = (await _cacheDir()).path;
    for (final name in ['share', 'share_plus']) {
      final dir = Directory('$root$_sep$name');
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    }
  }
}

final transcriptSharerProvider = Provider<TranscriptSharer>((ref) => FileTranscriptSharer());
