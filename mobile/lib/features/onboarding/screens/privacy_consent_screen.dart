import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/display.dart';
import '../../../core/widgets/states.dart';
import '../providers/onboarding_draft.dart';
import '../widgets/onboarding_widgets.dart';

class PrivacyConsentScreen extends ConsumerStatefulWidget {
  const PrivacyConsentScreen({super.key});

  @override
  ConsumerState<PrivacyConsentScreen> createState() =>
      _PrivacyConsentScreenState();
}

class _PrivacyConsentScreenState extends ConsumerState<PrivacyConsentScreen> {
  bool _agreedToTerms = false;
  bool _agreedToData = false;
  String? _error;

  void _continue() {
    if (!_agreedToTerms || !_agreedToData) {
      setState(() => _error = 'Please agree to both terms to continue.');
      return;
    }
    if (ref.read(onboardingDraftProvider) == null) {
      setState(() => _error = 'Registration data lost. Please start again.');
      return;
    }
    setState(() => _error = null);
    context.push(AppRoutes.role);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const OnboardingHeader(
              icon: Icons.shield_outlined,
              title: 'Your data belongs to you',
              subtitle:
                  'Rentra uses your data only to manage your rentals and build your history.',
            ),
            const SizedBox(height: AppSpacing.lg),
            const _DataPoint(icon: Icons.home_outlined, text: 'Manage your rentals'),
            const _DataPoint(icon: Icons.receipt_long_outlined, text: 'Track your payments'),
            const _DataPoint(icon: Icons.people_outline, text: 'Connect with households'),
            const _DataPoint(icon: Icons.history, text: 'Build your rental history'),
            const SizedBox(height: AppSpacing.md),
            if (_error != null) ...[
              InlineMessage(message: _error!),
              const SizedBox(height: AppSpacing.sm),
            ],
            CheckboxListTile(
              value: _agreedToTerms,
              onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'I agree to the Terms of Service and Privacy Policy',
                style: AppTypography.body,
              ),
            ),
            CheckboxListTile(
              value: _agreedToData,
              onChanged: (v) => setState(() => _agreedToData = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'I consent to Rentra processing my rental data',
                style: AppTypography.body,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Continue',
              onPressed: _continue,
            ),
          ],
        ),
      ),
    );
  }
}

class _DataPoint extends StatelessWidget {
  const _DataPoint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          IconBadge(icon: icon, size: AppSpacing.xl),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTypography.body)),
        ],
      ),
    );
  }
}
