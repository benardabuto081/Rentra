import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';

enum StatusTone { neutral, success, info, warning, attention }

extension StatusToneStyle on StatusTone {
  /// Icon colour. Every value meets 3:1 against its tinted chip background.
  Color get color => switch (this) {
        StatusTone.neutral => AppColors.textSecondary,
        StatusTone.success => AppColors.primary,
        StatusTone.info => AppColors.info,
        StatusTone.warning => AppColors.warningStrong,
        StatusTone.attention => AppColors.error,
      };

  IconData get defaultIcon => switch (this) {
        StatusTone.neutral => Icons.circle_outlined,
        StatusTone.success => Icons.check_circle_outline,
        StatusTone.info => Icons.info_outline,
        StatusTone.warning => Icons.schedule,
        StatusTone.attention => Icons.error_outline,
      };
}

/// Status is always shown as icon plus text, never colour alone.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
    this.icon,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.tint(tone.color),
        borderRadius: BorderRadius.circular(AppRadii.button),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon ?? tone.defaultIcon, size: AppSizes.iconSm, color: tone.color),
          const SizedBox(width: AppSpacing.xxs),
          Flexible(
            child: Text(
              label,
              style: AppTypography.label.copyWith(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
