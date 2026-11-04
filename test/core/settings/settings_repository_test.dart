import 'package:anuvaad/core/settings/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> _prefs([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

void main() {
  test('themeMode defaults to system on first install', () async {
    expect(SettingsRepository(await _prefs()).themeMode, ThemeMode.system);
  });

  test('setThemeMode(dark) persists as "dark"', () async {
    final prefs = await _prefs();
    await SettingsRepository(prefs).setThemeMode(ThemeMode.dark);
    expect(prefs.getString('theme_mode'), 'dark');
    expect(SettingsRepository(prefs).themeMode, ThemeMode.dark);
  });

  test('unknown stored theme value falls back to system', () async {
    expect(SettingsRepository(await _prefs({'theme_mode': 'purple'})).themeMode, ThemeMode.system);
  });

  test('installId is generated once and stable', () async {
    final prefs = await _prefs();
    var calls = 0;
    final repo = SettingsRepository(prefs, newId: () => 'id-${++calls}');
    expect(repo.installId, 'id-1');
    expect(repo.installId, 'id-1');
    expect(SettingsRepository(prefs, newId: () => 'other').installId, 'id-1');
    expect(calls, 1);
  });

  test('otherLanguage defaults to auto', () async {
    expect(SettingsRepository(await _prefs()).otherLanguage, 'auto');
  });

  test('onboarding and language choices persist', () async {
    final prefs = await _prefs();
    final repo = SettingsRepository(prefs);
    expect(repo.onboardingComplete, isFalse);
    expect(repo.myLanguage, isNull);
    await repo.setOnboardingComplete();
    await repo.setMyLanguage('gu-IN');
    await repo.setOtherLanguage('hi-IN');
    final reread = SettingsRepository(prefs);
    expect(reread.onboardingComplete, isTrue);
    expect(reread.myLanguage, 'gu-IN');
    expect(reread.otherLanguage, 'hi-IN');
  });

  test('update bookkeeping defaults and round-trips', () async {
    final prefs = await _prefs();
    final repo = SettingsRepository(prefs);
    expect(repo.lastSeenBuild, 0);
    expect(repo.pendingUpdateJson, isNull);
    expect(repo.lastUpdateCheck, isNull);
    await repo.setLastSeenBuild(3);
    await repo.setPendingUpdateJson('{"build":4}');
    await repo.setLastUpdateCheck(DateTime.utc(2026, 11, 4, 10, 30));
    expect(repo.lastSeenBuild, 3);
    expect(repo.pendingUpdateJson, '{"build":4}');
    expect(prefs.getString('last_update_check'), '2026-11-04T10:30:00.000Z');
    expect(repo.lastUpdateCheck, DateTime.utc(2026, 11, 4, 10, 30));
    await repo.setPendingUpdateJson(null);
    expect(prefs.containsKey('pending_update'), isFalse);
  });
}
