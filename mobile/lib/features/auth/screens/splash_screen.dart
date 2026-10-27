import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../widgets/brand_mark.dart';

/// Shown while the saved session is restored. The router moves on.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandMark(size: AppSpacing.xxxl + AppSpacing.md),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Rentra',
                style: AppTypography.display.copyWith(color: AppColors.onPrimary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Your rental identity, organized.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: AppColors.onPrimary),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Semantics(
                label: 'Loading Rentra',
                child: const SizedBox.square(
                  dimension: AppSizes.iconMd,
                  child: CircularProgressIndicator(
                    color: AppColors.onPrimary,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
