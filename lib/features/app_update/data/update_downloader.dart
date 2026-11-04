import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
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
/// size and SHA-256 match the release manifest. Partial files never survive a failure.
class UpdateDownloader {
  UpdateDownloader({required this._dio, required this._cacheDirectory});

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
      await _dio.download(
        asset.url.toString(),
        part.path,
        cancelToken: cancelToken,
        deleteOnError: true,
        options: Options(receiveTimeout: const Duration(seconds: 30)),
        onReceiveProgress: (received, total) => onProgress(received, total > 0 ? total : asset.size),
      );
      if (!await _matches(part, asset)) {
        await _deleteQuietly(part);
        throw const UpdateIntegrityException('The downloaded file does not match the release checksum');
      }
      return await part.rename(target.path);
    } on UpdateIntegrityException {
      rethrow;
    } on DioException catch (e) {
      await _deleteQuietly(part);
      throw UpdateDownloadException(e.message ?? e.type.name, cancelled: CancelToken.isCancel(e));
    } on FileSystemException catch (e) {
      await _deleteQuietly(part);
      throw UpdateDownloadException(e.message);
    }
  }

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
