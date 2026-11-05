import 'package:anuvaad/core/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

const _homeScreen = Key('home-screen');

void main() {
  testWidgets('first page shows wordmark, tagline and the three core languages', (tester) async {
    await pumpAnuvaadApp(tester);
    expect(find.text('Anuvaad'), findsOneWidget);
    expect(find.text('Speak Any Language. Be Closer.'), findsOneWidget);
    expect(find.text('Talk naturally with people who speak English, Hindi or Gujarati.'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('Skip completes onboarding and opens Home', (tester) async {
    final prefs = await pumpAnuvaadApp(tester);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(prefs.getBool('onboarding_complete'), isTrue);
    expect(find.byKey(_homeScreen), findsOneWidget);
  });

  testWidgets('Next twice shows privacy page; Get started completes onboarding', (tester) async {
    final prefs = await pumpAnuvaadApp(tester);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Two simple modes'), findsOneWidget);
    expect(find.text('Anuvaad listens to the other person and plays the translation in your earphones.'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Your privacy'), findsOneWidget);
    expect(find.text('Raw audio is never saved. History stays off unless you turn it on.'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
    expect(prefs.getBool('onboarding_complete'), isNull);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(prefs.getBool('onboarding_complete'), isTrue);
    expect(find.byKey(_homeScreen), findsOneWidget);
  });

  testWidgets('privacy link hidden when API base URL is not configured', (tester) async {
    await pumpAnuvaadApp(tester);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Read the full privacy notice'), findsNothing);
  });

  testWidgets('privacy link shown when API base URL is configured', (tester) async {
    await pumpAnuvaadApp(tester, config: AppConfig.parse(apiBaseUrl: 'https://anuvaad.example', releasesRepo: ''));
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Read the full privacy notice'), findsOneWidget);
  });

  testWidgets('returning user skips onboarding', (tester) async {
    await pumpAnuvaadApp(tester, prefs: {'onboarding_complete': true});
    expect(find.byKey(_homeScreen), findsOneWidget);
  });

  testWidgets('welcome content is vertically centred on a tall phone', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await pumpAnuvaadApp(tester);
    final page = tester.getRect(find.byType(PageView));
    final top = tester.getTopLeft(find.bySemanticsLabel('Anuvaad logo')).dy;
    final bottom = tester.getBottomLeft(find.textContaining('Talk naturally')).dy;
    expect(((top + bottom) / 2 - page.center.dy).abs(), lessThan(24));
  });
}
