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
import '../../auth/data/auth_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/onboarding_draft.dart';
import '../widgets/onboarding_widgets.dart';

class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(onboardingDraftProvider);
    if (draft != null) {
      _firstName.text = draft.firstName;
      _lastName.text = draft.lastName;
      _phone.text = draft.phone;
      _email.text = draft.email;
    }
  }

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _phone, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final email = _email.text.trim();
    ref.read(onboardingDraftProvider.notifier).set(
          OnboardingDraft(
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            phone: _phone.text.trim(),
            email: email,
            password: _password.text,
          ),
        );
    try {
      await ref
          .read(authRepositoryProvider)
          .sendOtp(recipient: email, channel: OtpChannel.email);
      if (mounted) context.push(AppRoutes.verifyEmail);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: AutofillGroup(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const OnboardingHeader(
                  title: 'Your Rentra identity',
                  subtitle: 'Create your account. You control your data.',
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_error != null) ...[
                  InlineMessage(message: _error!),
                  const SizedBox(height: AppSpacing.sm),
                ],
                AppTextField(
                  label: 'First Name',
                  controller: _firstName,
                  hint: 'John',
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.givenName],
                  validator: Validators.required('Enter your first name.'),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  label: 'Last Name',
                  controller: _lastName,
                  hint: 'Kamau',
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.familyName],
                  validator: Validators.required('Enter your last name.'),
                ),
                const SizedBox(height: AppSpacing.sm),
                KenyanPhoneField(controller: _phone, label: 'Phone Number'),
                const SizedBox(height: AppSpacing.sm),
                EmailField(controller: _email, label: 'Email Address'),
                const SizedBox(height: AppSpacing.sm),
                PasswordField(
                  controller: _password,
                  isNewPassword: true,
                  validator: Validators.password,
                ),
                const SizedBox(height: AppSpacing.sm),
                PasswordField(
                  controller: _confirm,
                  label: 'Confirm Password',
                  isNewPassword: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  validator: (value) => value != _password.text
                      ? 'Passwords do not match.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: 'Continue',
                  isLoading: _loading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
