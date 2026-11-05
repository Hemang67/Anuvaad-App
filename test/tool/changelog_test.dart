import 'package:flutter_test/flutter_test.dart';

import '../../tool/release/changelog.dart';

const _changelog = '''
# Changelog

Release notes for Anuvaad.

## 0.2.0 (3) — 2026-12-01
Mandatory: yes
Min supported build: 2
### What's new
- Live conversation mode.
- Hindi and Gujarati screens.
### Fixed
- Splash flicker on Android 12.

## 0.1.1 (2) - 2026-11-20
### Fixed
- Update popup text fits large font sizes.

## 0.1.0 (1) — 2026-11-12
### What's new
- First test build.
''';

void main() {
  test('parses version, build, date, flags and bullets', () {
    final e = parseChangelogEntry(_changelog, '0.2.0');
    expect(e.version, '0.2.0');
    expect(e.build, 3);
    expect(e.date, DateTime.utc(2026, 12, 1));
    expect(e.mandatory, isTrue);
    expect(e.minSupportedBuild, 2);
    expect(e.whatsNew, ['Live conversation mode.', 'Hindi and Gujarati screens.']);
    expect(e.fixed, ['Splash flicker on Android 12.']);
  });

  test('defaults Mandatory to no and min supported build to 1', () {
    final e = parseChangelogEntry(_changelog, '0.1.1');
    expect(e.build, 2);
    expect(e.mandatory, isFalse);
    expect(e.minSupportedBuild, 1);
    expect(e.whatsNew, isEmpty);
    expect(e.fixed, ['Update popup text fits large font sizes.']);
  });

  test('notesMarkdown keeps both sections and omits empty ones', () {
    expect(
      parseChangelogEntry(_changelog, '0.2.0').notesMarkdown,
      "### What's new\n- Live conversation mode.\n- Hindi and Gujarati screens.\n\n### Fixed\n- Splash flicker on Android 12.\n",
    );
    expect(parseChangelogEntry(_changelog, '0.1.1').notesMarkdown, '### Fixed\n- Update popup text fits large font sizes.\n');
  });

  test('rejects unknown section heading', () {
    const text = '## 0.3.0 (4) — 2026-12-10\n### Whats new\n- Typo heading.\n';
    expect(() => parseChangelogEntry(text, '0.3.0'), throwsA(isA<FormatException>()));
  });

  test('rejects an entry without any bullets', () {
    const text = "## 0.3.0 (4) — 2026-12-10\n### What's new\n\n### Fixed\n";
    expect(() => parseChangelogEntry(text, '0.3.0'), throwsA(isA<FormatException>()));
  });

  test('rejects a malformed heading for the requested version', () {
    const text = "## 0.3.0 (4) — 2026-12-XX\n### What's new\n- Something.\n";
    expect(
      () => parseChangelogEntry(text, '0.3.0'),
      throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('heading'))),
    );
  });

  test('rejects stray text inside an entry', () {
    const text = "## 0.3.0 (4) — 2026-12-10\nThis release is great\n### What's new\n- Something.\n";
    expect(() => parseChangelogEntry(text, '0.3.0'), throwsA(isA<FormatException>()));
  });

  test('throws when the version has no entry', () {
    expect(
      () => parseChangelogEntry(_changelog, '0.9.0'),
      throwsA(isA<FormatException>().having((e) => e.message, 'message', 'No CHANGELOG entry for 0.9.0')),
    );
  });

  test('verifyPubspecVersion accepts a match and rejects a mismatched build', () {
    const pubspec = 'name: anuvaad\nversion: 0.1.0+2\n';
    verifyPubspecVersion(pubspec, version: '0.1.0', build: 2);
    expect(() => verifyPubspecVersion(pubspec, version: '0.1.0', build: 1), throwsStateError);
    expect(() => verifyPubspecVersion(pubspec, version: '0.1.1', build: 2), throwsStateError);
  });
}
