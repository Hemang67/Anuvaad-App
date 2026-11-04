import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap.dart';
import '../../../app/theme/anuvaad_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/brand_logo.dart';

/// Branded splash shown while [bootstrapProvider] loads. The router leaves this
/// screen as soon as loading finishes; there is no artificial delay.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const indicatorDelay = Duration(milliseconds: 600);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _indicatorTimer;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    _indicatorTimer = Timer(SplashScreen.indicatorDelay, () {
      if (mounted) setState(() => _slow = true);
    });
  }

  @override
  void dispose() {
    _indicatorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bootstrap = ref.watch(bootstrapProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              const Spacer(),
              const BrandLogo(size: 120),
              const SizedBox(height: 16),
              Text(
                l10n.brandName,
                style: textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800, color: tokens.ink),
              ),
              const SizedBox(height: 6),
              Text(l10n.brandTagline, style: textTheme.titleMedium?.copyWith(color: tokens.muted), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Expanded(
                flex: 5,
                child: dark
                    ? const SizedBox.shrink()
                    : Image.asset('assets/branding/globe_light_interim.jpg', fit: BoxFit.contain, excludeFromSemantics: true),
              ),
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 72),
                child: Center(
                  child: bootstrap.hasError
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(l10n.splashStartFailed, textAlign: TextAlign.center, style: TextStyle(color: tokens.ink)),
                            const SizedBox(height: 8),
                            FilledButton(
                              onPressed: () => ref.invalidate(bootstrapProvider),
                              child: Text(l10n.tryAgain),
                            ),
                          ],
                        )
                      : (_slow && bootstrap.isLoading)
                          ? SizedBox(
                              width: 160,
                              child: LinearProgressIndicator(
                                color: tokens.blue,
                                backgroundColor: tokens.soft,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            )
                          : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
