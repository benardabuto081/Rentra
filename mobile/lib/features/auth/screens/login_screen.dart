import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/text_fields.dart';
import '../providers/auth_providers.dart';
import '../providers/session_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  /// Tenants sign in with a phone number, landlords and caretakers with email.
  bool get _isPhone {
    final text = _identifier.text.trim();
    return text.startsWith('0') || text.startsWith('+');
  }

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final repo = ref.read(authRepositoryProvider);
    try {
      final session = _isPhone
          ? await repo.tenantLogin(
              phone: _identifier.text.trim(),
              password: _password.text,
            )
          : await repo.login(
              email: _identifier.text.trim(),
              password: _password.text,
            );
      await ref.read(sessionControllerProvider.notifier).establish(session);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasInput = _identifier.text.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(AppRoutes.welcome),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: AutofillGroup(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const Text('Welcome back', style: AppTypography.display),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Sign in with your email or phone number',
                  style: AppTypography.bodySecondary,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_error != null) ...[
                  InlineMessage(message: _error!),
                  const SizedBox(height: AppSpacing.sm),
                ],
                AppTextField(
                  label: 'Email or Phone Number',
                  controller: _identifier,
                  hint: 'name@email.com or 0712345678',
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [
                    AutofillHints.email,
                    AutofillHints.telephoneNumber,
                  ],
                  onChanged: (_) => setState(() {}),
                  validator: Validators.required(
                    'Enter your email or phone number.',
                  ),
                ),
                if (hasInput) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _isPhone
                        ? 'Signing in as tenant'
                        : 'Signing in as landlord / manager',
                    style: AppTypography.caption,
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                PasswordField(
                  controller: _password,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  validator: Validators.required('Enter your password.'),
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: 'Sign In',
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
