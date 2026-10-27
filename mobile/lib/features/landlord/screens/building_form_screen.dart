import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/async_body.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/text_fields.dart';
import '../models/building.dart';
import '../providers/landlord_providers.dart';

/// Adds a building, or edits one when [buildingId] is given.
class BuildingFormScreen extends ConsumerWidget {
  const BuildingFormScreen({super.key, this.buildingId});

  final String? buildingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = buildingId;
    return Scaffold(
      appBar: AppBar(title: Text(id == null ? 'Add a building' : 'Edit building')),
      body: SafeArea(
        child: id == null
            ? const _BuildingForm()
            : AsyncBody<Building>(
                value: ref.watch(buildingProvider(id)),
                onRetry: () => ref.invalidate(buildingProvider(id)),
                data: (b) => _BuildingForm(initial: b),
              ),
      ),
    );
  }
}

class _BuildingForm extends ConsumerStatefulWidget {
  const _BuildingForm({this.initial});

  final Building? initial;

  @override
  ConsumerState<_BuildingForm> createState() => _BuildingFormState();
}

class _BuildingFormState extends ConsumerState<_BuildingForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _address = TextEditingController(text: widget.initial?.address);
  late final _city = TextEditingController(text: widget.initial?.city);
  late final _county = TextEditingController(text: widget.initial?.county);
  late final _floors =
      TextEditingController(text: widget.initial?.totalFloors?.toString());
  late final _description =
      TextEditingController(text: widget.initial?.description);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _address, _city, _county, _floors, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final orgId = ref.read(currentOrgIdProvider);
    if (orgId == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final initial = widget.initial;
    final repo = ref.read(buildingRepositoryProvider);
    final floors = int.tryParse(_floors.text.trim());
    String? text(TextEditingController c) =>
        initial == null && c.text.trim().isEmpty ? null : c.text.trim();
    try {
      if (initial == null) {
        final building = await repo.create(
          orgId,
          name: _name.text.trim(),
          address: text(_address),
          city: text(_city),
          county: text(_county),
          totalFloors: floors,
          description: text(_description),
        );
        invalidatePortfolio(ref);
        if (!mounted) return;
        showSuccessSnackBar(context, 'Building added.');
        context.pushReplacement(
          AppRoutes.addUnits(building.id, afterNewBuilding: true),
        );
      } else {
        await repo.update(
          orgId,
          initial.id,
          name: _name.text.trim(),
          address: text(_address),
          city: text(_city),
          county: text(_county),
          totalFloors: floors,
          description: text(_description),
        );
        invalidatePortfolio(ref);
        if (!mounted) return;
        showSuccessSnackBar(context, 'Building details saved.');
        context.pop();
      }
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (_error != null) ...[
            InlineMessage(message: _error!),
            const SizedBox(height: AppSpacing.sm),
          ],
          AppTextField(
            label: 'Building name',
            controller: _name,
            hint: 'e.g. Kamau Court',
            textCapitalization: TextCapitalization.words,
            validator: Validators.required('Please enter a name for the building.'),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Street or area (optional)',
            controller: _address,
            hint: 'e.g. Thika Road, Kasarani',
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Town or city (optional)',
            controller: _city,
            hint: 'e.g. Nairobi',
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'County (optional)',
            controller: _county,
            hint: 'e.g. Nairobi',
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Number of floors (optional)',
            controller: _floors,
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
            label: widget.initial == null ? 'Add building' : 'Save changes',
            isLoading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
