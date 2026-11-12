import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../services/language_registry/language.dart';
import '../../../services/language_registry/language_registry.dart';

/// `GET /api/v1/languages`: the backend's language catalogue (spec §7, R23).
class CatalogClient {
  CatalogClient({required this._dio, required Uri apiBaseUrl}) : _url = '$apiBaseUrl/api/v1/languages';

  final Dio _dio;
  final String _url;

  /// The languages not released yet, or null when the backend can't be reached or answers nonsense.
  Future<List<Language>?> fetchPlanned() async {
    try {
      final response = await _dio
          .get<Object?>(_url, options: Options(validateStatus: (_) => true))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;
      return parsePlannedLanguages(response.data, source: _url);
    } catch (error) {
      debugPrint('Language catalogue unavailable: $error');
      return null;
    }
  }
}
