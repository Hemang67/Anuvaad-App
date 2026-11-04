import 'dart:async';

import 'package:anuvaad/app/bootstrap.dart';
import 'package:anuvaad/app/theme/anuvaad_theme.dart';
import 'package:anuvaad/features/splash/presentation/splash_screen.dart';
import 'package:anuvaad/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpSplash(
  WidgetTester tester, {
  required Future<AppBootstrap> Function() bootstrap,
  ThemeMode mode = ThemeMode.light,
}) {
  return tester.pumpWidget(ProviderScope(
    overrides: [bootstrapProvider.overrideWith((ref) => bootstrap())],
    child: MaterialApp(
      theme: buildAnuvaadTheme(Brightness.light),
      darkTheme: buildAnuvaadTheme(Brightness.dark),
      themeMode: mode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [Locale('en')],
      home: const SplashScreen(),
    ),
  ));
}

final _globe = find.image(const AssetImage('assets/branding/globe_light_interim.jpg'));

void main() {
  testWidgets('splash shows wordmark and tagline as text', (tester) async {
    await _pumpSplash(tester, bootstrap: () => Completer<AppBootstrap>().future);
    expect(find.text('Anuvaad'), findsOneWidget);
    expect(find.text('Speak Any Language. Be Closer.'), findsOneWidget);
    expect(find.bySemanticsLabel('Anuvaad logo'), findsOneWidget);
  });

  testWidgets('light theme shows the light globe artwork; dark theme shows none', (tester) async {
    await _pumpSplash(tester, bootstrap: () => Completer<AppBootstrap>().future);
    expect(_globe, findsOneWidget);

    await _pumpSplash(tester, bootstrap: () => Completer<AppBootstrap>().future, mode: ThemeMode.dark);
    await tester.pump(const Duration(milliseconds: 300)); // theme change animates over 200 ms
    expect(_globe, findsNothing);
  });

  testWidgets('indeterminate indicator appears only after 600 ms while init is pending', (tester) async {
    await _pumpSplash(tester, bootstrap: () => Completer<AppBootstrap>().future);
    await tester.pump(const Duration(milliseconds: 599));
    expect(find.byType(LinearProgressIndicator), findsNothing);

    await tester.pump(const Duration(milliseconds: 2));
    final indicator = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
    expect(indicator.value, isNull);
  });

  testWidgets('initialization failure shows a retry message instead of a spinner', (tester) async {
    var attempts = 0;
    await _pumpSplash(tester, bootstrap: () {
      attempts++;
      return Future<AppBootstrap>.error(StateError('broken asset'));
    });
    await tester.pump(const Duration(seconds: 1));

    expect(find.text("Anuvaad couldn't start. Please try again."), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(attempts, 2);
  });
}
