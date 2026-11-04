import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
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
      supportedLocales: const [Locale('en')],
      routerConfig: ref.watch(routerProvider),
    );
  }
}
