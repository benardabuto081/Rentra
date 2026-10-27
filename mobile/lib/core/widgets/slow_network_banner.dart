import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/network_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';

/// Shows a calm note at the top of the app while any request is slow.
class SlowNetworkBanner extends ConsumerWidget {
  const SlowNetworkBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracker = ref.watch(slowRequestTrackerProvider);
    return ListenableBuilder(
      listenable: tracker,
      child: child,
      builder: (context, child) => Stack(
        children: [
          child!,
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SafeArea(
              bottom: false,
              child: AnimatedSwitcher(
                duration: AppMotion.normal,
                child: tracker.isSlow ? const _Note() : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Semantics(
        liveRegion: true,
        child: Material(
          color: AppColors.text,
          borderRadius: BorderRadius.circular(AppRadii.button),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                const Icon(Icons.hourglass_empty, color: AppColors.surface, size: AppSizes.iconInline),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'This is taking a little longer than usual…',
                    style: AppTypography.body.copyWith(color: AppColors.surface),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
