import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/text_fields.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/onboarding_draft.dart';
import '../widgets/onboarding_widgets.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _code = TextEditingController();
  bool _verifying = false;
  bool _resending = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify(String email) async {
    if (_verifying) return;
    if (_code.text.length != 6) {
      setState(() => _error = 'Please enter the complete 6-digit code.');
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).verifyOtp(
            recipient: email,
            channel: OtpChannel.email,
            code: _code.text,
          );
      if (mounted) context.push(AppRoutes.privacy);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend(String email) async {
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .sendOtp(recipient: email, channel: OtpChannel.email);
      _code.clear();
      if (mounted) showSuccessSnackBar(context, 'Code resent successfully');
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(onboardingDraftProvider)?.email;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: email == null
            ? EmptyState(
                icon: Icons.email_outlined,
                title: 'Let’s start again',
                message:
                    'We no longer have your sign-up details. Enter them again and we’ll send a new code.',
                actionLabel: 'Start again',
                onAction: () => context.go(AppRoutes.createAccount),
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  OnboardingHeader(
                    icon: Icons.email_outlined,
                    title: 'Verify your email',
                    subtitle: 'We sent a 6-digit code to $email',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (_error != null) ...[
                    InlineMessage(message: _error!),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  OtpField(
                    controller: _code,
                    onCompleted: (_) => _verify(email),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: 'Verify Email',
                    isLoading: _verifying,
                    onPressed: () => _verify(email),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Center(
                    child: AppTextButton(
                      label: 'Resend code',
                      isLoading: _resending,
                      onPressed: () => _resend(email),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
