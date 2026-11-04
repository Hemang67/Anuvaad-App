import 'package:anuvaad/features/app_update/domain/release_info.dart';
import 'package:anuvaad/features/app_update/domain/update_decision.dart';
import 'package:flutter_test/flutter_test.dart';

ReleaseInfo release({
  int build = 2,
  bool mandatory = false,
  int minSupportedBuild = 1,
  List<String> abis = const ['arm64-v8a', 'armeabi-v7a', 'x86_64', 'universal'],
}) {
  return ReleaseInfo(
    schema: 1,
    version: '0.1.$build',
    build: build,
    publishedAt: DateTime.utc(2026, 11, 12),
    mandatory: mandatory,
    minSupportedBuild: minSupportedBuild,
    notes: const ReleaseNotes(whatsNew: ['New'], fixed: []),
    assets: [
      for (final abi in abis)
        ApkAsset(
          abi: abi,
          file: 'anuvaad-0.1.$build-$abi.apk',
          url: Uri.parse('https://example.com/anuvaad-0.1.$build-$abi.apk'),
          size: 100,
          sha256: 'a' * 64,
        ),
    ],
    releaseUrl: Uri.parse('https://example.com/v0.1.$build'),
  );
}

void main() {
  test('newer build on an arm64 device is optional with the arm64 asset', () {
    final d = decideUpdate(currentBuild: 1, deviceAbis: ['arm64-v8a', 'armeabi-v7a'], latest: release(build: 2));
    expect(d.kind, UpdateKind.optional);
    expect(d.asset!.abi, 'arm64-v8a');
    expect(d.release!.build, 2);
  });

  test('device ABI order wins over asset order', () {
    final d = decideUpdate(currentBuild: 1, deviceAbis: ['armeabi-v7a'], latest: release(build: 2));
    expect(d.asset!.abi, 'armeabi-v7a');
  });

  test('same build is no update', () {
    expect(decideUpdate(currentBuild: 2, deviceAbis: ['arm64-v8a'], latest: release(build: 2)).kind, UpdateKind.none);
  });

  test('an older published build is no update', () {
    expect(decideUpdate(currentBuild: 5, deviceAbis: ['arm64-v8a'], latest: release(build: 2)).kind, UpdateKind.none);
  });

  test('no published release is no update', () {
    expect(decideUpdate(currentBuild: 1, deviceAbis: ['arm64-v8a'], latest: null).kind, UpdateKind.none);
  });

  test('below minSupportedBuild is mandatory', () {
    final d = decideUpdate(currentBuild: 1, deviceAbis: ['arm64-v8a'], latest: release(build: 3, minSupportedBuild: 2));
    expect(d.kind, UpdateKind.mandatory);
  });

  test('mandatory flag forces mandatory', () {
    final d = decideUpdate(currentBuild: 2, deviceAbis: ['arm64-v8a'], latest: release(build: 3, mandatory: true));
    expect(d.kind, UpdateKind.mandatory);
  });

  test('unknown ABI falls back to universal', () {
    final d = decideUpdate(currentBuild: 1, deviceAbis: ['x86'], latest: release(build: 2));
    expect(d.asset!.abi, 'universal');
  });

  test('no matching ABI and no universal means no update', () {
    final d = decideUpdate(currentBuild: 1, deviceAbis: ['x86'], latest: release(build: 2, abis: ['arm64-v8a']));
    expect(d.kind, UpdateKind.none);
    expect(d.asset, isNull);
  });
}
