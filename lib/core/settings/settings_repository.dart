import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Typed access to the app's persisted preferences.
class SettingsRepository {
  SettingsRepository(this._prefs, {String Function()? newId}) : _newId = newId ?? (() => const Uuid().v4());

  final SharedPreferences _prefs;
  final String Function() _newId;

  static const _themeMode = 'theme_mode';
  static const _onboardingComplete = 'onboarding_complete';
  static const _myLanguage = 'my_language';
  static const _otherLanguage = 'other_language';
  static const _installId = 'install_id';
  static const _lastSeenBuild = 'last_seen_build';
  static const _pendingUpdate = 'pending_update';
  static const _lastUpdateCheck = 'last_update_check';
  static const _outputPrefix = 'output_for_';
  static const _autoDetect = 'auto_detect';

  ThemeMode get themeMode => switch (_prefs.getString(_themeMode)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  Future<void> setThemeMode(ThemeMode mode) => _prefs.setString(_themeMode, switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      });

  bool get onboardingComplete => _prefs.getBool(_onboardingComplete) ?? false;
  Future<void> setOnboardingComplete() => _prefs.setBool(_onboardingComplete, true);

  String? get myLanguage => _prefs.getString(_myLanguage);
  Future<void> setMyLanguage(String code) => _prefs.setString(_myLanguage, code);

  String get otherLanguage => _prefs.getString(_otherLanguage) ?? 'auto';
  Future<void> setOtherLanguage(String codeOrAuto) => _prefs.setString(_otherLanguage, codeOrAuto);

  /// Random install identifier, created on first read and stable afterwards.
  String get installId {
    final existing = _prefs.getString(_installId);
    if (existing != null) return existing;
    final created = _newId();
    _prefs.setString(_installId, created);
    return created;
  }

  int get lastSeenBuild => _prefs.getInt(_lastSeenBuild) ?? 0;
  Future<void> setLastSeenBuild(int build) => _prefs.setInt(_lastSeenBuild, build);

  String? get pendingUpdateJson => _prefs.getString(_pendingUpdate);
  Future<void> setPendingUpdateJson(String? json) =>
      json == null ? _prefs.remove(_pendingUpdate) : _prefs.setString(_pendingUpdate, json);

  DateTime? get lastUpdateCheck {
    final raw = _prefs.getString(_lastUpdateCheck);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> setLastUpdateCheck(DateTime at) => _prefs.setString(_lastUpdateCheck, at.toUtc().toIso8601String());

  /// Where spoken translations for [role] play ('earphones' or 'speaker'), stored as `output_for_me` / `output_for_other`.
  String? outputPreference(String role) => _prefs.getString('$_outputPrefix${_roleKey(role)}');
  Future<void> setOutputPreference(String role, String value) => _prefs.setString('$_outputPrefix${_roleKey(role)}', value);

  static String _roleKey(String role) => role == 'forMe' ? 'me' : 'other';

  /// Automatic language detection (on by default).
  bool get autoDetect => _prefs.getBool(_autoDetect) ?? true;
  Future<void> setAutoDetect(bool on) => _prefs.setBool(_autoDetect, on);
}
