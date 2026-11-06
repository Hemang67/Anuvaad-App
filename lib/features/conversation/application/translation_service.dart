import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/client_headers.dart';
import '../../../core/network/dio_provider.dart';
import '../data/cloud_translator.dart';
import '../data/mlkit_translator.dart';
import '../domain/translation.dart';

/// Neither the backend nor the phone could translate this segment.
class TranslationUnavailable implements Exception {
  const TranslationUnavailable({required this.offlineNotReady});

  /// True when the offline models haven't downloaded yet (the UI asks for Wi-Fi once).
  final bool offlineNotReady;

  @override
  String toString() => 'TranslationUnavailable(offlineNotReady: $offlineNotReady)';
}

/// Translator selection policy (spec §3.2): online first; any backend failure falls back to the
/// on-device translator, whose results are marked offline.
class TranslationService {
  TranslationService({required this._cloud, required this._offline});

  final TranslatorPort? _cloud;
  final TranslatorPort _offline;

  bool get hasCloud => _cloud != null;

  Future<Translation> translate(TranslateRequest request) async {
    final cloud = _cloud;
    if (cloud != null) {
      try {
        return await cloud.translate(request);
      } catch (error) {
        // Timeouts, 5xx and no network per spec; 4xx and 429 too, since an offline result beats none.
        debugPrint('Online translation failed ($error); using offline translation');
      }
    }
    try {
      return await _offline.translate(request);
    } on OfflineModelMissing {
      throw const TranslationUnavailable(offlineNotReady: true);
    } catch (error) {
      debugPrint('Offline translation failed: $error');
      throw const TranslationUnavailable(offlineNotReady: false);
    }
  }
}

final translationServiceProvider = Provider<TranslationService>((ref) {
  final apiBaseUrl = ref.watch(appConfigProvider).apiBaseUrl;
  return TranslationService(
    cloud: apiBaseUrl == null
        ? null
        : CloudTranslator(dio: ref.watch(dioProvider), apiBaseUrl: apiBaseUrl, clientHeaders: ref.watch(clientHeadersProvider)),
    offline: ref.watch(mlKitTranslatorProvider),
  );
});
