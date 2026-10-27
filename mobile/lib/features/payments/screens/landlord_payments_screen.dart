import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/text.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_body.dart';
import '../../../core/widgets/display.dart';
import '../../../core/widgets/states.dart';
import '../../landlord/providers/landlord_providers.dart';
import '../../landlord/widgets/status_labels.dart';
import '../models/payment.dart';
import '../providers/payment_providers.dart';

class LandlordPaymentsScreen extends ConsumerStatefulWidget {
  const LandlordPaymentsScreen({super.key});

  @override
  ConsumerState<LandlordPaymentsScreen> createState() =>
      _LandlordPaymentsScreenState();
}

class _LandlordPaymentsScreenState extends ConsumerState<LandlordPaymentsScreen> {
  late MonthKey _month = _current;

  static MonthKey get _current {
    final now = DateTime.now();
    return (month: now.month, year: now.year);
  }

  bool get _isCurrent => _month == _current;

  void _shift(int delta) {
    final d = DateTime(_month.year, _month.month + delta);
    setState(() => _month = (month: d.month, year: d.year));
  }

  @override
  Widget build(BuildContext context) {
    final arrears = ref.watch(arrearsProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Payments'),
          bottom: TabBar(
            tabs: [
              const Tab(text: 'By month'),
              Tab(
                text: arrears.hasValue
                    ? 'Outstanding (${arrears.value!.length})'
                    : 'Outstanding',
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push(AppRoutes.recordPayment()),
          icon: const Icon(Icons.add),
          label: const Text('Record payment'),
        ),
        body: TabBarView(
          children: [
            Column(
              children: [
                _MonthSelector(
                  month: _month,
                  onPrevious: () => _shift(-1),
                  onNext: _isCurrent ? null : () => _shift(1),
                ),
                Expanded(child: _MonthTab(month: _month)),
              ],
            ),
            _OutstandingTab(arrears: arrears),
          ],
        ),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final MonthKey month;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous month',
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
          ),
          Expanded(
            child: Text(
              formatMonthYear(month.month, month.year),
              style: AppTypography.subheading,
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            tooltip: 'Next month',
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _MonthTab extends ConsumerWidget {
  const _MonthTab({required this.month});

  final MonthKey month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(monthPaymentsProvider(month));
    final stats = ref.watch(monthStatsProvider(month)).value;
    final index = ref.watch(portfolioIndexProvider).value;
    Future<void> refresh() async {
      ref.invalidate(monthStatsProvider(month));
      ref.invalidate(monthPaymentsProvider(month));
      await ref.read(monthPaymentsProvider(month).future);
    }

    return AsyncBody<List<Payment>>(
      value: payments,
      onRetry: refresh,
      data: (list) => RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            0,
            AppSpacing.sm,
            AppSpacing.xxxl + AppSpacing.md,
          ),
          children: [
            if (stats != null)
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    DetailRow(label: 'Expected', value: formatMoney(stats.expected)),
                    DetailRow(label: 'Collected', value: formatMoney(stats.collected)),
                    DetailRow(label: 'Still to collect', value: formatMoney(stats.outstanding)),
                    DetailRow(label: 'Payments recorded', value: '${stats.count}'),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            if (list.isEmpty)
              const EmptyState(
                icon: Icons.payments_outlined,
                title: 'No payments for this month',
                message:
                    'Record rent as it comes in. Your totals and outstanding balances update straight away.',
              )
            else
              for (final p in list) ...[
                PaymentCard(payment: p, unitLabel: index?.unitLabel(p.unitId, buildingId: p.buildingId)),
                const SizedBox(height: AppSpacing.xs),
              ],
          ],
        ),
      ),
    );
  }
}

class _OutstandingTab extends ConsumerWidget {
  const _OutstandingTab({required this.arrears});

  final AsyncValue<List<Payment>> arrears;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(portfolioIndexProvider).value;
    Future<void> refresh() => ref.refresh(arrearsProvider.future);
    return AsyncBody<List<Payment>>(
      value: arrears,
      onRetry: refresh,
      data: (list) => list.isEmpty
          ? const EmptyState(
              icon: Icons.check_circle_outline,
              title: 'Nothing outstanding',
              message:
                  'Every recorded payment is fully paid. Unpaid and part-paid rent will show here so you can follow up calmly.',
            )
          : RefreshIndicator(
              onRefresh: refresh,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.xxxl + AppSpacing.md,
                ),
                itemCount: list.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
                itemBuilder: (_, i) => i == 0
                    ? Text(
                        '${plural(list.length, 'payment')} not fully paid, oldest first.',
                        style: AppTypography.bodySecondary,
                      )
                    : PaymentCard(
                        payment: list[i - 1],
                        unitLabel: index?.unitLabel(
                          list[i - 1].unitId,
                          buildingId: list[i - 1].buildingId,
                        ),
                      ),
              ),
            ),
    );
  }
}

class PaymentCard extends StatelessWidget {
  const PaymentCard({super.key, required this.payment, this.unitLabel});

  final Payment payment;
  final String? unitLabel;

  @override
  Widget build(BuildContext context) {
    final p = payment;
    return ListCard(
      title: unitLabel ?? 'Unit',
      subtitle:
          '${p.type.label} · ${formatShortMonthYear(p.month, p.year)} · ${p.method.label}\n'
          'Paid ${formatMoney(p.amountPaid)} of ${formatMoney(p.amount)}',
      trailing: chipFor(paymentStatus(p.status)),
      onTap: () => context.go(AppRoutes.payment(p.id)),
    );
  }
}
