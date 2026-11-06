import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

import '../domain/translation.dart';
import 'offline_models.dart';

/// Thrown instead of translating when a needed model isn't on the phone yet.
class OfflineModelMissing implements Exception {
  const OfflineModelMissing(this.languageCodes);

  /// Registry codes, e.g. `['gu-IN']`.
  final List<String> languageCodes;

  @override
  String toString() => 'OfflineModelMissing($languageCodes)';
}

typedef OnDeviceTranslate = Future<String> Function(String text, String sourceBcp, String targetBcp);

/// One ML Kit translation, closing the translator afterwards.
Future<String> mlKitTranslate(String text, String sourceBcp, String targetBcp) async {
  final translator = OnDeviceTranslator(
    sourceLanguage: BCP47Code.fromRawValue(sourceBcp)!,
    targetLanguage: BCP47Code.fromRawValue(targetBcp)!,
  );
  try {
    return await translator.translateText(text);
  } finally {
    await translator.close();
  }
}

/// On-device translation (Google ML Kit). Results are marked offline.
class MlKitTranslator implements TranslatorPort {
  MlKitTranslator({required this._models, required this._translate});

  final OfflineModels _models;
  final OnDeviceTranslate _translate;

  @override
  Future<Translation> translate(TranslateRequest request) async {
    // Check first: ML Kit's translateText would otherwise download a missing model over mobile data.
    final missing = [
      for (final code in [request.sourceLanguage, request.targetLanguage])
        if (!await _models.isReady(code)) code,
    ];
    if (missing.isNotEmpty) throw OfflineModelMissing(missing);

    final text = await _translate(request.text, mlKitCodes[request.sourceLanguage]!, mlKitCodes[request.targetLanguage]!);
    return Translation(
      segmentId: request.segmentId,
      text: text.trim(),
      provenance: TranslationProvenance.offline,
      provider: 'mlkit',
    );
  }
}

final mlKitTranslatorProvider = Provider<TranslatorPort>(
  (ref) => MlKitTranslator(models: ref.watch(offlineModelsProvider), translate: mlKitTranslate),
);
