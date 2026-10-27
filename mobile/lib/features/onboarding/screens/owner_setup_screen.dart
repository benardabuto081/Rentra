import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/text_fields.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/providers/session_providers.dart';
import '../providers/onboarding_draft.dart';
import '../widgets/onboarding_widgets.dart';

/// Ported as-is: the name, city and phone entered here are not sent yet.
/// See docs/open-questions.md.
class OwnerSetupScreen extends ConsumerStatefulWidget {
  const OwnerSetupScreen({super.key});

  @override
  ConsumerState<OwnerSetupScreen> createState() => _OwnerSetupScreenState();
}

class _OwnerSetupScreenState extends ConsumerState<OwnerSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _phone = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final draft = ref.read(onboardingDraftProvider);
    if (draft == null) {
      setState(() => _error = 'Session expired. Please start again.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await ref.read(authRepositoryProvider).registerLandlord(
            firstName: draft.firstName,
            lastName: draft.lastName,
            email: draft.email,
            password: draft.password,
          );
      await ref.read(sessionControllerProvider.notifier).establish(session);
      ref.read(onboardingDraftProvider.notifier).clear();
      if (mounted) context.go(AppRoutes.tour);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Property Owner Setup')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const OnboardingHeader(
                icon: Icons.apartment_outlined,
                title: 'Set up your property portfolio',
                subtitle: 'You can add your buildings and units after setup.',
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_error != null) ...[
                InlineMessage(message: _error!),
                const SizedBox(height: AppSpacing.sm),
              ],
              AppTextField(
                label: 'Business or Portfolio Name',
                controller: _name,
                hint: 'e.g. Kamau Properties',
                textCapitalization: TextCapitalization.words,
                validator: Validators.required(
                  'Please enter your business or portfolio name.',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: 'City (optional)',
                controller: _city,
                hint: 'e.g. Nairobi',
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppSpacing.sm),
              KenyanPhoneField(
                controller: _phone,
                label: 'Business Phone (optional)',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? null
                    : Validators.kenyanPhone(v),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Complete Setup',
                isLoading: _loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
