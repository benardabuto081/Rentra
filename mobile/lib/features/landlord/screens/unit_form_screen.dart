import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/async_body.dart';
import '../../../core/widgets/feedback.dart';
import '../models/unit.dart';
import '../providers/landlord_providers.dart';
import '../widgets/unit_form.dart';

class UnitFormScreen extends ConsumerWidget {
  const UnitFormScreen({
    super.key,
    required this.buildingId,
    required this.unitId,
  });

  final String buildingId;
  final String unitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (buildingId: buildingId, unitId: unitId);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit unit')),
      body: SafeArea(
        child: AsyncBody<Unit>(
          value: ref.watch(unitProvider(key)),
          onRetry: () => ref.invalidate(unitProvider(key)),
          data: (unit) => _EditUnit(unit: unit),
        ),
      ),
    );
  }
}

class _EditUnit extends ConsumerStatefulWidget {
  const _EditUnit({required this.unit});

  final Unit unit;

  @override
  ConsumerState<_EditUnit> createState() => _EditUnitState();
}

class _EditUnitState extends ConsumerState<_EditUnit> {
  bool _saving = false;
  String? _error;

  Future<void> _save(UnitInput input) async {
    final orgId = ref.read(currentOrgIdProvider);
    if (orgId == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(unitRepositoryProvider).update(
            orgId,
            widget.unit.buildingId,
            widget.unit.id,
            name: input.name,
            rentAmount: input.rentAmount,
            type: input.type,
            floor: input.floor,
            storageAmount: input.storageAmount ?? 0,
            description: input.description,
          );
      invalidatePortfolio(ref);
      if (!mounted) return;
      showSuccessSnackBar(context, 'Unit details saved.');
      context.pop();
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return UnitForm(
      initial: widget.unit,
      submitLabel: 'Save changes',
      isSubmitting: _saving,
      error: _error,
      onSubmit: _save,
    );
  }
}
