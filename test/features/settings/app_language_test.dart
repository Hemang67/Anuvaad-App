import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

void main() {
  testWidgets('choosing हिन्दी shows the Hindi navigation, and it persists', (tester) async {
    final prefs = await pumpAnuvaadApp(tester, prefs: {'onboarding_complete': true});
    await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
    await tester.pumpAndSettle();
    await scrollIntoView(tester, find.byKey(const Key('app-language')));
    await tester.tap(find.byKey(const Key('app-language')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('हिन्दी').last);
    await tester.pumpAndSettle();
    expect(prefs.getString('app_language'), 'hi');
    expect(find.widgetWithText(NavigationDestination, 'होम'), findsOneWidget);
    expect(find.widgetWithText(NavigationDestination, 'सेटिंग्स'), findsOneWidget);
  });

  testWidgets('a saved app language is used at launch', (tester) async {
    await pumpAnuvaadApp(tester, prefs: {'onboarding_complete': true, 'app_language': 'gu'});
    expect(find.widgetWithText(NavigationDestination, 'હોમ'), findsOneWidget);
  });

  testWidgets('System follows the phone language', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('gu', 'IN')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await pumpAnuvaadApp(tester, prefs: {'onboarding_complete': true});
    expect(find.widgetWithText(NavigationDestination, 'હોમ'), findsOneWidget);
  });

  testWidgets('a phone in another language gets English', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('fr', 'FR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await pumpAnuvaadApp(tester, prefs: {'onboarding_complete': true});
    expect(find.widgetWithText(NavigationDestination, 'Home'), findsOneWidget);
  });
}
