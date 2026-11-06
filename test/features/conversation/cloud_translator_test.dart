import 'dart:io';

import 'package:anuvaad/app/bootstrap.dart';
import 'package:anuvaad/core/network/client_headers.dart';
import 'package:anuvaad/core/settings/settings_providers.dart';
import 'package:anuvaad/features/conversation/data/cloud_translator.dart';
import 'package:anuvaad/features/conversation/domain/translation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _api = 'https://api.anuvaad.test';
const _url = '$_api/api/v1/translate';
const _headers = {'X-Anuvaad-Install': 'install-1', 'X-Anuvaad-Version': '0.2.0+2'};
const _request = TranslateRequest(
  segmentId: 'seg-1',
  text: 'આપ આજે ક્યાં જઈ રહ્યા છો?',
  sourceLanguage: 'gu-IN',
  targetLanguage: 'hi-IN',
);

Map<String, Object?> _ok({String segmentId = 'seg-1', String text = 'आप आज कहाँ जा रहे हैं?'}) => {
      'segmentId': segmentId,
      'translatedText': text,
      'sourceLanguage': 'gu-IN',
      'targetLanguage': 'hi-IN',
      'provider': 'bhashini',
      'latencyMs': 640,
    };

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late List<RequestOptions> sent;

  setUp(() {
    dio = Dio();
    adapter = DioAdapter(dio: dio);
    sent = [];
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      sent.add(options);
      handler.next(options);
    }));
  });

  CloudTranslator translator({Duration timeout = CloudTranslator.timeout}) =>
      CloudTranslator(dio: dio, apiBaseUrl: Uri.parse(_api), clientHeaders: _headers, timeout: timeout);

  Future<CloudFailure> failureOf(Future<Translation> call) async {
    try {
      await call;
    } on CloudTranslationException catch (e) {
      return e.kind;
    }
    fail('expected a CloudTranslationException');
  }

  test('times out after 7 seconds by default', () {
    expect(CloudTranslator.timeout, const Duration(seconds: 7));
  });

  test('posts the contract body and headers and returns an online translation', () async {
    adapter.onPost(_url, (server) => server.reply(200, _ok()), data: Matchers.any);
    final result = await translator().translate(_request);

    expect(result.segmentId, 'seg-1');
    expect(result.text, 'आप आज कहाँ जा रहे हैं?');
    expect(result.provenance, TranslationProvenance.online);
    expect(result.provider, 'bhashini');
    expect(sent.single.data, {
      'segmentId': 'seg-1',
      'text': 'આપ આજે ક્યાં જઈ રહ્યા છો?',
      'sourceLanguage': 'gu-IN',
      'targetLanguage': 'hi-IN',
    });
    expect(sent.single.headers, containsPair('X-Anuvaad-Install', 'install-1'));
    expect(sent.single.headers, containsPair('X-Anuvaad-Version', '0.2.0+2'));
  });

  test('maps failures', () async {
    final cases = <int, CloudFailure>{
      429: CloudFailure.rateLimited,
      400: CloudFailure.rejected,
      413: CloudFailure.rejected,
      502: CloudFailure.unavailable,
      503: CloudFailure.unavailable,
    };
    for (final MapEntry(key: status, value: kind) in cases.entries) {
      adapter.onPost(_url, (server) => server.reply(status, {'error': {'code': 'x'}}), data: Matchers.any);
      expect(await failureOf(translator().translate(_request)), kind, reason: 'HTTP $status');
    }

    adapter.onPost(
      _url,
      (server) => server.throws(0, DioException.connectionError(requestOptions: RequestOptions(), reason: 'offline')),
      data: Matchers.any,
    );
    expect(await failureOf(translator().translate(_request)), CloudFailure.unavailable, reason: 'connection error');

    adapter.onPost(
      _url,
      (server) => server.throws(0, DioException(requestOptions: RequestOptions(), error: const SocketException('no route'))),
      data: Matchers.any,
    );
    expect(await failureOf(translator().translate(_request)), CloudFailure.unavailable, reason: 'socket');

    adapter.onPost(_url, (server) => server.reply(200, _ok(), delay: const Duration(milliseconds: 300)), data: Matchers.any);
    expect(await failureOf(translator(timeout: const Duration(milliseconds: 50)).translate(_request)),
        CloudFailure.unavailable,
        reason: 'timeout');

    adapter.onPost(_url, (server) => server.reply(200, _ok(segmentId: 'other')), data: Matchers.any);
    expect(await failureOf(translator().translate(_request)), CloudFailure.badResponse, reason: 'wrong segment');

    adapter.onPost(_url, (server) => server.reply(200, _ok(text: '  ')), data: Matchers.any);
    expect(await failureOf(translator().translate(_request)), CloudFailure.badResponse, reason: 'empty text');

    adapter.onPost(_url, (server) => server.reply(200, 'not json'), data: Matchers.any);
    expect(await failureOf(translator().translate(_request)), CloudFailure.badResponse, reason: 'not a map');
  });

  test('client headers carry the install id and app version', () async {
    SharedPreferences.setMockInitialValues({'install_id': 'install-42'});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      packageInfoProvider.overrideWithValue(PackageInfo(
        appName: 'Anuvaad',
        packageName: 'app.anuvaad',
        version: '0.2.0',
        buildNumber: '2',
      )),
    ]);
    addTearDown(container.dispose);
    expect(container.read(clientHeadersProvider), {'X-Anuvaad-Install': 'install-42', 'X-Anuvaad-Version': '0.2.0+2'});
  });
}
