import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/app_harness.dart';

Future<SharedPreferences> _openSettings(WidgetTester tester, {String version = '0.1.0', String buildNumber = '1'}) async {
  final prefs = await pumpAnuvaadApp(
    tester,
    prefs: {'onboarding_complete': true},
    version: version,
    buildNumber: buildNumber,
  );
  await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('settings-screen')), findsOneWidget);
  return prefs;
}

void main() {
  testWidgets('theme segment reflects and changes theme mode', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final prefs = await _openSettings(tester);

    final segments = tester.widget<SegmentedButton<ThemeMode>>(find.byType(SegmentedButton<ThemeMode>));
    expect(segments.selected, {ThemeMode.system});
    expect(find.text('Default: System'), findsOneWidget);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(prefs.getString('theme_mode'), 'dark');
    expect(Theme.of(tester.element(find.byKey(const Key('settings-screen')))).brightness, Brightness.dark);
    expect(tester.widget<SegmentedButton<ThemeMode>>(find.byType(SegmentedButton<ThemeMode>)).selected, {ThemeMode.dark});
  });

  testWidgets('shows version and build from PackageInfo', (tester) async {
    await _openSettings(tester, version: '0.2.3', buildNumber: '7');
    expect(find.text('v0.2.3 (7)'), findsOneWidget);
  });

  testWidgets('shows About Anuvaad and Powered by REA Intelligence', (tester) async {
    await _openSettings(tester);
    expect(find.text('About Anuvaad'), findsOneWidget);
    expect(find.text('Powered by REA Intelligence'), findsOneWidget);
  });
}
