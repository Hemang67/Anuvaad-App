import 'package:anuvaad/app/theme/anuvaad_theme.dart';
import 'package:anuvaad/l10n/app_localizations.dart';
import 'package:anuvaad/shared/widgets/brand_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('logo sits on a circular badge in the ${brightness.name} theme', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: buildAnuvaadTheme(brightness),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: const [Locale('en')],
        home: const Scaffold(body: Center(child: BrandLogo(size: 120))),
      ));
      expect(find.descendant(of: find.byType(BrandLogo), matching: find.byType(ClipOval)), findsOneWidget);
      expect(tester.getSize(find.byType(ClipOval)), const Size(120, 120));
      expect(find.bySemanticsLabel('Anuvaad logo'), findsOneWidget);
    });
  }
}
