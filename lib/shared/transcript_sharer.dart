import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Hands text to Android's share sheet as a file (a transcript `.txt`, a latency `.csv`).
abstract interface class TranscriptSharer {
  Future<void> shareText(String text, {required String fileName});
}

class SharePlusTranscriptSharer implements TranscriptSharer {
  @override
  Future<void> shareText(String text, {required String fileName}) async {
    final type = fileName.endsWith('.csv') ? 'text/csv' : 'text/plain';
    await SharePlus.instance.share(ShareParams(
      files: [XFile.fromData(utf8.encode(text), mimeType: type, name: fileName)],
      fileNameOverrides: [fileName],
    ));
  }
}

final transcriptSharerProvider = Provider<TranscriptSharer>((ref) => SharePlusTranscriptSharer());
