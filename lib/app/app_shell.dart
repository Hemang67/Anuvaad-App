import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/app_update/presentation/update_listener.dart';
import '../features/conversation/data/offline_models.dart';
import '../l10n/app_localizations.dart';
import 'routes.dart';
import 'theme/anuvaad_colors.dart';

/// Bottom navigation for the main tabs: Home, Languages, Settings.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.location, required this.child});

  /// Current path, used to highlight the active tab.
  final String location;
  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const _tabs = [Routes.home, Routes.languages, Routes.settings];
  AppLifecycleListener? _lifecycle;

  int get _selectedIndex {
    final index = _tabs.lastIndexWhere((tab) => widget.location.startsWith(tab));
    return index < 0 ? 0 : index;
  }

  @override
  void initState() {
    super.initState();
    // Offline translation models download in the background on Wi-Fi: at launch, and again whenever the
    // app returns to the foreground, so a download interrupted by lost Wi-Fi is retried.
    unawaited(ref.read(offlineModelsProvider).ensureDownloaded());
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(ref.read(offlineModelsProvider).ensureDownloaded()));
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    // Android standard for bottom navigation: Back on another tab returns to Home;
    // Back on Home leaves the app. Screens opened on top of a tab pop first.
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.go(Routes.home);
      },
      child: Scaffold(
        body: UpdateListener(child: widget.child),
        bottomNavigationBar: NavigationBar(
          backgroundColor: tokens.card,
          indicatorColor: tokens.soft,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) => context.go(_tabs[index]),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: l10n.navHome,
            ),
            NavigationDestination(
              icon: const Icon(Icons.translate_outlined),
              selectedIcon: const Icon(Icons.translate),
              label: l10n.navLanguages,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: l10n.navSettings,
            ),
          ],
        ),
      ),
    );
  }
}
