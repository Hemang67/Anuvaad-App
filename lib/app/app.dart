import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import 'app_language.dart';
import 'router.dart';
import 'theme/anuvaad_theme.dart';
import 'theme/theme_mode_controller.dart';

class AnuvaadApp extends ConsumerWidget {
  const AnuvaadApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Anuvaad',
      debugShowCheckedModeBanner: false,
      theme: buildAnuvaadTheme(Brightness.light),
      darkTheme: buildAnuvaadTheme(Brightness.dark),
      themeMode: ref.watch(themeModeProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: switch (ref.watch(appLanguageProvider)) {
        'system' => null,
        final code => Locale(code),
      },
      // English first: it's what a phone in any other language gets.
      supportedLocales: [for (final code in appLanguages) Locale(code)],
      routerConfig: ref.watch(routerProvider),
    );
  }
}
