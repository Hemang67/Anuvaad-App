import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/network/dio_provider.dart';
import '../domain/release_info.dart';

class UpdateDownloadException implements Exception {
  const UpdateDownloadException(this.message, {this.cancelled = false});
  final String message;
  final bool cancelled;

  @override
  String toString() => 'UpdateDownloadException: $message';
}

class UpdateIntegrityException implements Exception {
  const UpdateIntegrityException(this.message);
  final String message;

  @override
  String toString() => 'UpdateIntegrityException: $message';
}

/// Lowercase hex SHA-256 of [file], streamed.
Future<String> sha256OfFile(File file) async => (await sha256.bind(file.openRead()).first).toString();

/// Downloads an update APK into `<cache>/updates/` and only returns it once its
/// size and SHA-256 match the release manifest. A dropped connection resumes where it
/// stopped (an HTTP Range request), with a few automatic retries; what was received is
/// kept for "Try again". A cancelled, failed-checksum or unwritable download leaves nothing.
class UpdateDownloader {
  UpdateDownloader({required this._dio, required this._cacheDirectory, this.retryDelays = defaultRetryDelays});

  /// Waits before each automatic retry: a phone moving between cells usually reconnects within these.
  static const defaultRetryDelays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 15),
  ];

  final List<Duration> retryDelays;

  final Dio _dio;
  final Future<Directory> Function() _cacheDirectory;

  Future<Directory> _updatesDir() async => Directory('${(await _cacheDirectory()).path}/updates');

  Future<File> download(
    ApkAsset asset, {
    required void Function(int received, int total) onProgress,
    CancelToken? cancelToken,
  }) async {
    final dir = await _updatesDir();
    final target = File('${dir.path}/${asset.file}');
    final part = File('${target.path}.part');
    try {
      await dir.create(recursive: true);
      if (await target.exists()) {
        if (await _matches(target, asset)) {
          onProgress(asset.size, asset.size);
          return target;
        }
        await target.delete();
      }
      // Retries count only tries in a row that got nothing: a slow connection that keeps dropping but keeps
      // making progress carries on to the end.
      var failures = 0;
      while (true) {
        final before = await part.exists() ? await part.length() : 0;
        try {
          await _fetch(asset, part, onProgress: onProgress, cancelToken: cancelToken);
          break;
        } on Object catch (error) {
          final after = await part.exists() ? await part.length() : 0;
          failures = after > before ? 0 : failures + 1;
          if (!_retryable(error) || failures > retryDelays.length) rethrow;
          debugPrint('Update download interrupted ($error); retrying');
          await Future<void>.delayed(retryDelays[failures == 0 ? 0 : failures - 1]);
        }
      }
      if (!await _matches(part, asset)) {
        await _deleteQuietly(part);
        throw const UpdateIntegrityException('The downloaded file does not match the release checksum');
      }
      return await part.rename(target.path);
    } on UpdateIntegrityException {
      rethrow;
    } on DioException catch (e) {
      final cancelled = CancelToken.isCancel(e);
      // A connection that kept failing leaves what arrived for "Try again"; anything else starts over next time.
      if (cancelled || !_retryable(e)) await _deleteQuietly(part);
      throw UpdateDownloadException(e.message ?? e.error?.toString() ?? e.type.name, cancelled: cancelled);
    } on FileSystemException catch (e) {
      await _deleteQuietly(part);
      throw UpdateDownloadException(e.message);
    } on Object catch (e) {
      // The connection dropped mid-file (socket, TLS, HTTP errors): what arrived stays for "Try again".
      if (!_retryable(e)) await _deleteQuietly(part);
      throw UpdateDownloadException(e.toString());
    }
  }

  /// One request: the whole file, or with a partial file on disk only what is missing.
  Future<void> _fetch(
    ApkAsset asset,
    File part, {
    required void Function(int received, int total) onProgress,
    CancelToken? cancelToken,
  }) async {
    var start = await part.exists() ? await part.length() : 0;
    if (start > asset.size) {
      await part.delete(); // not this release's file
      start = 0;
    }
    final response = await _dio.get<ResponseBody>(
      asset.url.toString(),
      cancelToken: cancelToken,
      options: Options(
        responseType: ResponseType.stream,
        // Slow phone networks (two hosts: GitHub, then its file server) need longer than the quick update check.
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        headers: {if (start > 0) 'range': 'bytes=$start-'},
        validateStatus: (status) => status == 200 || status == 206 || status == 416,
      ),
    );
    final body = response.data!;
    if (response.statusCode == 416) {
      // Nothing left to send: the part is complete (the checksum decides), or not this file (starts over then).
      await body.stream.listen(null).cancel();
      return;
    }
    // 206 continues the part; 200 means the server ignored the Range: start over.
    final append = response.statusCode == 206 && start > 0;
    var received = append ? start : 0;
    final sink = part.openWrite(mode: append ? FileMode.append : FileMode.write);
    try {
      await _pipe(body.stream, cancelToken, (chunk) {
        sink.add(chunk);
        received += chunk.length;
        onProgress(received, asset.size);
      });
    } finally {
      await sink.flush();
      await sink.close();
    }
  }

  /// Copies [stream] until it ends; a cancel stops it at once (a stalled connection may never end by itself).
  static Future<void> _pipe(Stream<Uint8List> stream, CancelToken? cancelToken, void Function(Uint8List) onChunk) {
    final done = Completer<void>();
    late final StreamSubscription<Uint8List> subscription;
    subscription = stream.listen(
      onChunk,
      onError: (Object error, StackTrace trace) {
        if (!done.isCompleted) done.completeError(error, trace);
      },
      onDone: () {
        if (!done.isCompleted) done.complete();
      },
      cancelOnError: true,
    );
    cancelToken?.whenCancel.then((error) {
      if (done.isCompleted) return;
      unawaited(subscription.cancel());
      done.completeError(error);
    });
    return done.future;
  }

  /// Worth another try: the connection failed or dropped, or the server had a moment. Not a cancel, a missing file
  /// (4xx) or a full disk.
  static bool _retryable(Object error) => switch (error) {
        DioException(type: DioExceptionType.cancel) => false,
        DioException(type: DioExceptionType.badResponse, :final response) => (response?.statusCode ?? 0) >= 500,
        DioException() => true,
        FileSystemException() => false,
        SocketException() || HttpException() || HandshakeException() || TlsException() || TimeoutException() => true,
        _ => false,
      };

  /// Removes every downloaded update.
  Future<void> clear() async {
    final dir = await _updatesDir();
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  static Future<bool> _matches(File file, ApkAsset asset) async =>
      await file.length() == asset.size && await sha256OfFile(file) == asset.sha256;

  static Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // Nothing left to clean up.
    }
  }
}

final updateDownloaderProvider = Provider<UpdateDownloader>(
  (ref) => UpdateDownloader(dio: ref.watch(dioProvider), cacheDirectory: getApplicationCacheDirectory),
);
