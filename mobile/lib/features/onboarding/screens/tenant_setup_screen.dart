import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/text_fields.dart';
import '../../auth/models/passkey_preview.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/providers/session_providers.dart';
import '../../tenant/models/shadow_rental.dart';
import '../../tenant/providers/tenant_providers.dart';
import '../widgets/onboarding_widgets.dart';

enum _Step { choice, passkey, shadow }

class TenantSetupScreen extends ConsumerStatefulWidget {
  const TenantSetupScreen({super.key});

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

  final _shadowForm = GlobalKey<FormState>();
  final _nickname = TextEditingController();
  final _address = TextEditingController();
  final _rent = TextEditingController();
  final _destinationNumber = TextEditingController();
  final _reference = TextEditingController();
  PaymentDestinationType _destinationType = PaymentDestinationType.paybill;
  int _dueDay = 1;

  @override
  void dispose() {
    for (final c in [
      _passkey,
      _nickname,
      _address,
      _rent,
      _destinationNumber,
      _reference,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _goTo(_Step step) => setState(() {
        _step = step;
        _error = null;
        _preview = null;
        _previewFailed = false;
      });

  void _finish() => context.go(AppRoutes.tour);

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
      final preview = await ref.read(authRepositoryProvider).previewPasskey(code);
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
      if (mounted) _finish();
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveShadow() async {
    if (!_shadowForm.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    String? optional(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    try {
      await ref.read(shadowRentalRepositoryProvider).create(
            nickname: _nickname.text.trim(),
            address: optional(_address),
            rentAmount: parseMoney(_rent.text.trim()),
            billingCycle: BillingCycle.monthly,
            dueDayOfMonth: _dueDay,
            destinationType: _destinationType,
            destinationNumber: _destinationNumber.text.trim(),
            referenceName: optional(_reference),
          );
      if (mounted) _finish();
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
              _Step.shadow => _buildShadow(),
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
          title: 'My landlord is on Rentra',
          subtitle: 'I have a passkey from my landlord.',
          onTap: () => _goTo(_Step.passkey),
        ),
        const SizedBox(height: AppSpacing.sm),
        ChoiceCard(
          icon: Icons.edit_note,
          title: 'My landlord is not on Rentra',
          subtitle: 'I will enter my rent details manually.',
          onTap: () => _goTo(_Step.shadow),
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: AppTextButton(label: 'Skip for now', onPressed: _finish),
        ),
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

  Widget _buildShadow() {
    final numberLabel = switch (_destinationType) {
      PaymentDestinationType.paybill => 'Paybill Number',
      PaymentDestinationType.till => 'Till Number',
      PaymentDestinationType.bank => 'Account Number',
    };
    return Form(
      key: _shadowForm,
      child: ListView(
        key: const ValueKey(_Step.shadow),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const OnboardingHeader(
            title: 'Tell us about your rental',
            subtitle:
                'We will use this to track your payments and build your rental history.',
          ),
          const SizedBox(height: AppSpacing.md),
          _errorBlock(),
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
            label: 'Monthly Rent',
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
          AppDropdownField<int>(
            label: 'Rent Due Day',
            value: _dueDay,
            options: [
              for (var d = 1; d <= 28; d++)
                DropdownOption(d, 'Day $d of every month'),
            ],
            onChanged: (v) => setState(() => _dueDay = v ?? 1),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text('How do you pay rent?', style: AppTypography.label),
          const SizedBox(height: AppSpacing.xs),
          SegmentedButton<PaymentDestinationType>(
            showSelectedIcon: false,
            segments: [
              for (final type in PaymentDestinationType.values)
                ButtonSegment(value: type, label: Text(type.label)),
            ],
            selected: {_destinationType},
            onSelectionChanged: (s) =>
                setState(() => _destinationType = s.first),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: numberLabel,
            controller: _destinationNumber,
            hint: _destinationType == PaymentDestinationType.paybill
                ? 'e.g. 522522'
                : 'e.g. 0123456',
            keyboardType: TextInputType.number,
            validator: Validators.required('Please enter the payment number.'),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Reference (optional)',
            controller: _reference,
            hint: 'e.g. your phone number',
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Save My Rental',
            isLoading: _loading,
            onPressed: _saveShadow,
          ),
        ],
      ),
    );
  }
}
