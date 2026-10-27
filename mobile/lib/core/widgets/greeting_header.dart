import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';

class GreetingHeader extends StatelessWidget {
  const GreetingHeader({
    super.key,
    required this.firstName,
    required this.initial,
    required this.subtitle,
  });

  final String? firstName;
  final String initial;
  final String subtitle;

  static String greetingFor(DateTime now) => now.hour < 12
      ? 'Good morning'
      : now.hour < 17
          ? 'Good afternoon'
          : 'Good evening';

  @override
  Widget build(BuildContext context) {
    final name = firstName?.trim();
    final who = name == null || name.isEmpty ? 'there' : name;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    '${greetingFor(DateTime.now())}, $who',
                    style: AppTypography.heading,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ),
          ExcludeSemantics(
            child: CircleAvatar(
              radius: AppSpacing.md,
              backgroundColor: AppColors.tint(AppColors.primary),
              child: Text(
                initial,
                style: AppTypography.subheading.copyWith(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
