import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/states.dart';
import '../providers/session_providers.dart';
import '../widgets/brand_mark.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notice = ref.watch(sessionNoticeProvider);
    final onPrimary = AppTypography.body.copyWith(color: AppColors.onPrimary);

    void open(String route) {
      ref.read(sessionNoticeProvider.notifier).clear();
      context.push(route);
    }

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xxl),
                    const BrandMark(),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Rentra',
                      style: AppTypography.display.copyWith(
                        color: AppColors.onPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Your rental identity,\norganized.',
                      style: AppTypography.heading.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (notice != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadii.button),
                        ),
                        child: InlineMessage(
                          message: notice,
                          tone: InlineTone.info,
                        ),
                      ),
                    ],
                    const Spacer(),
                    const SizedBox(height: AppSpacing.lg),
                    _Feature(
                      icon: Icons.verified_user_outlined,
                      text: 'One identity for all your rentals',
                      style: onPrimary,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _Feature(
                      icon: Icons.payments_outlined,
                      text: 'Track payments and build history',
                      style: onPrimary,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _Feature(
                      icon: Icons.people_outline,
                      text: 'Connect with households',
                      style: onPrimary,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    SizedBox(
                      width: double.infinity,
                      child: PressScale(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.surface,
                            foregroundColor: AppColors.primary,
                          ),
                          onPressed: () => open(AppRoutes.createAccount),
                          child: const Text('Create Account'),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: PressScale(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.onPrimary,
                            side: const BorderSide(color: AppColors.onPrimary),
                          ),
                          onPressed: () => open(AppRoutes.login),
                          child: const Text('Sign In'),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.text, required this.style});

  final IconData icon;
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.onPrimary, size: AppSizes.iconInline),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: style)),
      ],
    );
  }
}
