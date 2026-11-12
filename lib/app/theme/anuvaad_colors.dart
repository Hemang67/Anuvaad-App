import 'package:flutter/material.dart';

/// Anuvaad colour tokens, taken from the approved prototype (design §1.2).
@immutable
class AnuvaadColors extends ThemeExtension<AnuvaadColors> {
  const AnuvaadColors({
    required this.bg,
    required this.card,
    required this.ink,
    required this.muted,
    required this.line,
    required this.blue,
    required this.cyan,
    required this.soft,
    required this.green,
  });

  final Color bg;
  final Color card;
  final Color ink;
  final Color muted;
  final Color line;
  final Color blue;
  final Color cyan;
  final Color soft;
  final Color green;

  static const light = AnuvaadColors(
    bg: Color(0xFFF5F8FF),
    card: Color(0xFFFFFFFF),
    ink: Color(0xFF102746),
    // Prototype #6D7D91 was 3.96:1 on the background; darkened to meet WCAG AA 4.5:1 (spec R48).
    muted: Color(0xFF5C6B7E),
    line: Color(0xFFE3EAF3),
    // Prototype #1678ED was 4.25:1 with white; darkened a little to meet WCAG AA 4.5:1 for links and button labels.
    blue: Color(0xFF1269D3),
    cyan: Color(0xFF28B8E9),
    soft: Color(0xFFEAF4FF),
    green: Color(0xFF13A879),
  );

  static const dark = AnuvaadColors(
    bg: Color(0xFF081629),
    card: Color(0xFF11243B),
    ink: Color(0xFFEDF5FF),
    muted: Color(0xFFA7B8CB),
    line: Color(0xFF29415B),
    blue: Color(0xFF4C9CFF),
    cyan: Color(0xFF38C7EC),
    soft: Color(0xFF183451),
    green: Color(0xFF13A879),
  );

  @override
  AnuvaadColors copyWith({
    Color? bg,
    Color? card,
    Color? ink,
    Color? muted,
    Color? line,
    Color? blue,
    Color? cyan,
    Color? soft,
    Color? green,
  }) {
    return AnuvaadColors(
      bg: bg ?? this.bg,
      card: card ?? this.card,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      line: line ?? this.line,
      blue: blue ?? this.blue,
      cyan: cyan ?? this.cyan,
      soft: soft ?? this.soft,
      green: green ?? this.green,
    );
  }

  @override
  AnuvaadColors lerp(covariant ThemeExtension<AnuvaadColors>? other, double t) {
    if (other is! AnuvaadColors) return this;
    return AnuvaadColors(
      bg: Color.lerp(bg, other.bg, t)!,
      card: Color.lerp(card, other.card, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      line: Color.lerp(line, other.line, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
      cyan: Color.lerp(cyan, other.cyan, t)!,
      soft: Color.lerp(soft, other.soft, t)!,
      green: Color.lerp(green, other.green, t)!,
    );
  }
}
