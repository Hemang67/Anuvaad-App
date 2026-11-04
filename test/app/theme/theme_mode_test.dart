import 'package:anuvaad/app/app.dart';
import 'package:anuvaad/app/theme/theme_mode_controller.dart';
import 'package:anuvaad/core/settings/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/platform_mocks.dart';

Future<SharedPreferences> _pumpApp(WidgetTester tester, Brightness platform) async {
  final prefs = await mockPlatform();
  tester.platformDispatcher.platformBrightnessTestValue = platform;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  await tester.pumpWidget(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const AnuvaadApp(),
  ));
  return prefs;
}

Brightness _appBrightness(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(Scaffold))).brightness;

void main() {
  testWidgets('ThemeMode.system follows platform brightness without restart', (tester) async {
    await _pumpApp(tester, Brightness.light);
    expect(_appBrightness(tester), Brightness.light);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    expect(_appBrightness(tester), Brightness.dark);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expect(_appBrightness(tester), Brightness.light);
  });

  testWidgets('selecting Light overrides a dark platform', (tester) async {
    final prefs = await _pumpApp(tester, Brightness.dark);
    expect(_appBrightness(tester), Brightness.dark);

    final container = ProviderScope.containerOf(tester.element(find.byType(Scaffold)));
    await container.read(themeModeProvider.notifier).select(ThemeMode.light);
    await tester.pumpAndSettle();

    expect(_appBrightness(tester), Brightness.light);
    expect(prefs.getString('theme_mode'), 'light');
  });
}
