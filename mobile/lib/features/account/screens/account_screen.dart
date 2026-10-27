import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/display.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/models/app_user.dart';
import '../../auth/providers/session_providers.dart';
import '../widgets/portfolio_section.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  static String roleLabel(UserRole role) => switch (role) {
        UserRole.landlord => 'Landlord',
        UserRole.tenant => 'Tenant',
        UserRole.caretaker => 'Caretaker',
      };

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Sign out?',
      message: 'You can sign back in at any time with your details.',
      confirmLabel: 'Sign Out',
    );
    if (confirmed) await ref.read(sessionControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();
    final contact = user.email ?? user.phone;
    final (version, build) = switch (AppConfig.appVersion.split('+')) {
      [final v, final b] => (v, b),
      [final v, ...] => (v, null),
      _ => (AppConfig.appVersion, null),
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.sm),
        children: [
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: CircleAvatar(
                    radius: AppSpacing.lg,
                    backgroundColor: AppColors.tint(AppColors.primary),
                    child: Text(
                      user.initial,
                      style: AppTypography.heading.copyWith(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName.isEmpty ? 'Your account' : user.fullName,
                        style: AppTypography.subheading,
                      ),
                      if (contact != null) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(contact, style: AppTypography.caption),
                      ],
                      const SizedBox(height: AppSpacing.xs),
                      StatusChip(
                        label: roleLabel(user.role),
                        tone: StatusTone.success,
                        icon: Icons.badge_outlined,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (user.role == UserRole.landlord) ...[
            const SizedBox(height: AppSpacing.md),
            const PortfolioSection(),
          ],
          const SizedBox(height: AppSpacing.md),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                if (user.email != null)
                  DetailRow(label: 'Email', value: user.email!),
                if (user.phone != null)
                  DetailRow(label: 'Phone', value: user.phone!),
                DetailRow(label: 'Role', value: roleLabel(user.role)),
                DetailRow(
                  label: 'App version',
                  value: build == null ? version : '$version (build $build)',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          DestructiveButton(
            label: 'Sign Out',
            icon: Icons.logout,
            onPressed: () => _signOut(context, ref),
          ),
        ],
      ),
    );
  }
}
