import 'package:anuvaad/app/app.dart';
import 'package:anuvaad/core/settings/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('AnuvaadApp builds a MaterialApp.router titled Anuvaad', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const AnuvaadApp(),
    ));
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).title, 'Anuvaad');
  });
}
