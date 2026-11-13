import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _arb(String locale) =>
    (jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync()) as Map).cast<String, Object?>();

void main() {
  final en = _arb('en');
  final keys = [for (final k in en.keys) if (!k.startsWith('@')) k];

  for (final locale in ['hi', 'gu']) {
    test('$locale has every key and the same placeholders as en', () {
      final other = _arb(locale);
      final missing = [for (final k in keys) if (other[k] is! String || (other[k] as String).trim().isEmpty) k];
      expect(missing, isEmpty, reason: 'untranslated in $locale');
      final extra = [for (final k in other.keys) if (!k.startsWith('@') && !en.containsKey(k)) k];
      expect(extra, isEmpty, reason: 'keys in $locale that English no longer has');
      for (final k in keys) {
        final meta = en['@$k'];
        final placeholders = meta is Map && meta['placeholders'] is Map ? (meta['placeholders'] as Map).keys : const [];
        for (final p in placeholders) {
          expect(other[k] as String, contains('{$p'), reason: '$locale.$k must use {$p}');
        }
        if ((en[k] as String).contains(', plural,')) {
          expect(other[k] as String, contains(', plural,'), reason: '$locale.$k must stay a plural message');
        }
      }
    });
  }

  test('translations keep the names that are never translated', () {
    for (final locale in ['hi', 'gu']) {
      final other = _arb(locale);
      for (final k in keys) {
        for (final name in ['Anuvaad', 'REA Intelligence', 'Google', 'Bluetooth', 'Cloudflare', 'Vercel', 'GitHub']) {
          if ((en[k] as String).contains(name)) {
            expect(other[k] as String, contains(name), reason: '$locale.$k keeps "$name"');
          }
        }
      }
    }
  });

  test('list separators keep their spaces (M4)', () {
    for (final locale in ['en', 'hi', 'gu']) {
      final arb = _arb(locale);
      for (final key in ['listOr', 'listAnd']) {
        final value = arb[key] as String;
        expect(value.startsWith(' ') && value.endsWith(' '), isTrue, reason: '$locale.$key is "$value"');
      }
    }
  });

  test('wording fixes from review (M5)', () {
    final hi = _arb('hi'), gu = _arb('gu');
    expect(hi['latencyStats'], contains('माध्यिका'), reason: 'median, not mean');
    expect(gu['latencyStats'], contains('મધ્યસ્થ'), reason: 'median, not mean');
    expect(hi['whatsNewGotIt'], 'ठीक है', reason: 'not gendered');
    for (final key in ['settingsRawAudio', 'privacyStoredAudio', 'onboardingPrivacyStorage']) {
      expect(hi[key], isNot(contains('असली')), reason: 'raw audio is मूल, not "genuine"');
    }
    expect(hi['settingsUpToDate'], contains('सबसे नया'));
    expect(gu['settingsUpToDate'], contains('સૌથી નવું'));
  });
}
