import 'dart:async';

import 'package:dio/dio.dart';

import '../domain/translation.dart';

enum CloudFailure {
  /// Network down, timeout, 5xx: worth falling back to offline translation.
  unavailable,

  /// 429 from the backend's per-install limit.
  rateLimited,

  /// 400 or 413: the backend refused this input.
  rejected,

  /// A 200 that doesn't match the contract.
  badResponse,
}

class CloudTranslationException implements Exception {
  const CloudTranslationException(this.kind);

  final CloudFailure kind;

  @override
  String toString() => 'CloudTranslationException(${kind.name})';
}

/// Translates through the Anuvaad backend, `POST /api/v1/translate`.
class CloudTranslator implements TranslatorPort {
  CloudTranslator({
    required this._dio,
    required Uri apiBaseUrl,
    required Map<String, String> clientHeaders,
    this._timeout = CloudTranslator.timeout,
  })  : _url = '$apiBaseUrl/api/v1/translate',
        _headers = clientHeaders;

  /// Longer than the backend's 5 s budget, so its provider fallback can finish.
  static const timeout = Duration(seconds: 7);

  final Dio _dio;
  final String _url;
  final Map<String, String> _headers;
  final Duration _timeout;

  @override
  Future<Translation> translate(TranslateRequest request) async {
    final Response<Object?> response;
    try {
      response = await _dio
          .post<Object?>(
            _url,
            data: {
              'segmentId': request.segmentId,
              'text': request.text,
              'sourceLanguage': request.sourceLanguage,
              'targetLanguage': request.targetLanguage,
            },
            options: Options(headers: _headers, contentType: Headers.jsonContentType, validateStatus: (_) => true),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const CloudTranslationException(CloudFailure.unavailable);
    } on DioException {
      throw const CloudTranslationException(CloudFailure.unavailable);
    }

    final status = response.statusCode ?? 0;
    if (status == 429) throw const CloudTranslationException(CloudFailure.rateLimited);
    if (status == 400 || status == 413) throw const CloudTranslationException(CloudFailure.rejected);
    if (status != 200) throw const CloudTranslationException(CloudFailure.unavailable);

    final body = response.data;
    if (body is! Map) throw const CloudTranslationException(CloudFailure.badResponse);
    final text = body['translatedText'];
    if (body['segmentId'] != request.segmentId || text is! String || text.trim().isEmpty) {
      throw const CloudTranslationException(CloudFailure.badResponse);
    }
    final provider = body['provider'];
    return Translation(
      segmentId: request.segmentId,
      text: text.trim(),
      provenance: TranslationProvenance.online,
      provider: provider is String ? provider : null,
    );
  }
}
