import 'dart:convert';

import 'package:anuvaad/app/theme/anuvaad_theme.dart';
import 'package:anuvaad/core/config/app_config.dart';
import 'package:anuvaad/features/app_update/application/update_controller.dart';
import 'package:anuvaad/features/app_update/data/update_repository.dart';
import 'package:anuvaad/features/app_update/domain/release_info.dart';
import 'package:anuvaad/features/app_update/domain/update_decision.dart';
import 'package:anuvaad/features/app_update/presentation/update_dialog.dart';
import 'package:anuvaad/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/app_harness.dart';

class _MockRepository extends Mock implements UpdateRepository {}

/// Test double: a controller with a fixed state that records user actions.
class _FakeController extends UpdateController {
  _FakeController(this.initial);
  final UpdateState initial;
  int startCalls = 0;
  int grantCalls = 0;
  int laterCalls = 0;

  @override
  UpdateState build() => initial;

  @override
  Future<void> startUpdate() async => startCalls++;

  @override
  Future<void> grantPermissionAndContinue() async => grantCalls++;

  @override
  void later() => laterCalls++;
}

ReleaseInfo _release({int build = 2, List<String> whatsNew = const ['Release notes history in Settings.'],
    List<String> fixed = const ['Update popup text fits large font sizes.']}) {
  return ReleaseInfo(
    schema: 1,
    version: '0.1.$build',
    build: build,
    publishedAt: DateTime(2026, 11, 12, 12),
    mandatory: false,
    minSupportedBuild: 1,
    notes: ReleaseNotes(whatsNew: whatsNew, fixed: fixed),
    assets: [
      ApkAsset(
        abi: 'arm64-v8a',
        file: 'anuvaad-0.1.$build-arm64-v8a.apk',
        url: Uri.parse('https://example.com/a.apk'),
        size: 21495808,
        sha256: 'a' * 64,
      ),
    ],
    releaseUrl: Uri.parse('https://example.com/v0.1.$build'),
  );
}

UpdateDecision _decision({UpdateKind kind = UpdateKind.optional, ReleaseInfo? release}) {
  final r = release ?? _release();
  return UpdateDecision(kind: kind, release: r, asset: r.assets.first);
}

const _config = AppConfig(apiBaseUrl: null, releasesRepo: null);

/// Opens the update dialog over a bare screen with [state].
Future<_FakeController> _openDialog(
  WidgetTester tester,
  UpdateState state, {
  ThemeMode mode = ThemeMode.light,
  double textScale = 1,
  AppConfig config = _config,
}) async {
  final fake = _FakeController(state);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      updateControllerProvider.overrideWith(() => fake),
      appConfigProvider.overrideWithValue(config),
    ],
    child: MaterialApp(
      theme: buildAnuvaadTheme(Brightness.light),
      darkTheme: buildAnuvaadTheme(Brightness.dark),
      themeMode: mode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [Locale('en')],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(child: TextButton(onPressed: () => showUpdateDialog(context), child: const Text('open'))),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return fake;
}

