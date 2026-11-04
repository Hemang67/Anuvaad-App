import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/app_harness.dart';

const _myField = Key('my-language-field');
const _otherField = Key('other-language-field');

Future<SharedPreferences> _openLanguages(WidgetTester tester, {Map<String, Object> prefs = const {}}) async {
  final shared = await pumpAnuvaadApp(tester, prefs: {'onboarding_complete': true, ...prefs});
  await tester.tap(find.text('Languages'));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('languages-screen')), findsOneWidget);
  return shared;
}

DropdownButton<String> _dropdown(WidgetTester tester, Key field) => tester.widget<DropdownButton<String>>(
      find.descendant(of: find.byKey(field), matching: find.byType(DropdownButton<String>)),
    );

Future<void> _choose(WidgetTester tester, Key field, String label) async {
  await tester.tap(find.byKey(field));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('my language offers the three core languages; other adds Automatic detection', (tester) async {
    await _openLanguages(tester);
    expect(_dropdown(tester, _myField).items!.map((i) => i.value), ['en-IN', 'hi-IN', 'gu-IN']);
    expect(_dropdown(tester, _otherField).items!.map((i) => i.value), ['auto', 'en-IN', 'hi-IN', 'gu-IN']);
    expect(find.text('Automatic detection'), findsOneWidget);
  });

  testWidgets('swap exchanges languages and is disabled for Automatic detection', (tester) async {
    await _openLanguages(tester, prefs: {'my_language': 'gu-IN', 'other_language': 'hi-IN'});
    await tester.tap(find.byTooltip('Swap languages'));
    await tester.pumpAndSettle();
    expect(_dropdown(tester, _myField).value, 'hi-IN');
    expect(_dropdown(tester, _otherField).value, 'gu-IN');

    await _choose(tester, _otherField, 'Automatic detection');
    final swap = tester.widget<IconButton>(find.ancestor(of: find.byTooltip('Swap languages'), matching: find.byType(IconButton)));
    expect(swap.onPressed, isNull);
  });

  testWidgets('same language on both sides shows validation and disables Save', (tester) async {
    await _openLanguages(tester, prefs: {'my_language': 'gu-IN'});
    await _choose(tester, _otherField, 'ગુજરાતી · Gujarati');
    expect(find.text('Choose two different languages.'), findsOneWidget);
    await _scrollTo(tester, find.text('Save language preferences'));
    final save = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save language preferences'));
    expect(save.onPressed, isNull);
  });

  testWidgets('Save persists both values', (tester) async {
    final prefs = await _openLanguages(tester, prefs: {'my_language': 'gu-IN'});
    await _choose(tester, _myField, 'हिन्दी · Hindi');
    await _scrollTo(tester, find.text('Save language preferences'));
    await tester.tap(find.text('Save language preferences'));
    await tester.pumpAndSettle();
    expect(prefs.getString('my_language'), 'hi-IN');
    expect(prefs.getString('other_language'), 'auto');
    expect(find.text('Language preferences saved'), findsOneWidget);
  });

  testWidgets('Soon on a planned language shows the future-release message', (tester) async {
    await _openLanguages(tester);
    await _scrollTo(tester, find.text('Marathi'));
    await tester.tap(find.descendant(
      of: find.ancestor(of: find.text('Marathi'), matching: find.byType(Card)),
      matching: find.text('Soon'),
    ));
    await tester.pump();
    expect(find.text('Marathi language pack is planned for a future release.'), findsOneWidget);
  });

  testWidgets('core rows show the capability line built from the manifest', (tester) async {
    await _openLanguages(tester);
    for (final row in ['English · English', 'Hindi · हिन्दी', 'Gujarati · ગુજરાતી']) {
      final card = find.widgetWithText(Card, row);
      await _scrollTo(tester, card);
      expect(find.descendant(of: card, matching: find.text('Speech input · Translation · Voice output')), findsOneWidget, reason: row);
      expect(find.descendant(of: card, matching: find.text('CORE')), findsOneWidget, reason: row);
    }
  });
}
