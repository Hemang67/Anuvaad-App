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
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: tokens.ink))),
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
  const SettingsRow({super.key, required this.title, this.subtitle, this.trailing, this.onTap});

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    return ListTile(
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: tokens.ink)),
      subtitle: subtitle == null ? null : Text(subtitle!, style: TextStyle(color: tokens.muted)),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
