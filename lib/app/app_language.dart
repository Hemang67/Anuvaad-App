import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings/settings_providers.dart';

/// The languages the app's own text comes in (spec R47).
const appLanguages = ['en', 'hi', 'gu'];

/// Each language named in itself, as language pickers do.
const appLanguageNames = {'en': 'English', 'hi': 'हिन्दी', 'gu': 'ગુજરાતી'};

/// 'system' follows the phone (English when the phone's language isn't one of [appLanguages]).
class AppLanguageController extends Notifier<String> {
  @override
  String build() {
    final saved = ref.watch(settingsRepositoryProvider).appLanguage;
    return appLanguages.contains(saved) ? saved : 'system';
  }

  Future<void> select(String code) async {
    await ref.read(settingsRepositoryProvider).setAppLanguage(code);
    state = code;
  }

  /// The locale to force, or null to follow the phone.
  Locale? get locale => state == 'system' ? null : Locale(state);
}

final appLanguageProvider = NotifierProvider<AppLanguageController, String>(AppLanguageController.new);
