import 'package:flutter/material.dart';

import '../errors/app_exception.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import 'buttons.dart';
import 'display.dart';

/// Explains why a space is empty, what to do next, and why it matters.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return _CenteredState(
      children: [
        IconBadge(icon: icon, size: AppSpacing.xxxl),
        const SizedBox(height: AppSpacing.md),
        Text(title, style: AppTypography.subheading, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xs),
        Text(
          message,
          style: AppTypography.bodySecondary,
          textAlign: TextAlign.center,
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(label: actionLabel!, onPressed: onAction),
        ],
      ],
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final offline = error is NoConnectionException;
    return _CenteredState(
      children: [
        IconBadge(
          icon: offline ? Icons.wifi_off : Icons.error_outline,
          color: AppColors.error,
          size: AppSpacing.xxxl,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          offline ? "You're offline" : "We couldn't load this",
          style: AppTypography.subheading,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          messageFor(error),
          style: AppTypography.bodySecondary,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        SecondaryButton(
          label: 'Try again',
          icon: Icons.refresh,
          onPressed: onRetry,
        ),
      ],
    );
  }
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.hasBoundedHeight
                ? (constraints.maxHeight - AppSpacing.lg * 2).clamp(0, double.infinity)
                : 0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// Inline feedback inside forms and screens, with an icon so tone is not
/// carried by colour alone.
class InlineMessage extends StatelessWidget {
  const InlineMessage({
    super.key,
    required this.message,
    this.tone = InlineTone.error,
  });

  final String message;
  final InlineTone tone;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (tone) {
      InlineTone.error => (Icons.error_outline, AppColors.error),
      InlineTone.info => (Icons.info_outline, AppColors.info),
      InlineTone.success => (Icons.check_circle_outline, AppColors.primary),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.tint(color),
          borderRadius: BorderRadius.circular(AppRadii.button),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: AppSizes.iconInline),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: Text(message, style: AppTypography.body)),
          ],
        ),
      ),
    );
  }
}

enum InlineTone { error, info, success }

class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.radius = AppRadii.button,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.5,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// Placeholder list shown while a list loads.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.itemCount = 4, this.itemHeight = 72});

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.sm),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, __) => SkeletonBox(
          height: itemHeight,
          radius: AppRadii.card,
        ),
      ),
    );
  }
}
