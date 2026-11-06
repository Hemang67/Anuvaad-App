/// Where a translation came from. Offline results are always labelled in the UI.
enum TranslationProvenance { online, offline }

/// One segment of recognized speech to translate. Language codes are registry codes such as `hi-IN`.
class TranslateRequest {
  const TranslateRequest({
    required this.segmentId,
    required this.text,
    required this.sourceLanguage,
    required this.targetLanguage,
  });

  final String segmentId;
  final String text;
  final String sourceLanguage;
  final String targetLanguage;
}

class Translation {
  const Translation({required this.segmentId, required this.text, required this.provenance, this.provider});

  final String segmentId;
  final String text;
  final TranslationProvenance provenance;

  /// Which engine produced it, e.g. `cloudflare` or `mlkit`.
  final String? provider;
}

/// Port for any translator (backend, on-device); adapters live in `data/`.
abstract interface class TranslatorPort {
  Future<Translation> translate(TranslateRequest request);
}
