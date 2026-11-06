import 'dart:io';

import 'package:anuvaad/core/config/app_config.dart';
import 'package:anuvaad/features/conversation/application/translation_service.dart';
import 'package:anuvaad/features/conversation/data/cloud_translator.dart';
import 'package:anuvaad/features/conversation/data/mlkit_translator.dart';
import 'package:anuvaad/features/conversation/domain/translation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/conversation_fakes.dart';

const _request = TranslateRequest(
  segmentId: 'seg-1',
  text: 'તમે ક્યાં છો?',
  sourceLanguage: 'gu-IN',
  targetLanguage: 'hi-IN',
);

void main() {
  late FakeTranslator cloud;
  late FakeTranslator offline;

  setUp(() {
    cloud = FakeTranslator(reply: (_) => 'आप कहाँ हैं?');
    offline = FakeTranslator(provenance: TranslationProvenance.offline, provider: 'mlkit', reply: (_) => 'तुम कहाँ हो?');
  });

  test('online result is returned as online', () async {
    final result = await TranslationService(cloud: cloud, offline: offline).translate(_request);
    expect(result.text, 'आप कहाँ हैं?');
    expect(result.provenance, TranslationProvenance.online);
    expect(offline.requests, isEmpty);
  });

  test('cloud failure falls back to offline and is marked offline', () async {
    final failures = <Object>[
      for (final kind in CloudFailure.values) CloudTranslationException(kind),
      const SocketException('no route'),
    ];
    for (final failure in failures) {
      cloud.error = failure;
      final result = await TranslationService(cloud: cloud, offline: offline).translate(_request);
      expect(result.provenance, TranslationProvenance.offline, reason: '$failure');
      expect(result.text, 'तुम कहाँ हो?');
      expect(result.provider, 'mlkit');
    }
  });

  test('offline with missing models reports offline not ready', () async {
    cloud.error = const CloudTranslationException(CloudFailure.unavailable);
    offline.error = const OfflineModelMissing(['gu-IN']);
    await expectLater(
      TranslationService(cloud: cloud, offline: offline).translate(_request),
      throwsA(isA<TranslationUnavailable>().having((e) => e.offlineNotReady, 'offlineNotReady', isTrue)),
    );
  });

  test('other offline errors report unavailable without the offline flag', () async {
    cloud.error = const CloudTranslationException(CloudFailure.unavailable);
    offline.error = StateError('ML Kit crashed');
    await expectLater(
      TranslationService(cloud: cloud, offline: offline).translate(_request),
      throwsA(isA<TranslationUnavailable>().having((e) => e.offlineNotReady, 'offlineNotReady', isFalse)),
    );
  });

  test('no backend configured goes straight to offline', () async {
    final result = await TranslationService(cloud: null, offline: offline).translate(_request);
    expect(result.provenance, TranslationProvenance.offline);
    expect(cloud.requests, isEmpty);
  });

  test('the provider has no cloud translator without an API base URL', () {
    final container = ProviderContainer(overrides: [
      appConfigProvider.overrideWithValue(const AppConfig(apiBaseUrl: null, releasesRepo: null)),
      mlKitTranslatorProvider.overrideWithValue(offline),
    ]);
    addTearDown(container.dispose);
    expect(container.read(translationServiceProvider).hasCloud, isFalse);
  });
}
