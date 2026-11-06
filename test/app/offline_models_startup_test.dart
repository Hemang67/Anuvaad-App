import 'package:anuvaad/app/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';
import '../helpers/conversation_fakes.dart';

void main() {
  testWidgets('starts the offline model download once after launch', (tester) async {
    final models = CountingOfflineModels();
    await pumpAnuvaadApp(tester, prefs: {'onboarding_complete': true}, offlineModels: models);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(models.ensureCalls, 1);

    await tester.tap(find.text('Languages'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(models.ensureCalls, 1);
    expect(Routes.settings, '/settings');
  });
}
