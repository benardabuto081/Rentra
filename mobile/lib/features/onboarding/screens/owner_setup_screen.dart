import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/text_fields.dart';
import '../../auth/providers/session_providers.dart';
import '../../landlord/providers/landlord_providers.dart';
import '../widgets/onboarding_widgets.dart';

/// Saves the business details onto the portfolio created at registration.
/// A failure never blocks onboarding.
class OwnerSetupScreen extends ConsumerStatefulWidget {
  const OwnerSetupScreen({super.key});

  @override
  ConsumerState<OwnerSetupScreen> createState() => _OwnerSetupScreenState();
}

class _OwnerSetupScreenState extends ConsumerState<OwnerSetupScreen> {
  static const _saveFailed =
      "We couldn't save your business details right now. You can try again, "
      'or continue and add them later from your account.';

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _phone = TextEditingController();
  bool _loading = false;
  bool _failed = false;

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _continue() => context.go(AppRoutes.tour);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final session = ref.read(sessionControllerProvider).value;
    final orgId = session?.organization?.id ?? session?.user.organizationId;
    setState(() {
      _loading = true;
      _failed = false;
    });
    String? optional(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    try {
      if (orgId == null) throw const NotFoundException();
      final organization = await ref.read(organizationRepositoryProvider).update(
            orgId,
            name: _name.text.trim(),
            city: optional(_city),
            phone: optional(_phone),
          );
      await ref
          .read(sessionControllerProvider.notifier)
          .updateOrganization(organization);
      if (!mounted) return;
      showSuccessSnackBar(context, 'Your portfolio is set up.');
      _continue();
    } on AppException {
      if (mounted) setState(() => _failed = true);
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
              if (_failed) ...[
                const InlineMessage(message: _saveFailed, tone: InlineTone.info),
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
                label: _failed ? 'Continue' : 'Complete Setup',
                isLoading: _loading,
                onPressed: _failed ? _continue : _submit,
              ),
              if (_failed) ...[
                const SizedBox(height: AppSpacing.sm),
                SecondaryButton(
                  label: 'Try again',
                  isLoading: _loading,
                  onPressed: _submit,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
