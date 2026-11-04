import 'release_info.dart';

enum UpdateKind { none, optional, mandatory }

class UpdateDecision {
  const UpdateDecision({required this.kind, this.release, this.asset});

  const UpdateDecision.none()
      : kind = UpdateKind.none,
        release = null,
        asset = null;

  final UpdateKind kind;
  final ReleaseInfo? release;
  final ApkAsset? asset;
}

/// The APK for the first device ABI that has one, else the universal APK, else null.
ApkAsset? selectAsset(List<ApkAsset> assets, List<String> deviceAbis) {
  for (final abi in deviceAbis) {
    for (final asset in assets) {
      if (asset.abi == abi) return asset;
    }
  }
  for (final asset in assets) {
    if (asset.abi == 'universal') return asset;
  }
  return null;
}

UpdateDecision decideUpdate({required int currentBuild, required List<String> deviceAbis, required ReleaseInfo? latest}) {
  if (latest == null || latest.build <= currentBuild) return const UpdateDecision.none();
  final asset = selectAsset(latest.assets, deviceAbis);
  if (asset == null) return const UpdateDecision.none();
  final mandatory = latest.mandatory || currentBuild < latest.minSupportedBuild;
  return UpdateDecision(kind: mandatory ? UpdateKind.mandatory : UpdateKind.optional, release: latest, asset: asset);
}
