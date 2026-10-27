import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/async_body.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/text_fields.dart';
import '../../landlord/models/tenancy.dart';
import '../../landlord/providers/landlord_providers.dart';
import '../models/payment.dart';
import '../providers/payment_providers.dart';

final _mpesaCode = RegExp(r'^[A-Z0-9]{10}$');

String? validateMpesaCode(String? value) {
  final code = value?.trim() ?? '';
  if (code.isEmpty) return null;
  return _mpesaCode.hasMatch(code)
      ? null
      : 'An M-Pesa code has 10 letters and numbers, like QJK3XY7ZAB.';
}

class RecordPaymentScreen extends ConsumerWidget {
  const RecordPaymentScreen({super.key, this.tenancyId});

  final String? tenancyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenancies = ref.watch(currentTenanciesProvider);
    final index = ref.watch(portfolioIndexProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Record a payment')),
      body: SafeArea(
        child: AsyncBody<PortfolioIndex>(
          value: index,
          onRetry: () => ref.invalidate(portfolioIndexProvider),
          data: (idx) => AsyncBody<List<Tenancy>>(
            value: tenancies,
            onRetry: () => ref.invalidate(currentTenanciesProvider),
            data: (list) => list.isEmpty
                ? EmptyState(
                    icon: Icons.people_outline,
                    title: 'No tenants yet',
                    message:
                        'Payments are recorded against a tenant. Invite a tenant to a vacant unit first.',
                    actionLabel: 'Go to My Properties',
                    onAction: () => context.go(AppRoutes.landlordProperties),
                  )
                : _PaymentForm(tenancies: list, index: idx, initialTenancyId: tenancyId),
          ),
        ),
      ),
    );
  }
}

class _PaymentForm extends ConsumerStatefulWidget {
  const _PaymentForm({
    required this.tenancies,
    required this.index,
    required this.initialTenancyId,
  });

  final List<Tenancy> tenancies;
  final PortfolioIndex index;
  final String? initialTenancyId;

  @override
  ConsumerState<_PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends ConsumerState<_PaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _paid = TextEditingController();
  final _code = TextEditingController();
  final _notes = TextEditingController();

  late Tenancy _tenancy = widget.tenancies.firstWhere(
    (t) => t.id == widget.initialTenancyId,
    orElse: () => widget.tenancies.first,
  );
  PaymentType _type = PaymentType.rent;
  PaymentMethod _method = PaymentMethod.mpesa;
  late int _month = DateTime.now().month;
  late int _year = DateTime.now().year;
  bool _paidEdited = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _applyDefaultAmount();
  }

  @override
  void dispose() {
    for (final c in [_amount, _paid, _code, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Rent defaults to the tenant's rent, storage to their storage charge.
  void _applyDefaultAmount() {
    final amount = switch (_type) {
      PaymentType.rent => _tenancy.rentAmount,
      PaymentType.storage => _tenancy.storageAmount,
      PaymentType.deposit => _tenancy.depositAmount,
      _ => 0.0,
    };
    _amount.text = amount > 0 ? editableAmount(amount) : '';
    if (!_paidEdited) _paid.text = _amount.text;
  }

  String? _validatePaid(String? value) {
    final text = value?.trim().replaceAll(',', '') ?? '';
    if (text.isEmpty) return 'Enter how much was paid. Use 0 if nothing yet.';
    final parsed = double.tryParse(text);
    return parsed == null || parsed < 0 ? 'Enter an amount of 0 or more.' : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final orgId = ref.read(currentOrgIdProvider);
    if (orgId == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final code = _code.text.trim();
    final notes = _notes.text.trim();
    try {
      final payment = await ref.read(paymentRepositoryProvider).record(
            orgId,
            tenantId: _tenancy.id,
            unitId: _tenancy.unitId,
            buildingId: _tenancy.buildingId,
            type: _type,
            method: _method,
            amount: parseMoney(_amount.text.trim()),
            amountPaid: parseMoney(_paid.text.trim()),
            month: _month,
            year: _year,
            mpesaCode: _method == PaymentMethod.mpesa && code.isNotEmpty ? code : null,
            notes: notes.isEmpty ? null : notes,
          );
      invalidatePayments(ref);
      if (!mounted) return;
      showSuccessSnackBar(
        context,
        payment.status == PaymentStatus.completed
            ? 'Payment recorded.'
            : 'Payment recorded as ${payment.status.label.toLowerCase()}.',
      );
      context.pop();
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (_error != null) ...[
            InlineMessage(message: _error!),
            const SizedBox(height: AppSpacing.sm),
          ],
          AppDropdownField<Tenancy>(
            label: 'Tenant',
            value: _tenancy,
            options: [
              for (final t in widget.tenancies)
                DropdownOption(
                  t,
                  widget.index.unitLabel(t.unitId, buildingId: t.buildingId),
                ),
            ],
            onChanged: (t) => setState(() {
              _tenancy = t ?? _tenancy;
              _applyDefaultAmount();
            }),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppDropdownField<PaymentType>(
            label: 'What is it for?',
            value: _type,
            options: [
              for (final t in PaymentType.values) DropdownOption(t, t.label),
            ],
            onChanged: (t) => setState(() {
              _type = t ?? _type;
              _applyDefaultAmount();
            }),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppDropdownField<int>(
                  label: 'Month',
                  value: _month,
                  options: [
                    for (var m = 1; m <= 12; m++)
                      DropdownOption(m, formatMonthName(m)),
                  ],
                  onChanged: (m) => setState(() => _month = m ?? _month),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppDropdownField<int>(
                  label: 'Year',
                  value: _year,
                  options: [
                    for (final y in [now.year + 1, now.year, now.year - 1])
                      DropdownOption(y, '$y'),
                  ],
                  onChanged: (y) => setState(() => _year = y ?? _year),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          MoneyField(
            label: 'Amount due',
            controller: _amount,
            onChanged: (value) {
              if (!_paidEdited) _paid.text = value;
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          MoneyField(
            label: 'Amount paid',
            controller: _paid,
            validator: _validatePaid,
            helper: 'Less than the amount due is saved as partly paid.',
            onChanged: (_) => _paidEdited = true,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text('How was it paid?', style: AppTypography.label),
          const SizedBox(height: AppSpacing.xs),
          SegmentedButton<PaymentMethod>(
            showSelectedIcon: false,
            segments: [
              for (final m in PaymentMethod.values)
                ButtonSegment(value: m, label: Text(m.label)),
            ],
            selected: {_method},
            onSelectionChanged: (s) => setState(() => _method = s.first),
          ),
          if (_method == PaymentMethod.mpesa) ...[
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              label: 'M-Pesa code (optional)',
              controller: _code,
              hint: 'e.g. QJK3XY7ZAB',
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                LengthLimitingTextInputFormatter(10),
                _UpperCase(),
              ],
              validator: validateMpesaCode,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Notes (optional)',
            controller: _notes,
            maxLines: 3,
            textInputAction: TextInputAction.newline,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Record payment',
            isLoading: _saving,
            onPressed: _save,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'For ${formatMonthYear(_month, _year)}.',
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _UpperCase extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}
