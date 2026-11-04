import 'dart:convert';
import 'dart:io';

import 'package:anuvaad/features/app_update/data/update_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

const _api = 'https://api.anuvaad.test';
const _repo = 'test/anuvaad-app';
const _latestUrl = '$_api/api/v1/app/latest';
const _releasesUrl = '$_api/api/v1/app/releases';
const _ghLatest = 'https://api.github.com/repos/$_repo/releases/latest';
const _ghList = 'https://api.github.com/repos/$_repo/releases';
const _manifestUrl = 'https://github.com/test/anuvaad-app/releases/download/v0.1.1/release.json';
const _headers = {'X-Anuvaad-Install': 'install-1', 'X-Anuvaad-Version': '0.1.0+1'};

Map<String, Object?> _json(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync()) as Map<String, Object?>;

/// A release fixture with a different build (for list tests).
Map<String, Object?> _releaseWithBuild(int build) => {..._json('release_0_1_1.json'), 'version': '0.1.$build', 'build': build};

void main() {
  late Dio dio;
  late DioAdapter adapter;

  setUp(() {
    dio = Dio();
    adapter = DioAdapter(dio: dio);
  });

  UpdateRepository repo({String? api = _api, String? releasesRepo = _repo}) => UpdateRepository(
        dio: dio,
        apiBaseUrl: api == null ? null : Uri.parse(api),
        releasesRepo: releasesRepo,
        clientHeaders: _headers,
      );

  void githubServesLatest({Map<String, Object?>? release, Object? manifest}) {
    adapter.onGet(_ghLatest, (server) => server.reply(200, release ?? _json('github_release_latest.json')));
    adapter.onGet(_manifestUrl, (server) => server.reply(200, manifest ?? _json('release_manifest_0_1_1.json')));
  }

  test('returns backend release on 200', () async {
    adapter.onGet(_latestUrl, (server) => server.reply(200, {'release': _json('release_0_1_1.json')}));
    final info = await repo().fetchLatest();
    expect(info!.build, 2);
    expect(info.version, '0.1.1');
  });

  test('returns null on backend 404 without calling GitHub', () async {
    adapter.onGet(_latestUrl, (server) => server.reply(404, {'error': {'code': 'no_release'}}));
    expect(await repo().fetchLatest(), isNull);
  });

  test('falls back to GitHub on backend 503 and resolves asset URLs', () async {
    adapter.onGet(_latestUrl, (server) => server.reply(503, {'error': {'code': 'unavailable'}}));
    githubServesLatest();
    final info = await repo().fetchLatest();
    expect(info!.assets.first.url.toString(),
        'https://github.com/test/anuvaad-app/releases/download/v0.1.1/anuvaad-0.1.1-arm64-v8a.apk');
    expect(info.releaseUrl.toString(), 'https://github.com/test/anuvaad-app/releases/tag/v0.1.1');
  });

  test('falls back to GitHub when backend JSON is malformed', () async {
    final broken = _json('release_0_1_1.json')..['schema'] = 99;
    adapter.onGet(_latestUrl, (server) => server.reply(200, {'release': broken}));
    githubServesLatest();
    expect((await repo().fetchLatest())!.schema, 1);
  });

  test('falls back to GitHub when the backend times out', () async {
    adapter.onGet(_latestUrl, (server) => server.throws(
          408,
          DioException.connectionTimeout(timeout: const Duration(seconds: 6), requestOptions: RequestOptions(path: _latestUrl)),
        ));
    githubServesLatest();
    expect((await repo().fetchLatest())!.build, 2);
  });

  test('uses GitHub directly when no backend is configured', () async {
    githubServesLatest();
    expect((await repo(api: null).fetchLatest())!.build, 2);
  });

  test('returns null when the GitHub release has no release.json', () async {
    final release = _json('github_release_latest.json');
    release['assets'] = (release['assets']! as List<Object?>)
        .where((a) => (a! as Map<String, Object?>)['name'] != 'release.json')
        .toList();
    adapter.onGet(_ghLatest, (server) => server.reply(200, release));
    expect(await repo(api: null).fetchLatest(), isNull);
  });

  test('returns null when a listed APK was not uploaded to the GitHub release', () async {
    final release = _json('github_release_latest.json');
    release['assets'] = (release['assets']! as List<Object?>)
        .where((a) => (a! as Map<String, Object?>)['name'] != 'anuvaad-0.1.1-universal.apk')
        .toList();
    githubServesLatest(release: release);
    expect(await repo(api: null).fetchLatest(), isNull);
  });

  test('returns null when GitHub has no published release', () async {
    adapter.onGet(_ghLatest, (server) => server.reply(404, {'message': 'Not Found'}));
    expect(await repo(api: null).fetchLatest(), isNull);
  });

  test('throws UpdateCheckException when both sources fail', () async {
    adapter.onGet(_latestUrl, (server) => server.reply(500, 'oops'));
    adapter.onGet(_ghLatest, (server) => server.reply(500, 'oops'));
    await expectLater(repo().fetchLatest(), throwsA(isA<UpdateCheckException>()));
  });

  test('throws UpdateCheckException when no update source is configured', () async {
    await expectLater(repo(api: null, releasesRepo: null).fetchLatest(), throwsA(isA<UpdateCheckException>()));
  });

  test('fetchAll skips invalid releases and sorts newest first', () async {
    final invalid = _releaseWithBuild(3)..['schema'] = 7;
    adapter.onGet(_releasesUrl, (server) => server.reply(200, {
          'releases': [_releaseWithBuild(1), invalid, _releaseWithBuild(2)],
        }));
    final all = await repo().fetchAll();
    expect(all.map((r) => r.build), [2, 1]);
  });

  test('fetchAll falls back to the GitHub list, skipping drafts and prereleases', () async {
    adapter.onGet(_releasesUrl, (server) => server.reply(502, 'bad gateway'));
    final published = _json('github_release_latest.json');
    adapter.onGet(
      _ghList,
      (server) => server.reply(200, [
        {...published, 'draft': true},
        {...published, 'prerelease': true},
        published,
      ]),
      queryParameters: {'per_page': 20},
    );
    adapter.onGet(_manifestUrl, (server) => server.reply(200, _json('release_manifest_0_1_1.json')));
    final all = await repo().fetchAll();
    expect(all.map((r) => r.build), [2]);
  });

  test('sends install and version headers to the backend', () async {
    adapter.onGet(
      _latestUrl,
      (server) => server.reply(200, {'release': _json('release_0_1_1.json')}),
      headers: _headers,
    );
    expect((await repo().fetchLatest())!.build, 2);
  });
}