void main() {
  setUpAll(() => registerFallbackValue(UpdateTrigger.manual));

  testWidgets('optional update dialog shows notes sections and Later', (tester) async {
    final fake = await _openDialog(tester, UpdateAvailable(_decision()));
    expect(find.text('Update available'), findsOneWidget);
    expect(find.text('Version 0.1.2 · Nov 12, 2026 · 20.5 MB'), findsOneWidget);
    expect(find.text("What's new"), findsOneWidget);
    expect(find.text('Release notes history in Settings.'), findsOneWidget);
    expect(find.text('Fixed'), findsOneWidget);
    expect(find.text('This update is required to keep using Anuvaad.'), findsNothing);

    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    expect(fake.laterCalls, 1);
    expect(find.text('Update available'), findsNothing);
  });

  testWidgets('an empty notes section is omitted', (tester) async {
    await _openDialog(tester, UpdateAvailable(_decision(release: _release(fixed: const []))));
    expect(find.text("What's new"), findsOneWidget);
    expect(find.text('Fixed'), findsNothing);
  });

  testWidgets('mandatory dialog has no Later and cannot be dismissed with back', (tester) async {
    final fake = await _openDialog(tester, UpdateAvailable(_decision(kind: UpdateKind.mandatory)));
    expect(find.text('This update is required to keep using Anuvaad.'), findsOneWidget);
    expect(find.text('Later'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Update available'), findsOneWidget);
    expect(fake.laterCalls, 0);
  });

  testWidgets('long Gujarati notes at 200% text scale stay scrollable with Update now reachable', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final notes = List.generate(40, (i) => 'અપડેટ નોંધ $i: ભાષાંતર હવે વધુ ઝડપી અને સ્પષ્ટ છે.');
    final fake = await _openDialog(
      tester,
      UpdateAvailable(_decision(release: _release(whatsNew: notes))),
      mode: ThemeMode.dark,
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    final button = find.text('Update now');
    await tester.ensureVisible(button);
    final rect = tester.getRect(button);
    expect(rect.bottom <= 640 && rect.top >= 0, isTrue, reason: 'Update now must be on screen: $rect');
    await tester.tap(button);
    await tester.pump();
    expect(fake.startCalls, 1);
  });

  testWidgets('downloading state shows percentage', (tester) async {
    await _openDialog(tester, UpdateDownloading(_decision(), received: 50, total: 200));
    expect(find.text('Downloading… 25%'), findsOneWidget);
    expect(find.text('Later'), findsNothing);
    final bar = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
    expect(bar.value, 0.25);
  });

  testWidgets('needs-permission state shows Open settings', (tester) async {
    final fake = await _openDialog(tester, UpdateNeedsPermission(_decision()));
    expect(find.text('Allow updates'), findsOneWidget);
    await tester.tap(find.text('Open settings'));
    await tester.pump();
    expect(fake.grantCalls, 1);
  });

  testWidgets('denied permission explains and offers Try again, never re-requesting on its own', (tester) async {
    final fake = await _openDialog(tester, UpdateFailed(_decision(), UpdateFailure.permissionDenied));
    expect(
      find.text("Updates can't be installed until you allow this. You can try again any time from Settings → Check for updates."),
      findsOneWidget,
    );
    expect(fake.grantCalls, 0);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(fake.startCalls, 1);
  });

  testWidgets('integrity failure explains the damaged download', (tester) async {
    await _openDialog(tester, UpdateFailed(_decision(), UpdateFailure.integrityFailed));
    expect(find.text("The download was damaged, so it wasn't installed. Please try again."), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });

  testWidgets('install-not-completed state explains reinstall and offers Open website', (tester) async {
    await _openDialog(
      tester,
      UpdateInstallNotCompleted(_decision()),
      config: AppConfig.parse(apiBaseUrl: 'https://anuvaad.example', releasesRepo: ''),
    );
    expect(find.text("The update wasn't installed"), findsOneWidget);
    expect(
      find.text('If Android said “App not installed”, uninstall this copy of Anuvaad and install it again from the website.'),
      findsOneWidget,
    );
    expect(find.text('Open website'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  group('in the app', () {
    late _MockRepository repo;
    final api = AppConfig.parse(apiBaseUrl: 'https://anuvaad.example', releasesRepo: 'test/anuvaad-app');

    setUp(() {
      repo = _MockRepository();
      when(() => repo.fetchLatest()).thenAnswer((_) async => null);
      when(() => repo.fetchAll()).thenAnswer((_) async => [_release(build: 2), _release(build: 1)]);
    });

    List<Override> overrides() => [
          updateRepositoryProvider.overrideWithValue(repo),
          deviceAbisProvider.overrideWith((ref) async => ['arm64-v8a']),
        ];

    /// Opens Settings and scrolls to the About rows (Check for updates, Release notes) at the bottom.
    Future<void> openSettings(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
      await tester.pumpAndSettle();
      await scrollIntoView(tester, find.text('Release notes'));
    }

    testWidgets('update popup appears on launch when a newer build exists', (tester) async {
      when(() => repo.fetchLatest()).thenAnswer((_) async => _release(build: 2));
      await pumpAnuvaadApp(tester, prefs: {'onboarding_complete': true}, config: api, overrides: overrides());
      expect(find.text('Update available'), findsOneWidget);
      expect(find.text('Version 0.1.2 · Nov 12, 2026 · 20.5 MB'), findsOneWidget);
    });

    testWidgets("What's new sheet appears once after update", (tester) async {
      final prefs = await pumpAnuvaadApp(
        tester,
        prefs: {
          'onboarding_complete': true,
          'pending_update': jsonEncode(_release(build: 2).toJson()),
          'last_seen_build': 1,
        },
        buildNumber: '2',
        version: '0.1.2',
        config: api,
        overrides: overrides(),
      );
      expect(find.text("What's new in 0.1.2"), findsOneWidget);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(find.text("What's new in 0.1.2"), findsNothing);
      expect(prefs.getString('pending_update'), isNull);
    });

    testWidgets('Settings Check for updates shows up-to-date snackbar', (tester) async {
      await pumpAnuvaadApp(tester, prefs: {'onboarding_complete': true}, config: api, overrides: overrides());
      await openSettings(tester);
      await tester.tap(find.text('Check for updates'));
      await tester.pumpAndSettle();
      expect(find.text("You're on the latest version"), findsOneWidget);
    });

    testWidgets('release notes screen lists releases newest first', (tester) async {
      await pumpAnuvaadApp(tester, prefs: {'onboarding_complete': true}, config: api, overrides: overrides());
      await openSettings(tester);
      await tester.tap(find.text('Release notes'));
      await tester.pumpAndSettle();
      final newer = tester.getTopLeft(find.text('Version 0.1.2'));
      final older = tester.getTopLeft(find.text('Version 0.1.1'));
      expect(newer.dy < older.dy, isTrue);
    });

    testWidgets('release notes screen offers Try again when loading fails', (tester) async {
      when(() => repo.fetchAll()).thenThrow(const UpdateCheckException('offline'));
      await pumpAnuvaadApp(tester, prefs: {'onboarding_complete': true}, config: api, overrides: overrides());
      await openSettings(tester);
      await tester.tap(find.text('Release notes'));
      await tester.pumpAndSettle();
      expect(find.text("Couldn't load release notes."), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('a build without an update source disables the update rows', (tester) async {
      await pumpAnuvaadApp(tester, prefs: {'onboarding_complete': true}, overrides: overrides());
      await openSettings(tester);
      expect(find.text("Updates aren't available in this preview build."), findsOneWidget);
      final row = tester.widget<ListTile>(find.widgetWithText(ListTile, 'Check for updates'));
      expect(row.onTap, isNull);
      expect(row.enabled, isFalse);
      expect(tester.widget<ListTile>(find.widgetWithText(ListTile, 'Release notes')).enabled, isFalse);
      verifyNever(() => repo.fetchLatest());
    });
  });
}
