import 'package:anuvaad/features/conversation/data/offline_models.dart';

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
