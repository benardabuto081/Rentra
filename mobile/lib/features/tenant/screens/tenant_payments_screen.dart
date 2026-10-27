import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/copy_row.dart';
import '../../../core/widgets/display.dart';
import '../../../core/widgets/states.dart';
import '../../auth/providers/session_providers.dart';
import '../models/rent_schedule.dart';
import '../models/shadow_rental.dart';
import '../providers/tenant_providers.dart';
import '../widgets/rental_labels.dart';

class TenantPaymentsScreen extends ConsumerWidget {
  const TenantPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: user.hasOrganization
          ? const EmptyState(
              icon: Icons.payments_outlined,
              title: 'Your rent details are on their way',
              message:
                  "Once your landlord's payment details are available in Rentra, you'll see how and when to pay here.",
            )
          : const _IndependentPayments(),
    );
  }
}

class _IndependentPayments extends ConsumerWidget {
  const _IndependentPayments();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rental = ref.watch(activeShadowRentalProvider);
    Future<void> refresh() => ref.refresh(activeShadowRentalProvider.future);

    return switch (rental) {
      AsyncData(value: final r?) => RefreshIndicator(
          onRefresh: refresh,
          child: _Details(rental: r),
        ),
      AsyncData() => EmptyState(
          icon: Icons.payments_outlined,
          title: 'No payment details yet',
          message:
              'Add your rental and how you pay it, and your paybill, till or bank details will always be one tap away.',
          actionLabel: 'Set up my rental',
          onAction: () => context.push(AppRoutes.rentalSetup),
        ),
      AsyncError(:final error) => ErrorState(error: error, onRetry: refresh),
      _ => const SkeletonList(itemCount: 3, itemHeight: AppSpacing.xxxl * 2),
    };
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.rental});

  final ShadowRental rental;

  @override
  Widget build(BuildContext context) {
    final due = nextRentDue(rental, DateTime.now());
    final reference = rental.displayReference;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.sm),
      children: [
        const SectionHeader(title: 'How to pay'),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconBadge(icon: destinationIcon(rental.destinationType)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      destinationMethodLabel(rental.destinationType),
                      style: AppTypography.subheading,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              CopyRow(
                label: destinationNumberLabel(rental.destinationType),
                value: rental.destinationNumber,
              ),
              if (reference != null)
                CopyRow(label: 'Reference', value: reference),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  const Text('Amount', style: AppTypography.bodySecondary),
                  const Spacer(),
                  MoneyText(rental.rentAmount),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const SectionHeader(title: 'Billing schedule'),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              DetailRow(label: 'How often', value: rental.billingCycle.label),
              DetailRow(label: 'Due', value: scheduleSentence(rental)),
              if (due != null)
                DetailRow(label: 'Next due date', value: formatDate(due.date)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const SectionHeader(title: 'Payment History'),
        const AppCard(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBadge(icon: Icons.receipt_long_outlined),
              SizedBox(height: AppSpacing.sm),
              Text(
                "Payment tracking isn't available yet",
                style: AppTypography.subheading,
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                'For now, keep your M-Pesa or bank messages as proof. When tracking arrives, each payment you make will be recorded here, building a rental history you can show a future landlord.',
                style: AppTypography.bodySecondary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
