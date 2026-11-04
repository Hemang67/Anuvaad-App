import 'package:anuvaad/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppConfig: empty values disable remote features', () {
    final c = AppConfig.parse(apiBaseUrl: '', releasesRepo: '');
    expect(c.apiBaseUrl, isNull);
    expect(c.releasesRepo, isNull);
  });

  test('AppConfig: parses an https base URL without a trailing slash', () {
    final c = AppConfig.parse(apiBaseUrl: 'https://anuvaad-web.vercel.app/', releasesRepo: 'owner/anuvaad-app');
    expect(c.apiBaseUrl.toString(), 'https://anuvaad-web.vercel.app');
    expect(c.releasesRepo, 'owner/anuvaad-app');
  });

  test('AppConfig: rejects non-https base URL', () {
    expect(() => AppConfig.parse(apiBaseUrl: 'http://x.dev', releasesRepo: ''), throwsArgumentError);
  });

  test('AppConfig: rejects malformed repo slug', () {
    expect(() => AppConfig.parse(apiBaseUrl: '', releasesRepo: 'not a repo'), throwsArgumentError);
    expect(() => AppConfig.parse(apiBaseUrl: '', releasesRepo: 'owner/repo/extra'), throwsArgumentError);
  });
}
