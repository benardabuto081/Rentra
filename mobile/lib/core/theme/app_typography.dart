import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Fixed type scale on the platform font. Hierarchy comes from size and weight.
class AppTypography {
  const AppTypography._();

  static const display = TextStyle(
    fontSize: 32,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  static const heading = TextStyle(
    fontSize: 24,
    height: 1.25,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  static const subheading = TextStyle(
    fontSize: 18,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  static const body = TextStyle(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
  );

  static const bodySecondary = TextStyle(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const caption = TextStyle(
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const label = TextStyle(
    fontSize: 14,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  static TextTheme get textTheme => TextTheme(
        displaySmall: display,
        headlineSmall: heading,
        titleLarge: subheading,
        titleMedium: subheading.copyWith(fontSize: 16),
        bodyLarge: body,
        bodyMedium: body.copyWith(fontSize: 14),
        bodySmall: caption,
        labelLarge: label,
        labelMedium: label.copyWith(fontSize: 12),
      );
}
