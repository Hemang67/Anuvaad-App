import 'package:flutter/material.dart';

import '../../../app/theme/anuvaad_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/release_info.dart';
import 'release_notes_view.dart';

/// One-time "What's new" sheet shown on the first launch after an update.
Future<void> showWhatsNewSheet(BuildContext context, ReleaseInfo release) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      final tokens = Theme.of(context).extension<AnuvaadColors>()!;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.whatsNewTitle(release.version),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: tokens.ink),
                ),
                Flexible(child: SingleChildScrollView(child: ReleaseNotesView(notes: release.notes))),
                const SizedBox(height: 16),
                FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.whatsNewGotIt)),
              ],
            ),
          ),
        ),
      );
    },
  );
}
