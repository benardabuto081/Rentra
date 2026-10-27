import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import '../../landlord/providers/landlord_providers.dart';
import '../../landlord/widgets/status_labels.dart';
import '../models/payment.dart';
import '../providers/payment_providers.dart';

class PaymentDetailScreen extends ConsumerWidget {
  const PaymentDetailScreen({super.key, required this.paymentId});

  final String paymentId;

  Future<void> _updatePaid(BuildContext context, WidgetRef ref, Payment p) async {
    Payment? updated;
    final done = await showAmountSheet(
      context: context,
      title: 'Update amount paid',
      message:
          'Enter the total paid so far for this ${p.type.label.toLowerCase()}, out of ${formatMoney(p.amount)}.',
      label: 'Total paid',
      initial: p.amount,
      submitLabel: 'Save',
      onSubmit: (amount) async {
        updated = await ref
            .read(paymentRepositoryProvider)
            .update(p.organizationId, p.id, amountPaid: amount);
      },
    );
    if (!done || !context.mounted) return;
    invalidatePayments(ref);
    showSuccessSnackBar(
      context,
      updated?.status == PaymentStatus.completed
          ? 'Payment updated. It is now fully paid.'
          : 'Payment updated.',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payment = ref.watch(paymentProvider(paymentId));
    final index = ref.watch(portfolioIndexProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: AsyncBody<Payment>(
        value: payment,
        onRetry: () => ref.invalidate(paymentProvider(paymentId)),
        data: (p) => ListView(
          padding: const EdgeInsets.all(AppSpacing.sm),
          children: [
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          index?.unitLabel(p.unitId, buildingId: p.buildingId) ?? 'Unit',
                          style: AppTypography.subheading,
                        ),
                      ),
                      chipFor(paymentStatus(p.status)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DetailRow(label: 'For', value: '${p.type.label} · ${formatMonthYear(p.month, p.year)}'),
                  DetailRow(label: 'Amount due', value: formatMoney(p.amount)),
                  DetailRow(label: 'Paid', value: formatMoney(p.amountPaid)),
                  DetailRow(label: 'Method', value: p.method.label),
                  if (p.mpesaCode?.isNotEmpty == true)
                    DetailRow(label: 'M-Pesa code', value: p.mpesaCode!),
                  if (p.receiptNumber != null)
                    DetailRow(label: 'Receipt', value: p.receiptNumber!),
                  if (p.paidAt != null)
                    DetailRow(label: 'Last paid', value: formatDate(p.paidAt!.toLocal())),
                  if (p.notes?.trim().isNotEmpty == true)
                    DetailRow(label: 'Notes', value: p.notes!.trim()),
                ],
              ),
            ),
            if (p.status != PaymentStatus.completed) ...[
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: 'Update amount paid',
                onPressed: () => _updatePaid(context, ref, p),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
