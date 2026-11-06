import 'package:anuvaad/features/conversation/data/offline_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/conversation_fakes.dart';

void main() {
  test('isReady maps registry codes to ML Kit models', () async {
    final models = OfflineModels(FakeOfflineModelStore(downloaded: {'en'}));
    expect(await models.isReady('en-IN'), isTrue);
    expect(await models.isReady('hi-IN'), isFalse);
    expect(await models.isReady('xx-XX'), isFalse);
  });

  test('ensureDownloaded fetches only missing models on wifi', () async {
    final store = FakeOfflineModelStore(downloaded: {'en'});
    await OfflineModels(store).ensureDownloaded();
    expect(store.downloads, [(code: 'hi', wifiOnly: true), (code: 'gu', wifiOnly: true)]);
  });

  test('concurrent ensureDownloaded calls share one run', () async {
    final store = FakeOfflineModelStore(downloaded: {});
    final models = OfflineModels(store);
    await Future.wait([models.ensureDownloaded(), models.ensureDownloaded()]);
    expect(store.downloads.map((d) => d.code), ['en', 'hi', 'gu']);
    // A later call runs again (nothing left to download).
    await models.ensureDownloaded();
    expect(store.downloads, hasLength(3));
  });

  test('ensureDownloaded survives a failed download', () async {
    final store = FakeOfflineModelStore(downloaded: {}, failing: {'hi'});
    await OfflineModels(store).ensureDownloaded();
    expect(store.downloads.map((d) => d.code), ['en', 'hi', 'gu']);
    expect(store.downloaded, {'en', 'gu'});
  });

  test('ensureDownloaded survives a store that cannot be queried', () async {
    await expectLater(OfflineModels(_BrokenStore()).ensureDownloaded(), completes);
  });
}

class _BrokenStore implements OfflineModelStore {
  @override
  Future<bool> isDownloaded(String bcpCode) => throw StateError('plugin missing');

  @override
  Future<bool> download(String bcpCode, {required bool wifiOnly}) => throw StateError('plugin missing');
}
