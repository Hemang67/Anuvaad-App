import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import 'theme/anuvaad_theme.dart';

/// Temporary route table; replaced by the guarded router in Task 6.
final _placeholderRouter = GoRouter(
  routes: [GoRoute(path: '/', builder: (context, state) => const Scaffold())],
);

class AnuvaadApp extends ConsumerWidget {
  const AnuvaadApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Anuvaad',
      debugShowCheckedModeBanner: false,
      theme: buildAnuvaadTheme(Brightness.light),
      darkTheme: buildAnuvaadTheme(Brightness.dark),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [Locale('en')],
      routerConfig: _placeholderRouter,
    );
  }
}
