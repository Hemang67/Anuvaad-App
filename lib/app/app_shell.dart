import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/app_update/presentation/update_listener.dart';
import '../l10n/app_localizations.dart';
import 'routes.dart';
import 'theme/anuvaad_colors.dart';

/// Bottom navigation for the main tabs: Home, Languages, Settings.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});

  /// Current path, used to highlight the active tab.
  final String location;
  final Widget child;

  static const _tabs = [Routes.home, Routes.languages, Routes.settings];

  int get _selectedIndex {
    final index = _tabs.lastIndexWhere((tab) => location.startsWith(tab));
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    return Scaffold(
      body: UpdateListener(child: child),
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
    );
  }
}
