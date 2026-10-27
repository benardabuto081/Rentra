import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/models/app_user.dart';
import '../../auth/providers/session_providers.dart';
import '../../landlord/widgets/landlord_home_body.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();
    final managesProperty = user.role != UserRole.tenant && user.hasOrganization;
    return Scaffold(
      body: SafeArea(
        child: managesProperty
            ? LandlordHomeBody(
                organizationId: user.organizationId!,
                header: _Greeting(user: user, subtitle: 'Property Dashboard'),
              )
            : ListView(
                children: [
                  _Greeting(user: user, subtitle: 'Tenant Dashboard'),
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    child: _WelcomeCard(),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.user, required this.subtitle});

  final AppUser user;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final name = user.firstName?.trim();
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
                    '$greeting, ${name == null || name.isEmpty ? 'there' : name}',
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
                user.initial,
                style: AppTypography.subheading.copyWith(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    const onPrimary = AppColors.onPrimary;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Rental', style: AppTypography.caption.copyWith(color: onPrimary)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Welcome to Rentra',
            style: AppTypography.subheading.copyWith(color: onPrimary),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Track your payments and build your rental history.',
            style: AppTypography.body.copyWith(color: onPrimary),
          ),
        ],
      ),
    );
  }
}
