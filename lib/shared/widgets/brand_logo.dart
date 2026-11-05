import 'package:flutter/material.dart';

import '../../app/theme/anuvaad_colors.dart';
import '../../l10n/app_localizations.dart';

/// Background colour of the approved logo image (median of its border pixels).
const logoBackgroundColor = Color(0xFFFCFCFE);

const _logoAsset = 'assets/branding/logo_interim.png';

/// The approved Anuvaad logo, never redrawn. The image is not transparent, so it
/// always sits on a circular badge in its own background colour; [size] is the
/// badge diameter.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(context).brandLogoLabel;
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    final light = Theme.of(context).brightness == Brightness.light;
    return Semantics(
      label: label,
      image: true,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: light ? Border.all(color: tokens.line) : null,
            boxShadow: light ? [BoxShadow(color: tokens.blue.withValues(alpha: 0.10), blurRadius: 24, offset: const Offset(0, 8))] : null,
          ),
          child: ClipOval(
            child: Container(
              width: size,
              height: size,
              color: logoBackgroundColor,
              alignment: Alignment.center,
              child: Image.asset(_logoAsset, width: size * 0.8, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
