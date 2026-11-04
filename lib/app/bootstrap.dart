import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/language_registry/language_registry.dart';

/// Everything the app loads behind the branded splash.
class AppBootstrap {
  const AppBootstrap({required this.languageRegistry, required this.packageInfo});

  final LanguageRegistry languageRegistry;
  final PackageInfo packageInfo;

  static Future<AppBootstrap> load(AssetBundle bundle) async {
    final registry = AssetLanguageRegistry.load(bundle);
    final packageInfo = PackageInfo.fromPlatform();
    return AppBootstrap(languageRegistry: await registry, packageInfo: await packageInfo);
  }
}

/// No automatic retry: a failed start shows "Try again" on the splash instead.
final bootstrapProvider = FutureProvider<AppBootstrap>(
  (ref) => AppBootstrap.load(rootBundle),
  retry: (retryCount, error) => null,
);

final languageRegistryProvider = Provider<LanguageRegistry>(
  (ref) => ref.watch(bootstrapProvider).requireValue.languageRegistry,
);

final packageInfoProvider = Provider<PackageInfo>(
  (ref) => ref.watch(bootstrapProvider).requireValue.packageInfo,
);
