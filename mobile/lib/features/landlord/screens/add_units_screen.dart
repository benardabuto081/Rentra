import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/text.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/text_fields.dart';
import '../models/unit.dart';
import '../providers/landlord_providers.dart';
import '../widgets/unit_form.dart';

enum _Mode { one, several }

class AddUnitsScreen extends ConsumerStatefulWidget {
  const AddUnitsScreen({
    super.key,
    required this.buildingId,
    this.afterNewBuilding = false,
  });

  final String buildingId;

  /// True right after the building was created, to guide the next step.
  final bool afterNewBuilding;

  @override
  ConsumerState<AddUnitsScreen> createState() => _AddUnitsScreenState();
}

class _AddUnitsScreenState extends ConsumerState<AddUnitsScreen> {
  _Mode _mode = _Mode.one;
  bool _saving = false;
  String? _error;

  void _toBuilding() => context.go(AppRoutes.building(widget.buildingId));

  Future<void> _addOne(UnitInput input) async {
    final orgId = ref.read(currentOrgIdProvider);
    if (orgId == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(unitRepositoryProvider).create(
            orgId,
            widget.buildingId,
            name: input.name,
            rentAmount: input.rentAmount,
            type: input.type,
            floor: input.floor,
            storageAmount: input.storageAmount,
            description: input.description.isEmpty ? null : input.description,
          );
      invalidatePortfolio(ref);
      if (!mounted) return;
      showSuccessSnackBar(context, 'Unit ${input.name} added.');
      _toBuilding();
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final buildingName =
        ref.watch(buildingProvider(widget.buildingId)).value?.name;
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.afterNewBuilding) ...[
          Text(
            buildingName == null
                ? 'Now add its units'
                : 'Now add the units in $buildingName',
            style: AppTypography.heading,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Each unit can then have its own tenant and rent.',
            style: AppTypography.bodySecondary,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        SegmentedButton<_Mode>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: _Mode.one, label: Text('One unit')),
            ButtonSegment(value: _Mode.several, label: Text('Several units')),
          ],
          selected: {_mode},
          onSelectionChanged: (s) => setState(() {
            _mode = s.first;
            _error = null;
          }),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add units'),
        actions: [
          if (widget.afterNewBuilding)
            TextButton(onPressed: _toBuilding, child: const Text('Later')),
        ],
      ),
      body: SafeArea(
        child: _mode == _Mode.one
            ? UnitForm(
                header: header,
                submitLabel: 'Add unit',
                isSubmitting: _saving,
                error: _error,
                onSubmit: _addOne,
              )
            : _SeveralUnits(
                buildingId: widget.buildingId,
                header: header,
                onDone: _toBuilding,
              ),
      ),
    );
  }
}

/// Creates units one after another, e.g. A1 to A6, all at the same rent.
class _SeveralUnits extends ConsumerStatefulWidget {
  const _SeveralUnits({
    required this.buildingId,
    required this.header,
    required this.onDone,
  });

  final String buildingId;
  final Widget header;
  final VoidCallback onDone;

  @override
  ConsumerState<_SeveralUnits> createState() => _SeveralUnitsState();
}

class _SeveralUnitsState extends ConsumerState<_SeveralUnits> {
  static const _maxUnits = 50;

  final _formKey = GlobalKey<FormState>();
  final _prefix = TextEditingController(text: 'A');
  final _start = TextEditingController(text: '1');
  final _count = TextEditingController(text: '4');
  final _rent = TextEditingController();
  UnitType _type = UnitType.bedsitter;

  bool _running = false;
  int _created = 0;
  int? _progress;
  String? _error;

  @override
  void dispose() {
    for (final c in [_prefix, _start, _count, _rent]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _names {
    final start = int.tryParse(_start.text.trim()) ?? 1;
    final count = int.tryParse(_count.text.trim()) ?? 0;
    final prefix = _prefix.text.trim();
    return [for (var i = 0; i < count; i++) '$prefix${start + i}'];
  }

  String get _preview {
    final names = _names;
    if (names.isEmpty) return '';
    if (names.length <= 3) return 'We will add ${names.join(', ')}.';
    return 'We will add ${names.first}, ${names[1]} … ${names.last}.';
  }

  Future<void> _run() async {
    if (!_formKey.currentState!.validate()) return;
    final orgId = ref.read(currentOrgIdProvider);
    if (orgId == null) return;
    final names = _names;
    final rent = parseMoney(_rent.text.trim());
    setState(() {
      _running = true;
      _error = null;
    });
    final repo = ref.read(unitRepositoryProvider);
    try {
      for (var i = _created; i < names.length; i++) {
        setState(() => _progress = i + 1);
        await repo.create(
          orgId,
          widget.buildingId,
          name: names[i],
          rentAmount: rent,
          type: _type,
        );
        _created = i + 1;
      }
      invalidatePortfolio(ref);
      if (!mounted) return;
      showSuccessSnackBar(context, '${plural(names.length, 'unit')} added.');
      widget.onDone();
    } on AppException catch (e) {
      invalidatePortfolio(ref);
      if (mounted) {
        setState(() => _error =
            'Added $_created of ${names.length} units. We couldn’t add '
            '${names[_created]}: ${e.message}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _running = false;
          _progress = null;
        });
      }
    }
  }

  String? _countValidator(String? value) {
    final n = int.tryParse(value?.trim() ?? '');
    if (n == null || n < 1) return 'Enter how many units to add.';
    if (n > _maxUnits) return 'Add up to $_maxUnits units at a time.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final total = _names.length;
    final remaining = total - _created;
    final label = _running
        ? 'Adding unit $_progress of $total…'
        : _created > 0
            ? 'Add the remaining ${plural(remaining, 'unit')}'
            : 'Add ${plural(total, 'unit')}';
    final locked = _created > 0 || _running;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          widget.header,
          const SizedBox(height: AppSpacing.md),
          if (_error != null) ...[
            InlineMessage(message: _error!),
            const SizedBox(height: AppSpacing.sm),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Name starts with',
                  controller: _prefix,
                  hint: 'e.g. A',
                  enabled: !locked,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTextField(
                  label: 'First number',
                  controller: _start,
                  enabled: !locked,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: Validators.required('Enter a number.'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'How many units',
            controller: _count,
            enabled: !locked,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: _countValidator,
            onChanged: (_) => setState(() {}),
          ),
          if (_preview.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(_preview, style: AppTypography.caption),
          ],
          const SizedBox(height: AppSpacing.sm),
          AppDropdownField<UnitType>(
            label: 'Type',
            value: _type,
            options: [
              for (final t in UnitType.values) DropdownOption(t, t.label),
            ],
            onChanged: locked ? null : (t) => setState(() => _type = t ?? _type),
          ),
          const SizedBox(height: AppSpacing.sm),
          MoneyField(
            label: 'Monthly rent for each unit',
            controller: _rent,
            helper: 'You can change the rent of any unit later.',
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: label,
            isLoading: false,
            onPressed: _running || total == 0 ? null : _run,
          ),
        ],
      ),
    );
  }
}
