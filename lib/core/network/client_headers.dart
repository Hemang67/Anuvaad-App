import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/bootstrap.dart';
import '../settings/settings_providers.dart';

/// Sent with every backend request: an anonymous install id (for rate limits) and the app version.
final clientHeadersProvider = Provider<Map<String, String>>((ref) {
  final info = ref.watch(packageInfoProvider);
  return {
    'X-Anuvaad-Install': ref.watch(settingsRepositoryProvider).installId,
    'X-Anuvaad-Version': '${info.version}+${info.buildNumber}',
  };
});
