import 'package:flutter/material.dart';

import '../errors/app_exception.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import '../utils/money.dart';
import 'buttons.dart';
import 'feedback.dart';
import 'states.dart';
import 'text_fields.dart';

/// Every sheet below returns true once [onSubmit] succeeds. Failures stay in
/// the sheet as a human message so the person can fix and retry.
Future<bool> showAmountSheet({
  required BuildContext context,
  required String title,
  required String label,
  required String submitLabel,
  required Future<void> Function(double amount) onSubmit,
  String? message,
  double? initial,
}) =>
    _show(
      context,
      _AmountSheet(
        title: title,
        message: message,
        label: label,
        submitLabel: submitLabel,
        initial: initial,
        onSubmit: onSubmit,
      ),
    );

Future<bool> showDateSheet({
  required BuildContext context,
  required String title,
  required String label,
  required String submitLabel,
  required Future<void> Function(DateTime date) onSubmit,
  String? message,
  bool destructive = false,
}) =>
    _show(
      context,
      _DateSheet(
        title: title,
        message: message,
        label: label,
        submitLabel: submitLabel,
        destructive: destructive,
        onSubmit: onSubmit,
      ),
    );

Future<bool> showTextSheet({
  required BuildContext context,
  required String title,
  required String label,
  required String submitLabel,
  required Future<void> Function(String text) onSubmit,
  String? message,
  String? hint,
  String? initial,
  String requiredMessage = 'Please fill this in.',
}) =>
    _show(
      context,
      _TextSheet(
        title: title,
        message: message,
        label: label,
        hint: hint,
        initial: initial,
        requiredMessage: requiredMessage,
        submitLabel: submitLabel,
        onSubmit: onSubmit,
      ),
    );

Future<bool> showChoiceSheet<T>({
  required BuildContext context,
  required String title,
  required List<DropdownOption<T>> options,
  required T selected,
  required String submitLabel,
  required Future<void> Function(T value) onSubmit,
}) =>
    _show(
      context,
      _ChoiceSheet<T>(
        title: title,
        options: options,
        initial: selected,
        submitLabel: submitLabel,
        onSubmit: onSubmit,
      ),
    );

Future<bool> _show(BuildContext context, Widget sheet) async {
  final result = await showAppBottomSheet<bool>(
    context: context,
    builder: (_) => sheet,
  );
  return result ?? false;
}

/// Title, optional message, fields, inline error and the submit button.
class SheetFrame extends StatefulWidget {
  const SheetFrame({
    super.key,
    required this.title,
    required this.fields,
    required this.submitLabel,
    required this.onSubmit,
    this.message,
    this.destructive = false,
  });

  final String title;
  final String? message;
  final List<Widget> fields;
  final String submitLabel;
  final Future<void> Function() onSubmit;
  final bool destructive;

  @override
  State<SheetFrame> createState() => _SheetFrameState();
}

class _SheetFrameState extends State<SheetFrame> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.onSubmit();
      if (mounted) Navigator.of(context).pop(true);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              header: true,
              child: Text(widget.title, style: AppTypography.subheading),
            ),
            if (widget.message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(widget.message!, style: AppTypography.bodySecondary),
            ],
            const SizedBox(height: AppSpacing.md),
            if (_error != null) ...[
              InlineMessage(message: _error!),
              const SizedBox(height: AppSpacing.sm),
            ],
            ...widget.fields,
            const SizedBox(height: AppSpacing.md),
            if (widget.destructive)
              DestructiveButton(
                label: widget.submitLabel,
                isLoading: _loading,
                onPressed: _submit,
              )
            else
              PrimaryButton(
                label: widget.submitLabel,
                isLoading: _loading,
                onPressed: _submit,
              ),
          ],
        ),
      ),
    );
  }
}

class _AmountSheet extends StatefulWidget {
  const _AmountSheet({
    required this.title,
    required this.message,
    required this.label,
    required this.submitLabel,
    required this.initial,
    required this.onSubmit,
  });

  final String title;
  final String? message;
  final String label;
  final String submitLabel;
  final double? initial;
  final Future<void> Function(double) onSubmit;

  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  late final _controller = TextEditingController(
    text: widget.initial == null ? '' : editableAmount(widget.initial!),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SheetFrame(
      title: widget.title,
      message: widget.message,
      submitLabel: widget.submitLabel,
      fields: [MoneyField(label: widget.label, controller: _controller)],
      onSubmit: () => widget.onSubmit(parseMoney(_controller.text.trim())),
    );
  }
}

class _DateSheet extends StatefulWidget {
  const _DateSheet({
    required this.title,
    required this.message,
    required this.label,
    required this.submitLabel,
    required this.destructive,
    required this.onSubmit,
  });

  final String title;
  final String? message;
  final String label;
  final String submitLabel;
  final bool destructive;
  final Future<void> Function(DateTime) onSubmit;

  @override
  State<_DateSheet> createState() => _DateSheetState();
}

class _DateSheetState extends State<_DateSheet> {
  DateTime _date = DateUtils.dateOnly(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    return SheetFrame(
      title: widget.title,
      message: widget.message,
      submitLabel: widget.submitLabel,
      destructive: widget.destructive,
      fields: [
        AppDateField(
          label: widget.label,
          value: _date,
          firstDate: DateTime(today.year - 1, today.month, today.day),
          lastDate: DateTime(today.year + 1, today.month, today.day),
          onChanged: (d) => setState(() => _date = d),
        ),
      ],
      onSubmit: () => widget.onSubmit(_date),
    );
  }
}

class _TextSheet extends StatefulWidget {
  const _TextSheet({
    required this.title,
    required this.message,
    required this.label,
    required this.hint,
    required this.initial,
    required this.requiredMessage,
    required this.submitLabel,
    required this.onSubmit,
  });

  final String title;
  final String? message;
  final String label;
  final String? hint;
  final String? initial;
  final String requiredMessage;
  final String submitLabel;
  final Future<void> Function(String) onSubmit;

  @override
  State<_TextSheet> createState() => _TextSheetState();
}

class _TextSheetState extends State<_TextSheet> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SheetFrame(
      title: widget.title,
      message: widget.message,
      submitLabel: widget.submitLabel,
      fields: [
        AppTextField(
          label: widget.label,
          hint: widget.hint,
          controller: _controller,
          textCapitalization: TextCapitalization.sentences,
          validator: (v) => (v == null || v.trim().isEmpty)
              ? widget.requiredMessage
              : null,
        ),
      ],
      onSubmit: () => widget.onSubmit(_controller.text.trim()),
    );
  }
}

class _ChoiceSheet<T> extends StatefulWidget {
  const _ChoiceSheet({
    required this.title,
    required this.options,
    required this.initial,
    required this.submitLabel,
    required this.onSubmit,
  });

  final String title;
  final List<DropdownOption<T>> options;
  final T initial;
  final String submitLabel;
  final Future<void> Function(T) onSubmit;

  @override
  State<_ChoiceSheet<T>> createState() => _ChoiceSheetState<T>();
}

class _ChoiceSheetState<T> extends State<_ChoiceSheet<T>> {
  late T _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return SheetFrame(
      title: widget.title,
      submitLabel: widget.submitLabel,
      fields: [
        RadioGroup<T>(
          groupValue: _value,
          onChanged: (v) => setState(() => _value = v ?? _value),
          child: Column(
            children: [
              for (final option in widget.options)
                RadioListTile<T>(
                  value: option.value,
                  title: Text(option.label, style: AppTypography.body),
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
      ],
      onSubmit: () => widget.onSubmit(_value),
    );
  }
}
