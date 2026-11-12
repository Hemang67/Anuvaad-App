import 'package:flutter/material.dart';

import '../../../app/theme/anuvaad_colors.dart';

/// A titled group of [SettingsRow]s in a card.
class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, required this.title, this.subtitle, required this.children});

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Side by side when they fit; the subtitle wraps under the title at large text sizes.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 8,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: tokens.ink)),
              if (subtitle != null) Text(subtitle!, style: TextStyle(color: tokens.muted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Card(child: Column(children: children)),
        ],
      ),
    );
  }
}

/// One line in a [SettingsSection]: title, optional subtitle, trailing widget, optional tap.
class SettingsRow extends StatelessWidget {
  const SettingsRow({super.key, required this.title, this.subtitle, this.trailing, this.onTap, this.enabled = true});

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// False draws the row greyed out (for features unavailable in this build).
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    return ListTile(
      enabled: enabled,
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: enabled ? tokens.ink : tokens.muted)),
      subtitle: subtitle == null ? null : Text(subtitle!, style: TextStyle(color: tokens.muted)),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
