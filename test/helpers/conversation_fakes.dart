import 'dart:async';

import 'package:anuvaad/features/conversation/data/offline_models.dart';
import 'package:anuvaad/features/conversation/domain/translation.dart';

/// In-memory ML Kit model store. [downloaded] holds BCP codes ('en', 'hi', 'gu').
class FakeOfflineModelStore implements OfflineModelStore {
  FakeOfflineModelStore({Set<String>? downloaded, this.failing = const {}})
      : downloaded = downloaded ?? {'en', 'hi', 'gu'};

  final Set<String> downloaded;

  /// Codes whose download throws.
  final Set<String> failing;

  final List<({String code, bool wifiOnly})> downloads = [];

  @override
  Future<bool> isDownloaded(String bcpCode) async => downloaded.contains(bcpCode);

  @override
  Future<bool> download(String bcpCode, {required bool wifiOnly}) async {
    downloads.add((code: bcpCode, wifiOnly: wifiOnly));
    if (failing.contains(bcpCode)) throw StateError('download failed: $bcpCode');
    downloaded.add(bcpCode);
    return true;
  }
}

/// Counts startup download requests without touching the store.
class CountingOfflineModels extends OfflineModels {
  CountingOfflineModels() : super(FakeOfflineModelStore());

  int ensureCalls = 0;

  @override
  Future<void> ensureDownloaded() async => ensureCalls++;
}

/// Translator double: answers with [reply] (or throws [error]); [gates] hold answers until completed.
class FakeTranslator implements TranslatorPort {
  FakeTranslator({this.provenance = TranslationProvenance.online, this.provider = 'cloudflare', this.reply, this.error});

  final TranslationProvenance provenance;
  final String provider;

  /// Builds the translated text from the request; defaults to the source text plus ' (translated)'.
  String Function(TranslateRequest request)? reply;
  Object? error;

  /// Per-segment gates: the answer for that segment waits until its completer finishes.
  final Map<String, Completer<void>> gates = {};
  final List<TranslateRequest> requests = [];

  @override
  Future<Translation> translate(TranslateRequest request) async {
    requests.add(request);
    final gate = gates[request.segmentId];
    if (gate != null) await gate.future;
    final failure = error;
    if (failure != null) throw failure;
    return Translation(
      segmentId: request.segmentId,
      text: reply?.call(request) ?? '${request.text} (translated)',
      provenance: provenance,
      provider: provider,
    );
  }
}
