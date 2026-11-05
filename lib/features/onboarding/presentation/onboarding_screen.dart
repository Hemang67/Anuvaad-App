import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/bootstrap.dart';
import '../../../app/theme/anuvaad_colors.dart';
import '../../../app/theme/anuvaad_theme.dart';
import '../../../core/config/app_config.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/utils/join_list.dart';
import '../../../shared/widgets/brand_logo.dart';
import '../application/onboarding_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _pageCount = 3;
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() => ref.read(onboardingCompleteProvider.notifier).complete();

  void _next() => _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    final last = _page == _pageCount - 1;

    return Scaffold(
      key: const Key('onboarding-screen'),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Align(
                alignment: Alignment.centerRight,
                child: last ? null : TextButton(onPressed: _finish, child: Text(l10n.onboardingSkip)),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (page) => setState(() => _page = page),
                children: const [_WelcomePage(), _ModesPage(), _PrivacyPage()],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _pageCount; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _page ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _page ? tokens.blue : tokens.line,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: last ? _finish : _next,
                      child: Text(last ? l10n.onboardingGetStarted : l10n.onboardingNext),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends ConsumerWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final names = ref.watch(languageRegistryProvider).coreLanguages.map((l) => l.displayName).toList();

    return _PageBody(
      children: [
        const BrandLogo(size: 140),
        const SizedBox(height: 20),
        Text(l10n.brandName, style: textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800, color: tokens.ink)),
        const SizedBox(height: 6),
        Text(l10n.brandTagline, textAlign: TextAlign.center, style: textTheme.titleMedium?.copyWith(color: tokens.muted)),
        const SizedBox(height: 28),
        Text(
          l10n.onboardingWelcomeBody(joinList(names, lastSeparator: l10n.listOr)),
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(color: tokens.ink, height: 1.5),
        ),
      ],
    );
  }
}

class _ModesPage extends StatelessWidget {
  const _ModesPage();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _PageBody(
      children: [
        _Title(l10n.onboardingModesTitle),
        const SizedBox(height: 24),
        _InfoCard(icon: Icons.hearing, title: l10n.onboardingListenTitle, body: l10n.onboardingListenBody),
        const SizedBox(height: 12),
        _InfoCard(icon: Icons.mic_none, title: l10n.onboardingSpeakTitle, body: l10n.onboardingSpeakBody),
      ],
    );
  }
}

class _PrivacyPage extends ConsumerWidget {
  const _PrivacyPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    final base = ref.watch(appConfigProvider).apiBaseUrl;
    final points = [
      (Icons.record_voice_over_outlined, l10n.onboardingPrivacySpeech),
      (Icons.translate, l10n.onboardingPrivacyText),
      (Icons.lock_outline, l10n.onboardingPrivacyStorage),
      (Icons.info_outline, l10n.onboardingPrivacyQuality),
    ];
    return _PageBody(
      children: [
        _Title(l10n.onboardingPrivacyTitle),
        const SizedBox(height: 20),
        for (final (icon, text) in points)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: tokens.blue, size: 22),
                const SizedBox(width: 12),
                Expanded(child: Text(text, style: TextStyle(color: tokens.ink, height: 1.4))),
              ],
            ),
          ),
        if (base != null)
          TextButton(
            onPressed: () => launchUrl(base.replace(path: '${base.path}/privacy'), mode: LaunchMode.externalApplication),
            child: Text(l10n.onboardingPrivacyLink),
          ),
      ],
    );
  }
}

class _PageBody extends StatelessWidget {
  const _PageBody({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        child: ConstrainedBox(
          // Centre the content on tall screens; scroll when it doesn't fit.
          constraints: BoxConstraints(minHeight: (constraints.maxHeight - 32).clamp(0, double.infinity)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: children),
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: tokens.ink),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: tokens.soft, borderRadius: BorderRadius.circular(cardRadius / 1.5)),
              child: Icon(icon, color: tokens.blue),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: tokens.ink, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(body, style: TextStyle(color: tokens.muted, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
