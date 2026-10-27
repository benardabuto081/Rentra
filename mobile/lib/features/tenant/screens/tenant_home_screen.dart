import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/display.dart';
import '../../../core/widgets/greeting_header.dart';
import '../../../core/widgets/states.dart';
import '../../auth/models/app_user.dart';
import '../../auth/providers/session_providers.dart';
import '../models/rent_schedule.dart';
import '../models/shadow_rental.dart';
import '../providers/tenant_providers.dart';
import '../widgets/rental_labels.dart';

class TenantHomeScreen extends ConsumerWidget {
  const TenantHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();
    final header = GreetingHeader(
      firstName: user.firstName,
      initial: user.initial,
      subtitle: 'Your home',
    );
    return Scaffold(
      body: SafeArea(
        child: user.hasOrganization
            ? ListView(children: [header, const _ConnectedCard()])
            : _IndependentHome(user: user, header: header),
      ),
    );
  }
}

/// Managed tenants: the backend has no tenant-scoped endpoints yet.
class _ConnectedCard extends StatelessWidget {
  const _ConnectedCard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.sm),
      child: AppCard(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBadge(icon: Icons.link),
            SizedBox(height: AppSpacing.sm),
            Text(
              "You're connected to your landlord's property.",
              style: AppTypography.subheading,
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              'Your rent and request details are on their way.',
              style: AppTypography.bodySecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _IndependentHome extends ConsumerWidget {
  const _IndependentHome({required this.user, required this.header});

  final AppUser user;
  final Widget header;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rental = ref.watch(activeShadowRentalProvider);
    Future<void> refresh() => ref.refresh(activeShadowRentalProvider.future);

    return RefreshIndicator(
      onRefresh: refresh,
      child: switch (rental) {
        AsyncData(value: final r?) => ListView(
            children: [
              header,
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: _RentalCard(rental: r),
              ),
            ],
          ),
        AsyncData() => ListView(
            children: [
              header,
              EmptyState(
                icon: Icons.home_outlined,
                title: 'Add your rental',
                message:
                    'Record your rent and how you pay it. Rentra will show when rent is next due and keep your payment details in one place.',
                actionLabel: 'Set up my rental',
                onAction: () => context.push(AppRoutes.rentalSetup),
              ),
            ],
          ),
        AsyncError(:final error) => ListView(
            children: [header, ErrorState(error: error, onRetry: refresh)],
          ),
        _ => ListView(
            physics: const NeverScrollableScrollPhysics(),
            children: [
              header,
              const Padding(
                padding: EdgeInsets.all(AppSpacing.sm),
                child: SkeletonBox(
                  height: AppSpacing.xxxl * 3,
                  radius: AppRadii.card,
                ),
              ),
            ],
          ),
      },
    );
  }
}

class _RentalCard extends StatelessWidget {
  const _RentalCard({required this.rental});

  final ShadowRental rental;

  @override
  Widget build(BuildContext context) {
    final due = nextRentDue(rental, DateTime.now());
    final address = rental.displayAddress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rental.displayName, style: AppTypography.subheading),
              if (address != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(address, style: AppTypography.caption),
              ],
              const SizedBox(height: AppSpacing.md),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: AppSpacing.xs,
                children: [
                  MoneyText(rental.rentAmount, style: AppTypography.display),
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                    child: Text(
                      perCycle(rental.billingCycle),
                      style: AppTypography.bodySecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.event_outlined, size: AppSizes.iconInline),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      dueSentence(rental, due),
                      style: AppTypography.body,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        PrimaryButton(
          label: 'How to pay',
          icon: Icons.payments_outlined,
          onPressed: () => context.go(AppRoutes.payments),
        ),
        const SizedBox(height: AppSpacing.xs),
        Center(
          child: AppTextButton(
            label: 'Edit rental details',
            onPressed: () => context.push(AppRoutes.rentalEdit),
          ),
        ),
      ],
    );
  }
}
