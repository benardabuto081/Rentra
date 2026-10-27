import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_body.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/display.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/sheets.dart';
import '../../../core/widgets/states.dart';
import '../../payments/models/payment.dart';
import '../../payments/providers/payment_providers.dart';
import '../models/tenancy.dart';
import '../providers/landlord_providers.dart';
import '../widgets/status_labels.dart';

class TenancyDetailScreen extends ConsumerWidget {
  const TenancyDetailScreen({super.key, required this.tenancyId});

  final String tenancyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenancy = ref.watch(tenancyProvider(tenancyId));
    final index = ref.watch(portfolioIndexProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Tenant')),
      body: AsyncBody<Tenancy>(
        value: tenancy,
        onRetry: () => ref.invalidate(tenancyProvider(tenancyId)),
        data: (t) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(tenantPaymentsProvider(tenancyId));
            ref.invalidate(tenancyProvider(tenancyId));
            await ref.read(tenancyProvider(tenancyId).future);
          },
          child: _Body(
            tenancy: t,
            unitLabel:
                index?.unitLabel(t.unitId, buildingId: t.buildingId) ?? 'Unit',
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.tenancy, required this.unitLabel});

  final Tenancy tenancy;
  final String unitLabel;

  Future<void> _updateRent(BuildContext context, WidgetRef ref) async {
    double? saved;
    final done = await showAmountSheet(
      context: context,
      title: 'Update rent',
      message: 'The new amount is used for payments you record from now on.',
      label: 'Monthly rent',
      initial: tenancy.rentAmount,
      submitLabel: 'Save rent',
      onSubmit: (amount) async {
        await ref
            .read(tenancyRepositoryProvider)
            .update(tenancy.organizationId, tenancy.id, rentAmount: amount);
        saved = amount;
      },
    );
    if (!done || !context.mounted) return;
    invalidatePortfolio(ref);
    showSuccessSnackBar(context, 'Rent updated to ${formatMoney(saved!)}.');
  }

  Future<void> _giveNotice(BuildContext context, WidgetRef ref) async {
    final done = await showDateSheet(
      context: context,
      title: 'Record notice',
      message: 'Use the date the tenant told you they are leaving.',
      label: 'Notice given on',
      submitLabel: 'Record notice',
      onSubmit: (date) => ref
          .read(tenancyRepositoryProvider)
          .giveNotice(tenancy.organizationId, tenancy.id, date),
    );
    if (!done || !context.mounted) return;
    invalidatePortfolio(ref);
    showSuccessSnackBar(context, 'Notice recorded.');
  }

  Future<void> _moveOut(BuildContext context, WidgetRef ref) async {
    final done = await showDateSheet(
      context: context,
      title: 'Move this tenant out?',
      message:
          '$unitLabel will become vacant so you can invite someone new. Their payment records are kept.',
      label: 'Move-out date',
      submitLabel: 'Move out',
      destructive: true,
      onSubmit: (date) => ref
          .read(tenancyRepositoryProvider)
          .vacate(tenancy.organizationId, tenancy.id, date),
    );
    if (!done || !context.mounted) return;
    invalidatePortfolio(ref);
    showSuccessSnackBar(context, 'Tenant moved out. $unitLabel is now vacant.');
    context.go(AppRoutes.landlordTenants);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = tenancy;
    final live = t.status != TenancyStatus.vacated;
    final payments = ref.watch(tenantPaymentsProvider(t.id));
    final history = payments.value ?? const <Payment>[];
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
            0,
          ),
          sliver: SliverList.list(
            children: [
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Text(unitLabel,
                                style: AppTypography.subheading)),
                        chipFor(tenancyStatus(t.status)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DetailRow(
                        label: 'Monthly rent',
                        value: formatMoney(t.rentAmount)),
                    if (t.storageAmount > 0)
                      DetailRow(
                          label: 'Storage charge',
                          value: formatMoney(t.storageAmount)),
                    if (t.depositAmount > 0)
                      DetailRow(
                          label: 'Deposit',
                          value: formatMoney(t.depositAmount)),
                    DetailRow(
                        label: 'Moved in', value: formatDate(t.moveInDate)),
                    if (t.noticeDate != null)
                      DetailRow(
                          label: 'Notice given',
                          value: formatDate(t.noticeDate!)),
                    if (t.moveOutDate != null)
                      DetailRow(
                          label: 'Moved out',
                          value: formatDate(t.moveOutDate!)),
                  ],
                ),
              ),
              if (live) ...[
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: 'Record a payment',
                  icon: Icons.add,
                  onPressed: () =>
                      context.push(AppRoutes.recordPayment(tenancyId: t.id)),
                ),
                const SizedBox(height: AppSpacing.xs),
                SecondaryButton(
                    label: 'Update rent',
                    onPressed: () => _updateRent(context, ref)),
                if (t.status == TenancyStatus.active) ...[
                  const SizedBox(height: AppSpacing.xs),
                  SecondaryButton(
                      label: 'Record notice',
                      onPressed: () => _giveNotice(context, ref)),
                ],
                const SizedBox(height: AppSpacing.xs),
                DestructiveButton(
                    label: 'Move out', onPressed: () => _moveOut(context, ref)),
              ],
              const SizedBox(height: AppSpacing.md),
              const SectionHeader(title: 'Payment History'),
              if (!payments.hasValue)
                AsyncBody<List<Payment>>(
                  value: payments,
                  onRetry: () => ref.invalidate(tenantPaymentsProvider(t.id)),
                  loading: const SkeletonBox(
                    height: AppSpacing.xxxl + AppSpacing.xs,
                    radius: AppRadii.card,
                  ),
                  data: (_) => const SizedBox.shrink(),
                )
              else if (history.isEmpty)
                const Text(
                  'No payments recorded for this tenant yet. Record one when rent comes in, so you always know where things stand.',
                  style: AppTypography.bodySecondary,
                ),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          sliver: SliverList.builder(
            itemCount: history.length,
            itemBuilder: (context, i) {
              final p = history[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: ListCard(
                  title:
                      '${p.type.label} · ${formatShortMonthYear(p.month, p.year)}',
                  subtitle:
                      '${formatMoney(p.amountPaid)} of ${formatMoney(p.amount)}',
                  trailing: chipFor(paymentStatus(p.status)),
                  onTap: () => context.go(AppRoutes.payment(p.id)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
