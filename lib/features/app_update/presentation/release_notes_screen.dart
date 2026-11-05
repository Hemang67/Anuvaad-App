import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/anuvaad_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../data/update_repository.dart';
import '../domain/release_info.dart';
import 'release_notes_view.dart';

final releaseHistoryProvider = FutureProvider.autoDispose<List<ReleaseInfo>>(
  (ref) => ref.watch(updateRepositoryProvider).fetchAll(),
  retry: (retryCount, error) => null,
);

class ReleaseNotesScreen extends ConsumerWidget {
  const ReleaseNotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    final history = ref.watch(releaseHistoryProvider);

    return Scaffold(
      key: const Key('release-notes-screen'),
      appBar: AppBar(title: Text(l10n.releaseNotesTitle)),
      body: switch (history) {
        AsyncData(:final value) when value.isEmpty =>
          Center(child: Text(l10n.releaseNotesEmpty, style: TextStyle(color: tokens.muted))),
        AsyncData(:final value) => ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: value.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final release = value[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.releaseNotesVersion(release.version),
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: tokens.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(formatReleaseDate(context, release.publishedAt), style: TextStyle(color: tokens.muted)),
                      ReleaseNotesView(notes: release.notes),
                    ],
                  ),
                ),
              );
            },
          ),
        AsyncError() => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.releaseNotesLoadFailed, style: TextStyle(color: tokens.ink)),
                const SizedBox(height: 8),
                FilledButton(onPressed: () => ref.invalidate(releaseHistoryProvider), child: Text(l10n.tryAgain)),
              ],
            ),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
