import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/text_fields.dart';
import '../models/rent_schedule.dart';
import '../models/shadow_rental.dart';
import 'rental_labels.dart';

/// What the form collects. Optional text left blank is an empty string so an
/// edit can clear it.
class ShadowRentalInput {
  const ShadowRentalInput({
    required this.nickname,
    required this.address,
    required this.rentAmount,
    required this.billingCycle,
    required this.dueDayOfMonth,
    required this.destinationType,
    required this.destinationNumber,
    required this.referenceName,
  });

  final String nickname;
  final String address;
  final double rentAmount;
  final BillingCycle billingCycle;
  final int? dueDayOfMonth;
  final PaymentDestinationType destinationType;
  final String destinationNumber;
  final String referenceName;
}

class ShadowRentalForm extends StatefulWidget {
  const ShadowRentalForm({
    super.key,
    required this.submitLabel,
    required this.onSubmit,
    this.initial,
    this.isSubmitting = false,
    this.error,
    this.header,
    this.footer,
  });

  final ShadowRental? initial;
  final String submitLabel;
  final ValueChanged<ShadowRentalInput> onSubmit;
  final bool isSubmitting;
  final String? error;
  final Widget? header;
  final Widget? footer;

  @override
  State<ShadowRentalForm> createState() => _ShadowRentalFormState();
}

class _ShadowRentalFormState extends State<ShadowRentalForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nickname;
  late final TextEditingController _address;
  late final TextEditingController _rent;
  late final TextEditingController _number;
  late final TextEditingController _reference;
  late BillingCycle _cycle;
  late int _dueDay;
  late PaymentDestinationType _destination;

  @override
  void initState() {
    super.initState();
    final r = widget.initial;
    _nickname = TextEditingController(text: r?.nickname ?? '');
    _address = TextEditingController(text: r?.displayAddress ?? '');
    _rent = TextEditingController(text: r == null ? '' : _editableAmount(r.rentAmount));
    _number = TextEditingController(text: r?.destinationNumber ?? '');
    _reference = TextEditingController(text: r?.displayReference ?? '');
    _cycle = r?.billingCycle ?? BillingCycle.monthly;
    final today = DateTime.now().day;
    _dueDay = (r?.dueDayOfMonth ?? today).clamp(1, 28);
    _destination = r?.destinationType ?? PaymentDestinationType.paybill;
  }

  static String _editableAmount(double amount) =>
      amount == amount.truncateToDouble()
          ? amount.toStringAsFixed(0)
          : amount.toStringAsFixed(2);

  @override
  void dispose() {
    for (final c in [_nickname, _address, _rent, _number, _reference]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(
      ShadowRentalInput(
        nickname: _nickname.text.trim(),
        address: _address.text.trim(),
        rentAmount: parseMoney(_rent.text.trim()),
        billingCycle: _cycle,
        dueDayOfMonth: _cycle == BillingCycle.monthly ? _dueDay : null,
        destinationType: _destination,
        destinationNumber: _number.text.trim(),
        referenceName: _reference.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (widget.header != null) ...[
            widget.header!,
            const SizedBox(height: AppSpacing.md),
          ],
          if (widget.error != null) ...[
            InlineMessage(message: widget.error!),
            const SizedBox(height: AppSpacing.sm),
          ],
          AppTextField(
            label: 'Property Name',
            controller: _nickname,
            hint: 'e.g. My Bedsitter in Kasarani',
            textCapitalization: TextCapitalization.sentences,
            validator: Validators.required('Please enter a property name.'),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Address (optional)',
            controller: _address,
            hint: 'e.g. Kasarani, Nairobi',
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Rent amount',
            controller: _rent,
            hint: 'e.g. 7000',
            prefixText: 'KES ',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            validator: Validators.amount,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text('How often do you pay?', style: AppTypography.label),
          const SizedBox(height: AppSpacing.xs),
          SegmentedButton<BillingCycle>(
            showSelectedIcon: false,
            segments: [
              for (final cycle in BillingCycle.values)
                ButtonSegment(value: cycle, label: Text(cycle.label)),
            ],
            selected: {_cycle},
            onSelectionChanged: (s) => setState(() => _cycle = s.first),
          ),
          if (_cycle == BillingCycle.monthly) ...[
            const SizedBox(height: AppSpacing.sm),
            AppDropdownField<int>(
              label: 'Rent Due Day',
              value: _dueDay,
              options: [
                for (var d = 1; d <= 28; d++)
                  DropdownOption(d, 'The ${ordinal(d)} of every month'),
              ],
              onChanged: (v) => setState(() => _dueDay = v ?? _dueDay),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          const Text('How do you pay rent?', style: AppTypography.label),
          const SizedBox(height: AppSpacing.xs),
          SegmentedButton<PaymentDestinationType>(
            showSelectedIcon: false,
            segments: [
              for (final type in PaymentDestinationType.values)
                ButtonSegment(value: type, label: Text(type.label)),
            ],
            selected: {_destination},
            onSelectionChanged: (s) => setState(() => _destination = s.first),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: destinationNumberLabel(_destination),
            controller: _number,
            hint: _destination == PaymentDestinationType.paybill
                ? 'e.g. 522522'
                : 'e.g. 0123456',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: Validators.required('Please enter the payment number.'),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Reference (optional)',
            controller: _reference,
            hint: 'e.g. your phone number',
            helper: 'What you type in the account or reference box when you pay.',
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: widget.submitLabel,
            isLoading: widget.isSubmitting,
            onPressed: _submit,
          ),
          if (widget.footer != null) ...[
            const SizedBox(height: AppSpacing.lg),
            widget.footer!,
          ],
        ],
      ),
    );
  }
}
