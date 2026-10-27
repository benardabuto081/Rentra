import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';

/// The white "R" tile shown on green brand screens.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = AppSpacing.xxxl});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(size / 4),
        ),
        child: Text(
          'R',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: size * 0.6,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}
