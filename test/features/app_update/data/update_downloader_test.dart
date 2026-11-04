import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:anuvaad/features/app_update/data/update_downloader.dart';
import 'package:anuvaad/features/app_update/domain/release_info.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test-only adapter serving raw bytes (the mock adapter JSON-encodes bodies).
class _ByteServer implements HttpClientAdapter {
  _ByteServer(this.respond);
  final ResponseBody Function(RequestOptions options) respond;
  int requests = 0;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests++;
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

final _bytes = Uint8List.fromList(utf8.encode('pretend this is an Anuvaad APK, ' * 64));

ApkAsset _asset({String? sha256Hex, int? size}) => ApkAsset(
      abi: 'arm64-v8a',
      file: 'anuvaad-0.1.1-arm64-v8a.apk',
      url: Uri.parse('https://github.com/test/anuvaad-app/releases/download/v0.1.1/anuvaad-0.1.1-arm64-v8a.apk'),
      size: size ?? _bytes.length,
      sha256: sha256Hex ?? sha256.convert(_bytes).toString(),
    );

ResponseBody _ok(RequestOptions _) => ResponseBody.fromBytes(_bytes, 200, headers: {
      Headers.contentLengthHeader: ['${_bytes.length}'],
    });

void main() {
  late Directory cache;
  late Dio dio;
  late _ByteServer server;

  setUp(() async {
    cache = await Directory.systemTemp.createTemp('anuvaad_dl_');
    dio = Dio();
  });
  tearDown(() async {
    if (await cache.exists()) await cache.delete(recursive: true);
  });

  UpdateDownloader downloader(ResponseBody Function(RequestOptions) respond, {Directory? dir}) {
    server = _ByteServer(respond);
    dio.httpClientAdapter = server;
    return UpdateDownloader(dio: dio, cacheDirectory: () async => dir ?? cache);
  }

  List<String> leftovers() {
    final updates = Directory('${cache.path}/updates');
    return updates.existsSync() ? updates.listSync().map((e) => e.uri.pathSegments.last).toList() : const [];
  }

  test('sha256OfFile matches the standard "abc" test vector', () async {
    final file = File('${cache.path}/abc.txt')..writeAsStringSync('abc');
    expect(await sha256OfFile(file), 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
  });

  test('downloads, verifies and returns the APK file', () async {
    final file = await downloader(_ok).download(_asset(), onProgress: (_, _) {});
    expect(file.readAsBytesSync(), _bytes);
    expect(file.path, endsWith('anuvaad-0.1.1-arm64-v8a.apk'));
    expect(leftovers(), ['anuvaad-0.1.1-arm64-v8a.apk']);
  });

  test('checksum mismatch throws UpdateIntegrityException and leaves no files', () async {
    final dl = downloader(_ok);
    await expectLater(
      dl.download(_asset(sha256Hex: 'b' * 64), onProgress: (_, _) {}),
      throwsA(isA<UpdateIntegrityException>()),
    );
    expect(leftovers(), isEmpty);
  });

  test('size mismatch throws UpdateIntegrityException', () async {
    await expectLater(
      downloader(_ok).download(_asset(size: _bytes.length + 1), onProgress: (_, _) {}),
      throwsA(isA<UpdateIntegrityException>()),
    );
    expect(leftovers(), isEmpty);
  });

  test('network error mid-way throws UpdateDownloadException and deletes the .part file', () async {
    ResponseBody broken(RequestOptions _) {
      final controller = StreamController<Uint8List>();
      controller.add(_bytes.sublist(0, 100));
      scheduleMicrotask(() {
        controller.addError(const SocketException('connection reset'));
        controller.close();
      });
      return ResponseBody(controller.stream, 200, headers: {
        Headers.contentLengthHeader: ['${_bytes.length}'],
      });
    }

    await expectLater(
      downloader(broken).download(_asset(), onProgress: (_, _) {}),
      throwsA(isA<UpdateDownloadException>().having((e) => e.cancelled, 'cancelled', isFalse)),
    );
    expect(leftovers(), isEmpty);
  });

  test('disk write failure surfaces as UpdateDownloadException and cleans up', () async {
    File('${cache.path}/updates').writeAsStringSync('not a directory');
    await expectLater(
      downloader(_ok).download(_asset(), onProgress: (_, _) {}),
      throwsA(isA<UpdateDownloadException>()),
    );
    expect(File('${cache.path}/updates').readAsStringSync(), 'not a directory');
    expect(File('${cache.path}/updates/anuvaad-0.1.1-arm64-v8a.apk.part').existsSync(), isFalse);
  });

  test('existing verified file is reused without a request', () async {
    Directory('${cache.path}/updates').createSync();
    File('${cache.path}/updates/anuvaad-0.1.1-arm64-v8a.apk').writeAsBytesSync(_bytes);
    final dl = downloader(_ok);
    final file = await dl.download(_asset(), onProgress: (_, _) {});
    expect(server.requests, 0);
    expect(file.readAsBytesSync(), _bytes);
  });

  test('a corrupt leftover file is replaced by a fresh download', () async {
    Directory('${cache.path}/updates').createSync();
    File('${cache.path}/updates/anuvaad-0.1.1-arm64-v8a.apk').writeAsStringSync('half a file');
    final dl = downloader(_ok);
    final file = await dl.download(_asset(), onProgress: (_, _) {});
    expect(server.requests, 1);
    expect(file.readAsBytesSync(), _bytes);
  });

  test('progress reports the final total', () async {
    final progress = <(int, int)>[];
    await downloader(_ok).download(_asset(), onProgress: (received, total) => progress.add((received, total)));
    expect(progress.last, (_bytes.length, _bytes.length));
  });

  test('cancelling marks the failure as cancelled and cleans up', () async {
    final token = CancelToken();
    ResponseBody slow(RequestOptions _) {
      final controller = StreamController<Uint8List>();
      controller.add(_bytes.sublist(0, 100));
      scheduleMicrotask(() => token.cancel('user cancelled'));
      return ResponseBody(controller.stream, 200, headers: {
        Headers.contentLengthHeader: ['${_bytes.length}'],
      });
    }

    await expectLater(
      downloader(slow).download(_asset(), onProgress: (_, _) {}, cancelToken: token),
      throwsA(isA<UpdateDownloadException>().having((e) => e.cancelled, 'cancelled', isTrue)),
    );
    expect(leftovers(), isEmpty);
  });

  test('clear removes downloaded updates', () async {
    final dl = downloader(_ok);
    await dl.download(_asset(), onProgress: (_, _) {});
    await dl.clear();
    expect(Directory('${cache.path}/updates').existsSync(), isFalse);
  });
}
