import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Background colour of the approved logo image (median of its border pixels).
const logoBackgroundColor = Color(0xFFFCFCFE);

const _logoAsset = 'assets/branding/logo_interim.png';

/// The approved Anuvaad logo, never redrawn. In dark theme it sits on a circular
/// badge in its own background colour, because the image is not transparent.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(context).brandLogoLabel;
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (!dark) {
      return Image.asset(_logoAsset, width: size, fit: BoxFit.contain, semanticLabel: label);
    }
    return Semantics(
      label: label,
      image: true,
      child: ExcludeSemantics(
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
    );
  }
}
