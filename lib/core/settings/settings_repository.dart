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
  static const _reviewReply = 'review_reply';
  static const _screenOffListening = 'screen_off_listening';
  static const _earphoneButton = 'earphone_button';
  static const _autoReply = 'auto_reply';
  static const _saveHistory = 'save_history';
  static const _speechRate = 'speech_rate';
  static const _voicePrefix = 'voice_';
  static const _appLanguage = 'app_language';

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

  /// Review my reply before playing (off by default).
  bool get reviewReply => _prefs.getBool(_reviewReply) ?? false;
  Future<void> setReviewReply(bool on) => _prefs.setBool(_reviewReply, on);

  /// A conversation keeps going with the screen off or the app in the background (on by default).
  bool get screenOffListening => _prefs.getBool(_screenOffListening) ?? true;
  Future<void> setScreenOffListening(bool on) => _prefs.setBool(_screenOffListening, on);

  /// During a conversation the earphones' play/pause button replies (on by default).
  bool get earphoneButton => _prefs.getBool(_earphoneButton) ?? true;
  Future<void> setEarphoneButton(bool on) => _prefs.setBool(_earphoneButton, on);

  /// Speech in my own language during Listen counts as my reply (off by default; Android 14+).
  bool get autoReply => _prefs.getBool(_autoReply) ?? false;
  Future<void> setAutoReply(bool on) => _prefs.setBool(_autoReply, on);

  /// Save conversations on this phone (off by default, spec R12).
  bool get saveHistory => _prefs.getBool(_saveHistory) ?? false;
  Future<void> setSaveHistory(bool on) => _prefs.setBool(_saveHistory, on);

  /// Speech speed name: 'slow', 'normal' (default) or 'fast'.
  String? get speechRate => _prefs.getString(_speechRate);
  Future<void> setSpeechRate(String name) => _prefs.setString(_speechRate, name);

  /// Chosen voice per language code, stored as `voice_<code>`; a language without one uses the engine's default.
  Map<String, String> get voices => {
        for (final key in _prefs.getKeys())
          if (key.startsWith(_voicePrefix) && _prefs.get(key) is String) key.substring(_voicePrefix.length): _prefs.getString(key)!,
      };
  /// App language: 'system' (default, follows the phone), 'en', 'hi' or 'gu'.
  String get appLanguage => _prefs.getString(_appLanguage) ?? 'system';
  Future<void> setAppLanguage(String code) => _prefs.setString(_appLanguage, code);

  Future<void> setVoice(String language, String? name) =>
      name == null ? _prefs.remove('$_voicePrefix$language') : _prefs.setString('$_voicePrefix$language', name);
}
