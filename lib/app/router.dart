import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/app_update/presentation/release_notes_screen.dart';
import '../features/audio_devices/presentation/audio_devices_screen.dart';
import '../features/conversation/presentation/conversation_screen.dart';
import '../features/history/presentation/conversation_detail_screen.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/language_settings/presentation/languages_screen.dart';
import '../features/onboarding/application/onboarding_controller.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import 'app_shell.dart';
import 'bootstrap.dart';
import 'routes.dart';

export 'routes.dart';

/// Where to send the user, or null to stay. Rules in order (plan Task 6).
String? appRedirect({required bool bootstrapped, required bool onboardingComplete, required String location}) {
  if (!bootstrapped) return location == Routes.splash ? null : Routes.splash;
  if (location == Routes.splash) return onboardingComplete ? Routes.home : Routes.onboarding;
  if (!onboardingComplete) return location == Routes.onboarding ? null : Routes.onboarding;
  if (location == Routes.onboarding) return Routes.home;
  return null;
}

/// Full-screen flows opened from a tab slide up over it.
CustomTransitionPage<void> _slideUp(GoRouterState state, Widget child) => CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) => SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) => CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
    );

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(bootstrapProvider, (previous, next) => refresh.value++);
  ref.listen(onboardingCompleteProvider, (previous, next) => refresh.value++);

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => appRedirect(
      bootstrapped: ref.read(bootstrapProvider).hasValue,
      onboardingComplete: ref.read(onboardingCompleteProvider),
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(path: Routes.splash, pageBuilder: (context, state) => _fade(state, const SplashScreen())),
      GoRoute(path: Routes.onboarding, pageBuilder: (context, state) => _fade(state, const OnboardingScreen())),
      GoRoute(
        path: Routes.conversation,
        pageBuilder: (context, state) => _slideUp(state, const ConversationScreen()),
      ),
      GoRoute(
        path: Routes.audioDevices,
        pageBuilder: (context, state) => _slideUp(state, const AudioDevicesScreen()),
      ),
      GoRoute(
        path: Routes.history,
        pageBuilder: (context, state) => _slideUp(state, const HistoryScreen()),
        routes: [
          GoRoute(
            path: ':id',
            pageBuilder: (context, state) => _slideUp(state, ConversationDetailScreen(id: state.pathParameters['id']!)),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: Routes.home, pageBuilder: (context, state) => _fade(state, const HomeScreen())),
          GoRoute(path: Routes.languages, pageBuilder: (context, state) => _fade(state, const LanguagesScreen())),
          GoRoute(
            path: Routes.settings,
            pageBuilder: (context, state) => _fade(state, const SettingsScreen()),
            routes: [
              GoRoute(
                path: 'release-notes',
                pageBuilder: (context, state) => _fade(state, const ReleaseNotesScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
