import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap.dart';
import '../../../app/routes.dart';
import '../../../app/theme/anuvaad_colors.dart';
import '../../../app/theme/anuvaad_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/utils/join_list.dart';
import '../../../shared/widgets/brand_logo.dart';
import '../../language_settings/application/language_preferences_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final registry = ref.watch(languageRegistryProvider);
    final prefs = ref.watch(languagePreferencesProvider);
    final core = registry.coreLanguages;
    final myLanguage = registry.byCode(prefs.myLanguage);

    return Scaffold(
      key: const Key('home-screen'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            Text(
              l10n.homeGreeting,
              style: textTheme.labelMedium?.copyWith(color: tokens.muted, letterSpacing: 1.2, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(l10n.homeHeadlineTop, style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: tokens.ink)),
            Text(
              l10n.homeHeadlineBottom,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontStyle: FontStyle.italic,
                color: tokens.blue,
              ),
            ),
            const SizedBox(height: 18),
            _HeroCard(
              title: l10n.homeHeroTitle,
              body: l10n.homeHeroBody(joinList(core.map((l) => l.displayName).toList(), lastSeparator: l10n.listAnd)),
              pills: core.map((l) => l.shortLabel).toList(),
            ),
            const SizedBox(height: 22),
            _SectionRow(title: l10n.homeModesTitle, subtitle: l10n.homeModesSubtitle),
            const SizedBox(height: 10),
            _ModeCard(
              icon: Icons.swap_horiz,
              title: l10n.homeInPersonTitle,
              subtitle: l10n.homeInPersonSubtitle,
              primary: true,
              onTap: () => context.push(Routes.conversation),
            ),
            const SizedBox(height: 10),
            _ModeCard(
              icon: Icons.video_call_outlined,
              title: l10n.homeMeetingTitle,
              subtitle: l10n.homeMeetingSubtitle,
              chip: l10n.homeComingSoon,
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.homeMyLanguage,
                            style: textTheme.labelSmall?.copyWith(color: tokens.muted, letterSpacing: 1.1, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            myLanguage?.nativeFirstLabel ?? prefs.myLanguage,
                            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: tokens.ink),
                          ),
                        ],
                      ),
                    ),
                    TextButton(onPressed: () => context.go(Routes.languages), child: Text(l10n.homeChange)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            _SectionRow(title: l10n.homeQuickAccessTitle, subtitle: l10n.homeQuickAccessSubtitle),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.settings_outlined, size: 18),
                  label: Text(l10n.navSettings),
                  onPressed: () => context.go(Routes.settings),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.title, required this.body, required this.pills});
  final String title;
  final String body;
  final List<String> pills;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cardRadius),
        gradient: LinearGradient(
          colors: [tokens.soft, tokens.card],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: tokens.line),
      ),
      child: Row(
        children: [
          const BrandLogo(size: 96),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: tokens.ink)),
                const SizedBox(height: 4),
                Text(body, style: TextStyle(color: tokens.muted, height: 1.35)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final pill in pills)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: tokens.card, borderRadius: BorderRadius.circular(20)),
                        child: Text(pill, style: TextStyle(fontWeight: FontWeight.w700, color: tokens.blue)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: tokens.ink))),
        Text(subtitle, style: TextStyle(color: tokens.muted, fontSize: 12)),
      ],
    );
  }
}

/// A conversation mode. Without [onTap] it is disabled and shows an honest [chip].
class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.icon, required this.title, required this.subtitle, this.chip, this.primary = false, this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final String? chip;
  final bool primary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.75 : 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: primary ? tokens.blue : tokens.soft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: primary ? Colors.white : tokens.blue),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: tokens.ink)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(color: tokens.muted)),
                      if (chip case final chip?) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: tokens.soft, borderRadius: BorderRadius.circular(12)),
                          child: Text(chip, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tokens.blue)),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onTap != null) Icon(Icons.chevron_right, color: tokens.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
