import 'dart:math';

import 'package:anuvaad/app/theme/anuvaad_colors.dart';
import 'package:anuvaad/app/theme/anuvaad_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _luminance(Color c) {
  double channel(double v) => v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double contrast(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

void main() {
  for (final brightness in Brightness.values) {
    test('text colours meet WCAG AA in the ${brightness.name} theme', () {
      final theme = buildAnuvaadTheme(brightness);
      final t = theme.extension<AnuvaadColors>()!;
      final scheme = theme.colorScheme;
      final pairs = {
        'ink on background': (t.ink, t.bg),
        'ink on card': (t.ink, t.card),
        'ink on soft': (t.ink, t.soft),
        'muted on background': (t.muted, t.bg),
        'muted on card': (t.muted, t.card),
        'muted on soft': (t.muted, t.soft),
        'blue links on card': (t.blue, t.card),
        'blue links on background': (t.blue, t.bg),
        'filled button label on primary': (scheme.onPrimary, scheme.primary),
      };
      for (final MapEntry(key: name, value: (fg, bg)) in pairs.entries) {
        expect(contrast(fg, bg), greaterThanOrEqualTo(4.5), reason: '$name is ${contrast(fg, bg).toStringAsFixed(2)}:1');
      }
    });
  }
}
