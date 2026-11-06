import 'package:anuvaad/app/app.dart';
import 'package:anuvaad/core/config/app_config.dart';
import 'package:anuvaad/core/settings/settings_providers.dart';
import 'package:anuvaad/features/conversation/data/offline_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'conversation_fakes.dart';
import 'platform_mocks.dart';

/// Pumps the real app (splash, router, screens) with test-only platform state
/// and settles until navigation is done. Returns the in-memory preferences.
Future<SharedPreferences> pumpAnuvaadApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  AppConfig config = const AppConfig(apiBaseUrl: null, releasesRepo: null),
  List<Override> overrides = const [],
  String version = '0.1.0',
  String buildNumber = '1',
  OfflineModels? offlineModels,
}) async {
  final shared = await mockPlatform(prefs: prefs, version: version, buildNumber: buildNumber);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(shared),
      appConfigProvider.overrideWithValue(config),
      // Never touch the ML Kit plugin in widget tests: all offline models count as downloaded.
      offlineModelsProvider.overrideWithValue(offlineModels ?? OfflineModels(FakeOfflineModelStore())),
      ...overrides,
    ],
    child: const AnuvaadApp(),
  ));
  await tester.pumpAndSettle();
  return shared;
}
