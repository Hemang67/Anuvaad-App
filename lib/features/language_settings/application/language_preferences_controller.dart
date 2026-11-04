import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap.dart';
import '../../../core/settings/settings_providers.dart';
import '../../../services/language_registry/language_registry.dart';

const autoDetect = 'auto';

/// The user's language and the other person's language ('auto' or a core code).
class LanguagePreferences {
  const LanguagePreferences({required this.myLanguage, required this.otherLanguage});

  final String myLanguage;
  final String otherLanguage;

  bool get isValid => otherLanguage == autoDetect || otherLanguage != myLanguage;
}

LanguagePreferences swapLanguages(LanguagePreferences p) {
  if (p.otherLanguage == autoDetect) throw ArgumentError('Cannot swap while the other language is automatic');
  return LanguagePreferences(myLanguage: p.otherLanguage, otherLanguage: p.myLanguage);
}

final languagePreferencesProvider =
    NotifierProvider<LanguagePreferencesController, LanguagePreferences>(LanguagePreferencesController.new);

class LanguagePreferencesController extends Notifier<LanguagePreferences> {
  @override
  LanguagePreferences build() {
    final settings = ref.watch(settingsRepositoryProvider);
    final registry = ref.watch(languageRegistryProvider);
    bool isCore(String? code) => code != null && registry.coreLanguages.any((l) => l.code == code);

    final stored = settings.myLanguage;
    final my = isCore(stored) ? stored! : defaultMyLanguage(PlatformDispatcher.instance.locale);
    final other = settings.otherLanguage;
    return LanguagePreferences(
      myLanguage: my,
      otherLanguage: other == autoDetect || (isCore(other) && other != my) ? other : autoDetect,
    );
  }

  Future<void> save(LanguagePreferences prefs) async {
    if (!prefs.isValid) throw ArgumentError('Choose two different languages');
    final settings = ref.read(settingsRepositoryProvider);
    await settings.setMyLanguage(prefs.myLanguage);
    await settings.setOtherLanguage(prefs.otherLanguage);
    state = prefs;
  }
}
