import 'package:flutter/material.dart';

import 'anuvaad_colors.dart';

const _fontFamily = 'Inter';
const _fontFallback = ['NotoSansDevanagari', 'NotoSansGujarati'];
const cardRadius = 18.0;

/// Material 3 theme built from the Anuvaad tokens for [brightness].
ThemeData buildAnuvaadTheme(Brightness brightness) {
  final tokens = brightness == Brightness.dark ? AnuvaadColors.dark : AnuvaadColors.light;
  final scheme = ColorScheme.fromSeed(seedColor: tokens.blue, brightness: brightness).copyWith(
    primary: tokens.blue,
    secondary: tokens.cyan,
    tertiary: tokens.green,
    surface: tokens.card,
    onSurface: tokens.ink,
    onSurfaceVariant: tokens.muted,
    outline: tokens.line,
    outlineVariant: tokens.line,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: tokens.bg,
    fontFamily: _fontFamily,
    fontFamilyFallback: _fontFallback,
    cardTheme: CardThemeData(
      color: tokens.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        side: BorderSide(color: tokens.line),
      ),
    ),
    extensions: <ThemeExtension<dynamic>>[tokens],
  );
}
