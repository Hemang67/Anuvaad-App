import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';

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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [Locale('en')],
      routerConfig: _placeholderRouter,
    );
  }
}
