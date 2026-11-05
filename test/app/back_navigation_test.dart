import 'package:anuvaad/core/config/app_config.dart';
import 'package:anuvaad/features/app_update/data/update_repository.dart';
import 'package:anuvaad/features/app_update/domain/release_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/app_harness.dart';

class _MockRepository extends Mock implements UpdateRepository {}

const _onboarded = <String, Object>{'onboarding_complete': true};

/// Presses Android Back; true when Android was asked to close the app (SystemNavigator.pop).
Future<bool> _pressBack(WidgetTester tester) async {
  var exited = false;
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'SystemNavigator.pop') exited = true;
    return null;
  });
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
  return exited;
}

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(NavigationDestination, label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('back from the Languages tab returns to Home instead of leaving the app', (tester) async {
    await pumpAnuvaadApp(tester, prefs: _onboarded);
    await _openTab(tester, 'Languages');

    expect(await _pressBack(tester), isFalse);
    expect(find.byKey(const Key('home-screen')), findsOneWidget);
  });

  testWidgets('back from the Settings tab returns to Home', (tester) async {
    await pumpAnuvaadApp(tester, prefs: _onboarded);
    await _openTab(tester, 'Settings');

    expect(await _pressBack(tester), isFalse);
    expect(find.byKey(const Key('home-screen')), findsOneWidget);
  });

  testWidgets('back on Home leaves the app', (tester) async {
    await pumpAnuvaadApp(tester, prefs: _onboarded);

    expect(await _pressBack(tester), isTrue);
  });

  testWidgets('back from Release notes returns to Settings', (tester) async {
    final repo = _MockRepository();
    when(() => repo.fetchAll()).thenAnswer((_) async => const <ReleaseInfo>[]);
    await pumpAnuvaadApp(
      tester,
      prefs: _onboarded,
      config: AppConfig.parse(apiBaseUrl: 'https://anuvaad.example', releasesRepo: 'test/anuvaad-app'),
      overrides: [updateRepositoryProvider.overrideWithValue(repo)],
    );
    await _openTab(tester, 'Settings');
    await tester.tap(find.text('Release notes'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('release-notes-screen')), findsOneWidget);

    expect(await _pressBack(tester), isFalse);
    expect(find.byKey(const Key('settings-screen')), findsOneWidget);
  });

  testWidgets('back on a later onboarding page returns to the previous page', (tester) async {
    await pumpAnuvaadApp(tester);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Two simple modes'), findsOneWidget);

    expect(await _pressBack(tester), isFalse);
    expect(find.text('Talk naturally with people who speak English, Hindi or Gujarati.'), findsOneWidget);
  });

  testWidgets('back on the first onboarding page leaves the app', (tester) async {
    await pumpAnuvaadApp(tester);
    expect(await _pressBack(tester), isTrue);
  });
}
