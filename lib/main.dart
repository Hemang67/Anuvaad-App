import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicenses();
  runApp(const ProviderScope(child: AnuvaadApp()));
}

void _registerFontLicenses() {
  const licenses = {
    'Inter': 'assets/fonts/licenses/OFL-Inter.txt',
    'Noto Sans Devanagari': 'assets/fonts/licenses/OFL-NotoSansDevanagari.txt',
    'Noto Sans Gujarati': 'assets/fonts/licenses/OFL-NotoSansGujarati.txt',
  };
  LicenseRegistry.addLicense(() async* {
    for (final entry in licenses.entries) {
      yield LicenseEntryWithLineBreaks([entry.key], await rootBundle.loadString(entry.value));
    }
  });
}
