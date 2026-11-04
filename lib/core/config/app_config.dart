import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Build-time configuration passed with `--dart-define`.
class AppConfig {
  const AppConfig({required this.apiBaseUrl, required this.releasesRepo});

  /// Anuvaad backend, e.g. `https://<project>.vercel.app`. Null disables update checks and web links.
  final Uri? apiBaseUrl;

  /// GitHub `owner/name` of the public app repo, used as the update fallback. Null disables it.
  final String? releasesRepo;

  static final _repoSlug = RegExp(r'^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$');

  static AppConfig parse({required String apiBaseUrl, required String releasesRepo}) {
    Uri? base;
    final url = apiBaseUrl.trim();
    if (url.isNotEmpty) {
      final parsed = Uri.tryParse(url);
      if (parsed == null || parsed.scheme != 'https' || parsed.host.isEmpty) {
        throw ArgumentError.value(apiBaseUrl, 'apiBaseUrl', 'must be an https URL');
      }
      final path = parsed.path.endsWith('/') ? parsed.path.substring(0, parsed.path.length - 1) : parsed.path;
      base = parsed.replace(path: path);
    }
    String? repo;
    final slug = releasesRepo.trim();
    if (slug.isNotEmpty) {
      if (!_repoSlug.hasMatch(slug)) throw ArgumentError.value(releasesRepo, 'releasesRepo', 'must be owner/name');
      repo = slug;
    }
    return AppConfig(apiBaseUrl: base, releasesRepo: repo);
  }

  factory AppConfig.fromEnvironment() => parse(
        apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
        releasesRepo: const String.fromEnvironment('RELEASES_REPO'),
      );
}

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.fromEnvironment());
