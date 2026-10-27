import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/text_fields.dart';
import '../models/unit.dart';

class UnitInput {
  const UnitInput({
    required this.name,
    required this.type,
    required this.rentAmount,
    required this.storageAmount,
    required this.floor,
    required this.description,
  });

  final String name;
  final UnitType type;
  final double rentAmount;
  final double? storageAmount;
  final int? floor;
  final String description;
}

/// Fields for one unit, used to add and to edit.
class UnitForm extends StatefulWidget {
  const UnitForm({
    super.key,
    required this.submitLabel,
    required this.onSubmit,
    this.initial,
    this.isSubmitting = false,
    this.error,
    this.header,
  });

  final Unit? initial;
  final String submitLabel;
  final ValueChanged<UnitInput> onSubmit;
  final bool isSubmitting;
  final String? error;
  final Widget? header;

  @override
  State<UnitForm> createState() => _UnitFormState();
}

class _UnitFormState extends State<UnitForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _rent = TextEditingController(
    text: widget.initial == null ? '' : editableAmount(widget.initial!.rentAmount),
  );
  late final _storage = TextEditingController(
    text: (widget.initial?.storageAmount ?? 0) > 0
        ? editableAmount(widget.initial!.storageAmount)
        : '',
  );
  late final _floor =
      TextEditingController(text: widget.initial?.floor?.toString());
  late final _description =
      TextEditingController(text: widget.initial?.description);
  late UnitType _type = widget.initial?.type ?? UnitType.bedsitter;

  @override
  void dispose() {
    for (final c in [_name, _rent, _storage, _floor, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final storage = _storage.text.trim();
    widget.onSubmit(
      UnitInput(
        name: _name.text.trim(),
        type: _type,
        rentAmount: parseMoney(_rent.text.trim()),
        storageAmount: storage.isEmpty ? null : parseMoney(storage),
        floor: int.tryParse(_floor.text.trim()),
        description: _description.text.trim(),
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
            label: 'Unit name',
            controller: _name,
            hint: 'e.g. A1',
            textCapitalization: TextCapitalization.characters,
            validator: Validators.required('Please enter a name for the unit.'),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppDropdownField<UnitType>(
            label: 'Type',
            value: _type,
            options: [
              for (final t in UnitType.values) DropdownOption(t, t.label),
            ],
            onChanged: (t) => setState(() => _type = t ?? _type),
          ),
          const SizedBox(height: AppSpacing.sm),
          MoneyField(label: 'Monthly rent', controller: _rent),
          const SizedBox(height: AppSpacing.sm),
          MoneyField(
            label: 'Storage charge (optional)',
            controller: _storage,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? null : Validators.amount(v),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Floor (optional)',
            controller: _floor,
            hint: '0 for ground floor',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Notes (optional)',
            controller: _description,
            maxLines: 3,
            textInputAction: TextInputAction.newline,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: widget.submitLabel,
            isLoading: widget.isSubmitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
