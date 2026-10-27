import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/text_fields.dart';
import '../../auth/models/passkey_preview.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/providers/session_providers.dart';
import '../../tenant/providers/tenant_providers.dart';
import '../../tenant/widgets/shadow_rental_form.dart';
import '../widgets/onboarding_widgets.dart';

enum _Step { choice, passkey, shadow }

/// Lets a tenant join their landlord with a passkey, or record the rental
/// themselves. Used during onboarding and later from Home.
class TenantSetupScreen extends ConsumerStatefulWidget {
  const TenantSetupScreen({super.key, this.fromOnboarding = true});

  final bool fromOnboarding;

  @override
  ConsumerState<TenantSetupScreen> createState() => _TenantSetupScreenState();
}

class _TenantSetupScreenState extends ConsumerState<TenantSetupScreen> {
  static const _passkeyUnavailable =
      "We couldn't check this passkey right now. You can try again, "
      'or set up your rental yourself.';

  _Step _step = _Step.choice;
  String? _error;
  bool _loading = false;

  final _passkeyForm = GlobalKey<FormState>();
  final _passkey = TextEditingController();
  PasskeyPreview? _preview;
  bool _previewFailed = false;

  @override
  void dispose() {
    _passkey.dispose();
    super.dispose();
  }

  void _goTo(_Step step) => setState(() {
        _step = step;
        _error = null;
        _preview = null;
        _previewFailed = false;
      });

  void _finish(String confirmation) {
    showSuccessSnackBar(context, confirmation);
    ref.invalidate(activeShadowRentalProvider);
    context.go(widget.fromOnboarding ? AppRoutes.tour : AppRoutes.home);
  }

  static String? _validatePasskey(String? value) {
    final code = value?.trim().toUpperCase() ?? '';
    final valid = RegExp(r'^RTR-[A-Z0-9]{6}$').hasMatch(code);
    return valid ? null : 'Invalid passkey format. Should look like RTR-XXXXXX';
  }

  Future<void> _checkPasskey() async {
    if (!_passkeyForm.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _previewFailed = false;
    });
    final code = _passkey.text.trim().toUpperCase();
    try {
      final preview =
          await ref.read(authRepositoryProvider).previewPasskey(code);
      if (mounted) setState(() => _preview = preview);
    } on AppException {
      if (mounted) {
        setState(() {
          _error = _passkeyUnavailable;
          _previewFailed = true;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinUnit(PasskeyPreview preview) async {
    final rent = preview.rentAmount;
    if (rent == null) {
      setState(() => _error = _passkeyUnavailable);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await ref.read(authRepositoryProvider).linkPasskey(
            passkeyCode: preview.code,
            rentAmount: rent,
            moveInDate: DateTime.now(),
          );
      await ref.read(sessionControllerProvider.notifier).establish(session);
      if (mounted) _finish("You're connected to your landlord's property.");
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveShadow(ShadowRentalInput input) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    String? orNull(String value) => value.isEmpty ? null : value;
    try {
      await ref.read(shadowRentalRepositoryProvider).create(
            nickname: input.nickname,
            address: orNull(input.address),
            rentAmount: input.rentAmount,
            billingCycle: input.billingCycle,
            dueDayOfMonth: input.dueDayOfMonth,
            destinationType: input.destinationType,
            destinationNumber: input.destinationNumber,
            referenceName: orNull(input.referenceName),
          );
      if (mounted) _finish('Your rental is set up.');
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == _Step.choice,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo(_Step.choice);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Your Rental')),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: AppMotion.normal,
            child: switch (_step) {
              _Step.choice => _buildChoice(),
              _Step.passkey => _buildPasskey(),
              _Step.shadow => ShadowRentalForm(
                  key: const ValueKey(_Step.shadow),
                  header: const OnboardingHeader(
                    title: 'Tell us about your rental',
                    subtitle:
                        'We will use this to remind you when rent is due and keep your payment details in one place.',
                  ),
                  submitLabel: 'Save My Rental',
                  isSubmitting: _loading,
                  error: _error,
                  onSubmit: _saveShadow,
                ),
            },
          ),
        ),
      ),
    );
  }

  Widget _errorBlock() => _error == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: InlineMessage(message: _error!),
        );

  Widget _buildChoice() {
    return ListView(
      key: const ValueKey(_Step.choice),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const OnboardingHeader(
          title: 'How is your rent set up?',
          subtitle: 'This helps us track your payments correctly.',
        ),
        const SizedBox(height: AppSpacing.lg),
        ChoiceCard(
          icon: Icons.key_outlined,
          title: 'My landlord gave me a passkey',
          subtitle: 'Join your landlord’s property on Rentra.',
          onTap: () => _goTo(_Step.passkey),
        ),
        const SizedBox(height: AppSpacing.sm),
        ChoiceCard(
          icon: Icons.edit_note,
          title: 'My landlord isn’t on Rentra',
          subtitle: 'Add your rent and how you pay it yourself.',
          onTap: () => _goTo(_Step.shadow),
        ),
        if (widget.fromOnboarding) ...[
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: AppTextButton(
              label: 'Skip for now',
              onPressed: () => context.go(AppRoutes.tour),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPasskey() {
    final preview = _preview;
    return Form(
      key: _passkeyForm,
      child: ListView(
        key: const ValueKey(_Step.passkey),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (preview == null) ...[
            const OnboardingHeader(
              title: 'Enter your passkey',
              subtitle:
                  'Your landlord gave you a passkey that looks like RTR-XXXXXX.',
            ),
            const SizedBox(height: AppSpacing.md),
            _errorBlock(),
            AppTextField(
              label: 'Passkey',
              controller: _passkey,
              hint: 'RTR-XXXXXX',
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9-]')),
                LengthLimitingTextInputFormatter(10),
              ],
              style: AppTypography.subheading,
              validator: _validatePasskey,
              onSubmitted: (_) => _checkPasskey(),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: _previewFailed ? 'Try again' : 'Find My Unit',
              isLoading: _loading,
              onPressed: _checkPasskey,
            ),
            if (_previewFailed) ...[
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                label: 'Set up my rental myself',
                onPressed: () => _goTo(_Step.shadow),
              ),
            ],
          ] else ...[
            const OnboardingHeader(title: 'Is this your home?'),
            const SizedBox(height: AppSpacing.md),
            _errorBlock(),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Property found', style: AppTypography.caption),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    preview.propertyName ?? 'Your property',
                    style: AppTypography.subheading,
                  ),
                  if (preview.unitName != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text('Unit: ${preview.unitName}', style: AppTypography.body),
                  ],
                  if (preview.rentAmount != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Rent: ${formatMoney(preview.rentAmount!)}',
                      style: AppTypography.body,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Confirm and join this unit',
              isLoading: _loading,
              onPressed: () => _joinUnit(preview),
            ),
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              label: 'Use a different passkey',
              onPressed: () => setState(() {
                _preview = null;
                _error = null;
              }),
            ),
          ],
        ],
      ),
    );
  }
}
