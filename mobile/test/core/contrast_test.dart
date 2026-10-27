import 'dart:math';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentra/core/theme/app_colors.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

Color _over(Color top, Color bottom) => Color.alphaBlend(top, bottom);

void main() {
  const backgrounds = {
    'background': AppColors.background,
    'surface': AppColors.surface,
  };

  test('text colours meet WCAG AA (4.5:1) on page and surface', () {
    const text = {
      'text': AppColors.text,
      'textSecondary': AppColors.textSecondary,
      'primary': AppColors.primary,
      'error': AppColors.error,
      'info': AppColors.info,
      'warningStrong': AppColors.warningStrong,
    };
    for (final fg in text.entries) {
      for (final bg in backgrounds.entries) {
        expect(
          _contrast(fg.value, bg.value),
          greaterThanOrEqualTo(4.5),
          reason: '${fg.key} on ${bg.key}',
        );
      }
    }
  });

  test('text on filled colours meets AA', () {
    expect(_contrast(AppColors.onPrimary, AppColors.primary), greaterThanOrEqualTo(4.5));
    expect(_contrast(AppColors.onError, AppColors.error), greaterThanOrEqualTo(4.5));
    expect(_contrast(AppColors.surface, AppColors.text), greaterThanOrEqualTo(4.5));
    expect(_contrast(AppColors.primary, AppColors.surface), greaterThanOrEqualTo(4.5));
  });

  test('text on tinted chips and messages meets AA', () {
    for (final tone in [
      AppColors.primary,
      AppColors.error,
      AppColors.info,
      AppColors.warningStrong,
      AppColors.textSecondary,
    ]) {
      for (final bg in backgrounds.values) {
        final tinted = _over(AppColors.tint(tone), bg);
        expect(_contrast(AppColors.text, tinted), greaterThanOrEqualTo(4.5));
        expect(
          _contrast(tone, tinted),
          greaterThanOrEqualTo(3),
          reason: 'icon $tone on its tint',
        );
      }
    }
  });

  test('the brand warning is never used for text', () {
    expect(_contrast(AppColors.warning, AppColors.background), lessThan(4.5));
    expect(_contrast(AppColors.warningStrong, AppColors.background), greaterThanOrEqualTo(4.5));
  });
}
