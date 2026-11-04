import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Test-only platform state: in-memory preferences and a fixed app version.
Future<SharedPreferences> mockPlatform({
  Map<String, Object> prefs = const {},
  String version = '0.1.0',
  String buildNumber = '1',
}) async {
  PackageInfo.setMockInitialValues(
    appName: 'Anuvaad',
    packageName: 'app.anuvaad',
    version: version,
    buildNumber: buildNumber,
    buildSignature: '',
  );
  SharedPreferences.setMockInitialValues(prefs);
  return SharedPreferences.getInstance();
}
