import 'package:flutter/material.dart';

/// Contrast ratios (WCAG 2.1) are enforced by `test/core/theme/contrast_test.dart`.
class AppColors {
  const AppColors._();

  static const primary = Color(0xFF12805C);
  static const onPrimary = Color(0xFFFFFFFF);
  static const text = Color(0xFF1F2933);
  static const textSecondary = Color(0xFF5F6B76);
  static const background = Color(0xFFFAF8F5);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE7E2DA);
  static const info = Color(0xFF2563EB);
  static const success = primary;
  static const error = Color(0xFFC62828);
  static const onError = Color(0xFFFFFFFF);
  static const disabled = Color(0xFF9AA5AF);

  /// Brand warning. Below 4.5:1 on light backgrounds, so only for fills.
  static const warning = Color(0xFFD97706);

  /// [warning] darkened to the nearest shade that passes AA on [background].
  static const warningStrong = Color(0xFFAB5E05);

  static const shadow = Color(0x0F1F2933);

  static Color tint(Color color) => color.withValues(alpha: 0.10);
}
