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
  var retries = List.filled(5, Duration.zero);

  setUp(() async {
    cache = await Directory.systemTemp.createTemp('anuvaad_dl_');
    dio = Dio();
    retries = List.filled(5, Duration.zero);
  });
  tearDown(() async {
    if (await cache.exists()) await cache.delete(recursive: true);
  });

  UpdateDownloader downloader(ResponseBody Function(RequestOptions) respond, {Directory? dir}) {
    server = _ByteServer(respond);
    dio.httpClientAdapter = server;
    return UpdateDownloader(dio: dio, cacheDirectory: () async => dir ?? cache, retryDelays: retries);
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

  /// A response that sends the first [count] bytes of [from] and then drops the connection.
  ResponseBody dropsAfter(int count, {int from = 0, int status = 200}) {
    final controller = StreamController<Uint8List>();
    controller.add(_bytes.sublist(from, from + count));
    scheduleMicrotask(() {
      controller.addError(const SocketException('connection reset'));
      controller.close();
    });
    return ResponseBody(controller.stream, status, headers: {
      Headers.contentLengthHeader: ['${_bytes.length - from}'],
    });
  }

  /// The rest of the file from the requested Range, as a server that supports resuming answers.
  ResponseBody rest(RequestOptions options) {
    final from = int.parse(RegExp(r'bytes=(\d+)-').firstMatch(options.headers['range'] as String)!.group(1)!);
    return ResponseBody.fromBytes(_bytes.sublist(from), 206, headers: {
      Headers.contentLengthHeader: ['${_bytes.length - from}'],
    });
  }

  test('a dropped connection resumes where it stopped, asking only for the missing bytes', () async {
    final ranges = <Object?>[];
    final progress = <int>[];
    final dl = downloader((options) {
      ranges.add(options.headers['range']);
      return ranges.length == 1 ? dropsAfter(100) : rest(options);
    });
    final file = await dl.download(_asset(), onProgress: (received, _) => progress.add(received));
    expect(file.readAsBytesSync(), _bytes);
    expect(ranges, [null, 'bytes=100-']);
    expect(progress.last, _bytes.length);
    expect(progress, orderedEquals([...progress]..sort()), reason: 'progress never goes backwards on a resume');
    expect(leftovers(), ['anuvaad-0.1.1-arm64-v8a.apk']);
  });

  test('a server that ignores the Range starts the file over instead of appending', () async {
    var calls = 0;
    final file = await downloader((options) => ++calls == 1 ? dropsAfter(100) : _ok(options)).download(
      _asset(),
      onProgress: (_, _) {},
    );
    expect(file.readAsBytesSync(), _bytes);
  });

  test('after the automatic retries it gives up but keeps what it has; Try again resumes', () async {
    var calls = 0;
    final failing = downloader((options) {
      if (++calls == 1) return dropsAfter(100);
      throw DioException.connectionError(requestOptions: options, reason: 'offline');
    });
    await expectLater(
      failing.download(_asset(), onProgress: (_, _) {}),
      throwsA(isA<UpdateDownloadException>().having((e) => e.cancelled, 'cancelled', isFalse)),
    );
    expect(calls, 6, reason: 'one try and five retries');
    expect(File('${cache.path}/updates/anuvaad-0.1.1-arm64-v8a.apk.part').lengthSync(), 100);

    final ranges = <Object?>[];
    final again = downloader((options) {
      ranges.add(options.headers['range']);
      return rest(options);
    });
    final file = await again.download(_asset(), onProgress: (_, _) {});
    expect(file.readAsBytesSync(), _bytes);
    expect(ranges, ['bytes=100-']);
  });

  test('a missing file (404) is not retried', () async {
    await expectLater(
      downloader((_) => ResponseBody.fromString('Not Found', 404)).download(_asset(), onProgress: (_, _) {}),
      throwsA(isA<UpdateDownloadException>()),
    );
    expect(server.requests, 1);
  });

  test('a leftover .part longer than the APK is thrown away and the download starts over', () async {
    Directory('${cache.path}/updates').createSync();
    File('${cache.path}/updates/anuvaad-0.1.1-arm64-v8a.apk.part').writeAsBytesSync([..._bytes, ..._bytes]);
    final ranges = <Object?>[];
    final file = await downloader((options) {
      ranges.add(options.headers['range']);
      return _ok(options);
    }).download(_asset(), onProgress: (_, _) {});
    expect(file.readAsBytesSync(), _bytes);
    expect(ranges, [null]);
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
