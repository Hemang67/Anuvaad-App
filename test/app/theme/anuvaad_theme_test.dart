import 'package:anuvaad/app/theme/anuvaad_colors.dart';
import 'package:anuvaad/app/theme/anuvaad_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('light theme uses prototype tokens', () {
    final t = buildAnuvaadTheme(Brightness.light);
    expect(t.brightness, Brightness.light);
    expect(t.scaffoldBackgroundColor, const Color(0xFFF5F8FF));
    expect(t.colorScheme.primary, const Color(0xFF1678ED));
    expect(t.colorScheme.surface, const Color(0xFFFFFFFF));
    expect(t.colorScheme.onSurface, const Color(0xFF102746));
    expect(t.extension<AnuvaadColors>(), same(AnuvaadColors.light));
  });

  test('dark theme uses prototype tokens', () {
    final t = buildAnuvaadTheme(Brightness.dark);
    expect(t.brightness, Brightness.dark);
    expect(t.scaffoldBackgroundColor, const Color(0xFF081629));
    expect(t.colorScheme.primary, const Color(0xFF4C9CFF));
    expect(t.colorScheme.surface, const Color(0xFF11243B));
    expect(t.colorScheme.onSurface, const Color(0xFFEDF5FF));
    expect(t.extension<AnuvaadColors>(), same(AnuvaadColors.dark));
  });

  test('text uses Inter with Devanagari and Gujarati fallbacks', () {
    final s = buildAnuvaadTheme(Brightness.light).textTheme.bodyMedium!;
    expect(s.fontFamily, 'Inter');
    expect(s.fontFamilyFallback, ['NotoSansDevanagari', 'NotoSansGujarati']);
  });

  test('cards use the prototype 18 px radius', () {
    final shape = buildAnuvaadTheme(Brightness.light).cardTheme.shape as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(18));
  });

  test('AnuvaadColors.lerp blends tokens halfway', () {
    final mid = AnuvaadColors.light.lerp(AnuvaadColors.dark, 0.5);
    expect(mid.bg, Color.lerp(const Color(0xFFF5F8FF), const Color(0xFF081629), 0.5));
  });

  test('selected segments use the brand soft colour, not a seed-derived tint', () {
    final style = buildAnuvaadTheme(Brightness.light).segmentedButtonTheme.style!;
    expect(style.backgroundColor!.resolve({WidgetState.selected}), const Color(0xFFEAF4FF));
    expect(style.foregroundColor!.resolve({WidgetState.selected}), const Color(0xFF1678ED));
  });
}
