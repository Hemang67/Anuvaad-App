// Validates release configuration before any APK is built.
// Usage: dart run tool/release/config_check.dart "<API_BASE_URL>"
import 'dart:io';

/// Why [value] can't be the app's API base URL, or null when it's fine.
/// Mirrors the app's AppConfig rule: an https URL with a host.
String? apiBaseUrlProblem(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'API_BASE_URL is empty';
  final url = Uri.tryParse(trimmed);
  if (url == null || url.scheme != 'https' || url.host.isEmpty) {
    return 'API_BASE_URL must be an https URL such as https://<project>.vercel.app (got "$value")';
  }
  return null;
}

void main(List<String> args) {
  final problem = apiBaseUrlProblem(args.isEmpty ? '' : args.first);
  if (problem != null) {
    stderr.writeln('::error::$problem');
    exitCode = 1;
  }
}
