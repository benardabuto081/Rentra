import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/async_body.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/text_fields.dart';
import '../../auth/providers/session_providers.dart';
import '../../landlord/models/organization.dart';
import '../../landlord/providers/landlord_providers.dart';

class PortfolioFormScreen extends ConsumerWidget {
  const PortfolioFormScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Portfolio details')),
      body: SafeArea(
        child: AsyncBody<Organization>(
          value: ref.watch(organizationProvider),
          onRetry: () => ref.invalidate(organizationProvider),
          data: (org) => _Form(organization: org),
        ),
      ),
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.organization});

  final Organization organization;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.organization.name);
  late final _phone = TextEditingController(text: widget.organization.phone);
  late final _email = TextEditingController(text: widget.organization.email);
  late final _address = TextEditingController(text: widget.organization.address);
  late final _city = TextEditingController(text: widget.organization.city);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _address, _city]) {
      c.dispose();
    }
    super.dispose();
  }

  static String? Function(String?) _optional(String? Function(String?) check) =>
      (v) => v == null || v.trim().isEmpty ? null : check(v);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await ref.read(organizationRepositoryProvider).update(
            widget.organization.id,
            name: _name.text.trim(),
            phone: _phone.text.trim(),
            email: _email.text.trim(),
            address: _address.text.trim(),
            city: _city.text.trim(),
          );
      await ref.read(sessionControllerProvider.notifier).updateOrganization(updated);
      ref.invalidate(organizationProvider);
      if (!mounted) return;
      showSuccessSnackBar(context, 'Portfolio details saved.');
      context.pop();
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
            label: 'Business or Portfolio Name',
            controller: _name,
            textCapitalization: TextCapitalization.words,
            validator: Validators.required('Please enter your business or portfolio name.'),
          ),
          const SizedBox(height: AppSpacing.sm),
          KenyanPhoneField(
            controller: _phone,
            label: 'Business Phone (optional)',
            validator: _optional(Validators.kenyanPhone),
          ),
          const SizedBox(height: AppSpacing.sm),
          EmailField(
            controller: _email,
            label: 'Business Email (optional)',
            validator: _optional(Validators.email),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Address (optional)',
            controller: _address,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'City (optional)',
            controller: _city,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(label: 'Save changes', isLoading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}
