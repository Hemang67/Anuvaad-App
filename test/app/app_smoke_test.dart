import 'package:anuvaad/app/app.dart';
import 'package:anuvaad/core/settings/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/platform_mocks.dart';

void main() {
  testWidgets('AnuvaadApp builds a MaterialApp.router titled Anuvaad', (tester) async {
    final prefs = await mockPlatform();
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const AnuvaadApp(),
    ));
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).title, 'Anuvaad');
  });
}
