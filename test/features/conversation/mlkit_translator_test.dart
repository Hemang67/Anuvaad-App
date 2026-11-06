import 'package:anuvaad/features/conversation/data/mlkit_translator.dart';
import 'package:anuvaad/features/conversation/data/offline_models.dart';
import 'package:anuvaad/features/conversation/domain/translation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/conversation_fakes.dart';

const _request = TranslateRequest(
  segmentId: 'seg-1',
  text: 'आप आज कहाँ जा रहे हैं?',
  sourceLanguage: 'hi-IN',
  targetLanguage: 'gu-IN',
);

void main() {
  late List<(String, String, String)> calls;

  Future<String> fakeTranslate(String text, String source, String target) async {
    calls.add((text, source, target));
    return 'તમે આજે ક્યાં જઈ રહ્યા છો?';
  }

  setUp(() => calls = []);

  test('translates offline when both models are present', () async {
    final translator = MlKitTranslator(models: OfflineModels(FakeOfflineModelStore()), translate: fakeTranslate);
    final result = await translator.translate(_request);

    expect(calls, [('आप आज कहाँ जा रहे हैं?', 'hi', 'gu')]);
    expect(result.segmentId, 'seg-1');
    expect(result.text, 'તમે આજે ક્યાં જઈ રહ્યા છો?');
    expect(result.provenance, TranslationProvenance.offline);
    expect(result.provider, 'mlkit');
  });

  test('missing model throws OfflineModelMissing naming it and does not translate', () async {
    final translator = MlKitTranslator(
      models: OfflineModels(FakeOfflineModelStore(downloaded: {'en', 'hi'})),
      translate: fakeTranslate,
    );
    await expectLater(
      translator.translate(_request),
      throwsA(isA<OfflineModelMissing>().having((e) => e.languageCodes, 'languageCodes', ['gu-IN'])),
    );
    expect(calls, isEmpty);
  });

  test('english maps to its ML Kit code', () async {
    final translator = MlKitTranslator(models: OfflineModels(FakeOfflineModelStore()), translate: fakeTranslate);
    await translator.translate(const TranslateRequest(
      segmentId: 's',
      text: 'Hello',
      sourceLanguage: 'en-IN',
      targetLanguage: 'hi-IN',
    ));
    expect(calls.single.$2, 'en');
    expect(calls.single.$3, 'hi');
  });
}
