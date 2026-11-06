import 'dart:convert';

import 'package:anuvaad/services/language_registry/language.dart';
import 'package:anuvaad/services/language_registry/language_registry.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test-only bundle serving in-memory strings.
class _MemoryBundle extends CachingAssetBundle {
  _MemoryBundle(this.files);
  final Map<String, String> files;

  @override
  Future<ByteData> load(String key) async {
    final text = files[key];
    if (text == null) throw FlutterError('missing asset $key');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(text)));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LanguageRegistry registry;

  setUpAll(() async => registry = await AssetLanguageRegistry.load(rootBundle));

  test('loads core languages in order en-IN, hi-IN, gu-IN', () {
    expect(registry.coreLanguages.map((l) => l.code), ['en-IN', 'hi-IN', 'gu-IN']);
    expect(registry.coreLanguages.every((l) => l.isCore), isTrue);
  });

  test('core languages offer offline translation', () {
    expect(registry.coreLanguages.every((l) => l.capabilities.offlineTranslation), isTrue);
  });

  test('Gujarati manifest has native name ગુજરાતી and short label ગુ', () {
    final gu = registry.byCode('gu-IN')!;
    expect(gu.nativeName, 'ગુજરાતી');
    expect(gu.shortLabel, 'ગુ');
    expect(gu.nativeFirstLabel, 'ગુજરાતી · Gujarati');
    expect(gu.nameFirstLabel, 'Gujarati · ગુજરાતી');
  });

  test('planned languages are notReleased and not core', () {
    final planned = registry.plannedLanguages;
    expect(planned.map((l) => l.code), contains('mr-IN'));
    expect(planned.every((l) => l.installation == LanguageInstallation.notReleased && !l.isCore), isTrue);
    expect(registry.byCode('mr-IN')!.displayName, 'Marathi');
  });

  test('canTranslate allows all six core directions', () {
    const pairs = [
      ('en-IN', 'hi-IN'), ('hi-IN', 'en-IN'), ('en-IN', 'gu-IN'),
      ('gu-IN', 'en-IN'), ('hi-IN', 'gu-IN'), ('gu-IN', 'hi-IN'),
    ];
    for (final (source, target) in pairs) {
      expect(registry.canTranslate(source, target), isTrue, reason: '$source -> $target');
    }
  });

  test('canTranslate rejects same language, planned and unknown languages', () {
    expect(registry.canTranslate('gu-IN', 'gu-IN'), isFalse);
    expect(registry.canTranslate('mr-IN', 'gu-IN'), isFalse);
    expect(registry.canTranslate('gu-IN', 'mr-IN'), isFalse);
    expect(registry.canTranslate('xx-XX', 'gu-IN'), isFalse);
  });

  test('malformed manifest throws FormatException naming the file', () async {
    final bundle = _MemoryBundle({
      'assets/languages/core/index.json': '{"core": ["en-IN"]}',
      'assets/languages/core/en-IN.json': '{"languageCode": 1}',
      'assets/languages/catalog.json': '{"languages": []}',
    });
    await expectLater(
      AssetLanguageRegistry.load(bundle),
      throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('assets/languages/core/en-IN.json'))),
    );
  });

  test('defaultMyLanguage maps device locales', () {
    expect(defaultMyLanguage(const Locale('gu', 'IN')), 'gu-IN');
    expect(defaultMyLanguage(const Locale('hi')), 'hi-IN');
    expect(defaultMyLanguage(const Locale('fr')), 'en-IN');
  });
}
