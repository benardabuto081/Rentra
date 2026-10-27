import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/display.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/models/app_user.dart';
import '../../auth/providers/session_providers.dart';
import '../models/payment.dart';
import '../providers/payment_providers.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final orgId = user?.organizationId;
    final managesProperty =
        user != null && user.role != UserRole.tenant && user.hasOrganization;

    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: managesProperty
          ? _OrganizationPayments(orgId: orgId!)
          : const EmptyState(
              icon: Icons.payments_outlined,
              title: 'Payments will appear here',
              message:
                  'Your account is not linked to a property portfolio yet, so there are no payments to show.',
            ),
    );
  }
}

class _OrganizationPayments extends ConsumerWidget {
  const _OrganizationPayments({required this.orgId});

  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(paymentHistoryProvider(orgId));
    final arrears = ref.watch(paymentArrearsProvider(orgId));
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: _tabLabel('Payment History', history)),
              Tab(text: _tabLabel('Outstanding', arrears)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _PaymentList(
                  payments: history,
                  onRefresh: () => ref.refresh(paymentHistoryProvider(orgId).future),
                  emptyTitle: 'No payments recorded yet',
                  emptyMessage:
                      'Payments you record will appear here, so you always know who has paid.',
                ),
                _PaymentList(
                  payments: arrears,
                  onRefresh: () => ref.refresh(paymentArrearsProvider(orgId).future),
                  emptyTitle: 'Nothing outstanding',
                  emptyMessage:
                      'Unpaid and partly paid rent will show here so you can follow up calmly.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _tabLabel(String label, AsyncValue<List<Payment>> value) =>
      value.hasValue ? '$label (${value.value!.length})' : label;
}

class _PaymentList extends StatelessWidget {
  const _PaymentList({
    required this.payments,
    required this.onRefresh,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  final AsyncValue<List<Payment>> payments;
  final Future<void> Function() onRefresh;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return switch (payments) {
      AsyncData(:final value) when value.isEmpty => RefreshIndicator(
          onRefresh: onRefresh,
          child: EmptyState(
            icon: Icons.payments_outlined,
            title: emptyTitle,
            message: emptyMessage,
          ),
        ),
      AsyncData(:final value) => RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.sm),
            itemCount: value.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) => _PaymentCard(payment: value[i]),
          ),
        ),
      AsyncError(:final error) => ErrorState(error: error, onRetry: onRefresh),
      _ => const SkeletonList(),
    };
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final tone = switch (payment.status) {
      PaymentStatus.completed => StatusTone.success,
      PaymentStatus.partial => StatusTone.warning,
      PaymentStatus.pending => StatusTone.neutral,
      PaymentStatus.failed => StatusTone.attention,
    };
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${payment.type.label} · ${formatShortMonthYear(payment.month, payment.year)}',
                  style: AppTypography.label,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(payment.method.label, style: AppTypography.caption),
                const SizedBox(height: AppSpacing.xs),
                StatusChip(label: payment.status.label, tone: tone),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MoneyText(payment.amountPaid),
              Text(
                'of ${formatMoney(payment.amount)}',
                style: AppTypography.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
