import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/anuvaad_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/release_info.dart';

/// "What's new" and "Fixed" bullet lists; an empty section is left out.
class ReleaseNotesView extends StatelessWidget {
  const ReleaseNotesView({super.key, required this.notes});

  final ReleaseNotes notes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (notes.whatsNew.isNotEmpty) _NotesSection(title: l10n.updateWhatsNew, items: notes.whatsNew),
        if (notes.fixed.isNotEmpty) _NotesSection(title: l10n.updateFixed, items: notes.fixed),
      ],
    );
  }
}

class _NotesSection extends StatelessWidget {
  const _NotesSection({required this.title, required this.items});
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: tokens.ink)),
          const SizedBox(height: 6),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: TextStyle(color: tokens.blue, fontWeight: FontWeight.w800)),
                  Expanded(child: Text(item, style: TextStyle(color: tokens.ink, height: 1.35))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// "Nov 12, 2026" in the current locale.
String formatReleaseDate(BuildContext context, DateTime date) =>
    DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).format(date.toLocal());

/// Bytes as megabytes with one decimal (bytes ÷ 1,048,576), matching the website.
String formatMegabytes(int bytes) => (bytes / 1048576).toStringAsFixed(1);
