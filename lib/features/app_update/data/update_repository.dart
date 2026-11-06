import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/client_headers.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/release_info.dart';

class UpdateCheckException implements Exception {
  const UpdateCheckException(this.message);
  final String message;

  @override
  String toString() => 'UpdateCheckException: $message';
}

const _backendTimeout = Duration(seconds: 6);
const _githubApi = 'https://api.github.com';
const _githubHeaders = {'Accept': 'application/vnd.github+json'};

/// Reads release information from the Anuvaad backend, falling back to the
/// public GitHub Releases API when the backend is unreachable or returns bad data.
class UpdateRepository {
  UpdateRepository({
    required this._dio,
    required Uri? apiBaseUrl,
    required String? releasesRepo,
    required this._clientHeaders,
  })  : _api = apiBaseUrl,
        _repo = releasesRepo;

  final Dio _dio;
  final Uri? _api;
  final String? _repo;
  final Map<String, String> _clientHeaders;

  /// Latest published release, or null when none is published.
  Future<ReleaseInfo?> fetchLatest() async {
    _requireSource();
    final api = _api;
    if (api != null) {
      final backend = await _backend(api, '/api/v1/app/latest');
      if (backend is _Found && backend.status == 404 && _isNoRelease(backend.body)) return null;
      if (backend is _Found && backend.status == 200) {
        try {
          return parseReleaseInfo(_asMap(_asMap(backend.body)['release']));
        } on FormatException {
          // Bad backend data: fall through to GitHub.
        }
      }
    }
    final repo = _repo;
    if (repo == null) throw const UpdateCheckException('Release information is unavailable');
    try {
      final response = await _dio.get<Object?>(
        '$_githubApi/repos/$repo/releases/latest',
        options: Options(headers: _githubHeaders, validateStatus: (_) => true),
      );
      if (response.statusCode == 404) return null;
      if (response.statusCode != 200) throw UpdateCheckException('GitHub returned ${response.statusCode}');
      return await _resolveGitHubRelease(_asMap(response.data));
    } on DioException catch (e) {
      throw UpdateCheckException('GitHub unreachable: ${e.type.name}');
    } on FormatException catch (e) {
      throw UpdateCheckException('GitHub returned bad data: ${e.message}');
    }
  }

  /// Every valid published release, newest build first.
  Future<List<ReleaseInfo>> fetchAll() async {
    _requireSource();
    final api = _api;
    if (api != null) {
      final backend = await _backend(api, '/api/v1/app/releases');
      if (backend is _Found && backend.status == 200) {
        try {
          final items = _asMap(backend.body)['releases'];
          if (items is List<Object?>) return _sorted(items.map(_tryParse).whereType<ReleaseInfo>());
        } on FormatException {
          // Fall through to GitHub.
        }
      }
    }
    final repo = _repo;
    if (repo == null) throw const UpdateCheckException('Release information is unavailable');
    try {
      final response = await _dio.get<Object?>(
        '$_githubApi/repos/$repo/releases',
        queryParameters: {'per_page': 20},
        options: Options(headers: _githubHeaders, validateStatus: (_) => true),
      );
      final data = response.data;
      if (response.statusCode != 200 || data is! List<Object?>) {
        throw UpdateCheckException('GitHub returned ${response.statusCode}');
      }
      final releases = <ReleaseInfo>[];
      for (final item in data) {
        final release = await _resolveGitHubRelease(_asMap(item));
        if (release != null) releases.add(release);
      }
      return _sorted(releases);
    } on DioException catch (e) {
      throw UpdateCheckException('GitHub unreachable: ${e.type.name}');
    } on FormatException catch (e) {
      throw UpdateCheckException('GitHub returned bad data: ${e.message}');
    }
  }

  void _requireSource() {
    if (_api == null && _repo == null) throw const UpdateCheckException('Update source not configured');
  }

  /// A backend response (any status), or a failure meaning "try GitHub".
  Future<_BackendResult> _backend(Uri api, String path) async {
    try {
      final response = await _dio.get<Object?>(
        api.replace(path: '${api.path}$path').toString(),
        options: Options(
          headers: _clientHeaders,
          validateStatus: (_) => true,
          receiveTimeout: _backendTimeout,
          sendTimeout: _backendTimeout,
        ),
      );
      final status = response.statusCode ?? 0;
      if (status == 200 || status == 404) return _Found(status, response.data);
      return const _Failed();
    } on DioException {
      return const _Failed();
    }
  }

  /// Builds ReleaseInfo from a GitHub release; null when it is not a usable release.
  Future<ReleaseInfo?> _resolveGitHubRelease(Map<String, Object?> release) async {
    if (release['draft'] == true || release['prerelease'] == true) return null;
    final assets = <String, String>{};
    for (final asset in (release['assets'] as List<Object?>?) ?? const []) {
      final map = _asMap(asset);
      final name = map['name'];
      final url = map['browser_download_url'];
      if (name is String && url is String) assets[name] = url;
    }
    final manifestUrl = assets['release.json'];
    if (manifestUrl == null) return null;

    final response = await _dio.get<String>(
      manifestUrl,
      options: Options(responseType: ResponseType.plain, validateStatus: (_) => true),
    );
    if (response.statusCode != 200 || response.data == null) return null;
    final Map<String, Object?> manifest;
    try {
      manifest = _asMap(jsonDecode(response.data!));
    } on FormatException {
      return null;
    }

    final enriched = <Object?>[];
    for (final asset in (manifest['assets'] as List<Object?>?) ?? const []) {
      final map = _asMap(asset);
      final url = assets[map['file']];
      if (url == null) return null; // listed APK was not uploaded
      enriched.add({...map, 'url': url});
    }
    return _tryParse({...manifest, 'assets': enriched, 'releaseUrl': release['html_url']});
  }

  /// Only the backend's own `no_release` answer means nothing is published; any other
  /// 404 (e.g. a removed deployment) is treated as "backend unavailable".
  static bool _isNoRelease(Object? body) {
    try {
      return _asMap(_asMap(body)['error'])['code'] == 'no_release';
    } on FormatException {
      return false;
    }
  }

  static ReleaseInfo? _tryParse(Object? json) {
    try {
      return parseReleaseInfo(_asMap(json));
    } on FormatException {
      return null;
    }
  }

  static List<ReleaseInfo> _sorted(Iterable<ReleaseInfo> releases) =>
      releases.toList()..sort((a, b) => b.build.compareTo(a.build));

  static Map<String, Object?> _asMap(Object? value) {
    if (value is Map<String, Object?>) return value;
    if (value is Map) return value.map((k, v) => MapEntry('$k', v));
    throw const FormatException('expected a JSON object');
  }
}

sealed class _BackendResult {
  const _BackendResult();
}

class _Found extends _BackendResult {
  const _Found(this.status, this.body);
  final int status;
  final Object? body;
}

class _Failed extends _BackendResult {
  const _Failed();
}

final updateRepositoryProvider = Provider<UpdateRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return UpdateRepository(
    dio: ref.watch(dioProvider),
    apiBaseUrl: config.apiBaseUrl,
    releasesRepo: config.releasesRepo,
    clientHeaders: ref.watch(clientHeadersProvider),
  );
});
