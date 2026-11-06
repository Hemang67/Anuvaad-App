import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

/// Registry code → ML Kit model code (shared language table in the M2 plan).
const mlKitCodes = {
  'en-IN': 'en', // TranslateLanguage.english
  'hi-IN': 'hi', // TranslateLanguage.hindi
  'gu-IN': 'gu', // TranslateLanguage.gujarati
};

/// Where on-device translation models live; a fake in tests, ML Kit in the app.
abstract interface class OfflineModelStore {
  Future<bool> isDownloaded(String bcpCode);
  Future<bool> download(String bcpCode, {required bool wifiOnly});
}

class MlKitModelStore implements OfflineModelStore {
  final _manager = OnDeviceTranslatorModelManager();

  @override
  Future<bool> isDownloaded(String bcpCode) => _manager.isModelDownloaded(bcpCode);

  @override
  Future<bool> download(String bcpCode, {required bool wifiOnly}) =>
      _manager.downloadModel(bcpCode, isWifiRequired: wifiOnly);
}

/// The core languages' offline models (~30 MB each), fetched in the background on Wi-Fi.
class OfflineModels {
  OfflineModels(this._store);

  final OfflineModelStore _store;

  Future<bool> isReady(String languageCode) async {
    final code = mlKitCodes[languageCode];
    if (code == null) return false;
    try {
      return await _store.isDownloaded(code);
    } catch (error) {
      debugPrint('Offline model check failed for $code: $error');
      return false;
    }
  }

  /// Downloads missing models one at a time, Wi-Fi only. Never throws: offline translation is a fallback.
  Future<void> ensureDownloaded() async {
    for (final code in mlKitCodes.values) {
      try {
        if (await _store.isDownloaded(code)) continue;
        await _store.download(code, wifiOnly: true);
      } catch (error) {
        debugPrint('Offline model download failed for $code: $error');
      }
    }
  }
}

final offlineModelsProvider = Provider<OfflineModels>((ref) => OfflineModels(MlKitModelStore()));
