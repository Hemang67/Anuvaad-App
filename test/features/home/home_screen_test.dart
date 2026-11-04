import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

const _onboarded = <String, Object>{'onboarding_complete': true};

void main() {
  testWidgets('shows prototype headline and hero copy', (tester) async {
    await pumpAnuvaadApp(tester, prefs: _onboarded);
    expect(find.byKey(const Key('home-screen')), findsOneWidget);
    expect(find.text('YOUR PERSONAL LANGUAGE BRIDGE'), findsOneWidget);
    expect(find.text('Speak freely.'), findsOneWidget);
    expect(find.text('Understand everyone.'), findsOneWidget);
    expect(find.text('Your voice, understood worldwide.'), findsOneWidget);
    expect(find.text('Real-time translation in English, Hindi and Gujarati.'), findsOneWidget);
    expect(find.text('Start communicating'), findsOneWidget);
  });

  testWidgets('language pills come from the registry', (tester) async {
    await pumpAnuvaadApp(tester, prefs: _onboarded);
    for (final label in ['EN', 'हि', 'ગુ']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('mode cards are disabled and say Coming in an update', (tester) async {
    await pumpAnuvaadApp(tester, prefs: _onboarded);
    expect(find.text('Coming in an update'), findsNWidgets(2));
    for (final title in ['In-person conversation', 'Online meeting']) {
      final card = tester.widget<InkWell>(find.ancestor(of: find.text(title), matching: find.byType(InkWell)).first);
      expect(card.onTap, isNull, reason: title);
    }
    await tester.tap(find.text('In-person conversation'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-screen')), findsOneWidget);
  });

  testWidgets('my language row shows native-first label; Change opens Languages', (tester) async {
    await pumpAnuvaadApp(tester, prefs: {..._onboarded, 'my_language': 'gu-IN'});
    expect(find.text('ગુજરાતી · Gujarati'), findsOneWidget);
    await tester.ensureVisible(find.text('Change'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('languages-screen')), findsOneWidget);
  });

  testWidgets('my language falls back to device default when unset', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('en', 'US');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    await pumpAnuvaadApp(tester, prefs: _onboarded);
    expect(find.text('English · English'), findsOneWidget);
  });

  testWidgets('Settings pill and tab open Settings', (tester) async {
    await pumpAnuvaadApp(tester, prefs: _onboarded);
    await tester.scrollUntilVisible(find.widgetWithText(ActionChip, 'Settings'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ActionChip, 'Settings'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-screen')), findsOneWidget);
  });
}
