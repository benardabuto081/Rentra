import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/states.dart';
import '../../auth/models/app_user.dart';
import '../providers/onboarding_draft.dart';
import '../providers/registration.dart';
import '../widgets/onboarding_widgets.dart';

/// Creates the account once the person confirms how they use Rentra.
class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  OnboardingRole? _role;
  bool _loading = false;
  String? _error;
  bool _alreadyRegistered = false;
  bool _draftLost = false;

  void _select(OnboardingRole role) {
    if (_loading) return;
    setState(() {
      _role = role;
      _error = null;
      _alreadyRegistered = false;
    });
  }

  Future<void> _confirm() async {
    final role = _role;
    if (role == null || _loading) return;
    final registration = ref.read(registrationProvider);
    setState(() {
      _loading = true;
      _error = null;
      _alreadyRegistered = false;
      _draftLost = false;
    });
    try {
      if (!registration.hasDraft) {
        setState(() {
          _draftLost = true;
          _error = 'Registration data lost. Please start again.';
        });
        return;
      }
      final session = await registration.register(role);
      if (!mounted) return;
      context.go(
        session.user.role == UserRole.tenant
            ? AppRoutes.tenantSetup
            : AppRoutes.ownerSetup,
      );
    } on AppException catch (e) {
      final failure = describeRegistrationFailure(e);
      if (mounted) {
        setState(() {
          _error = failure.message;
          _alreadyRegistered = failure.alreadyRegistered;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _signInInstead() {
    ref.read(onboardingDraftProvider.notifier).clear();
    context.go(AppRoutes.login);
  }

  void _startAgain() {
    ref.read(onboardingDraftProvider.notifier).clear();
    context.go(AppRoutes.createAccount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const OnboardingHeader(
              title: 'How do you use Rentra?',
              subtitle: 'You can add more roles later from your account.',
            ),
            const SizedBox(height: AppSpacing.lg),
            ChoiceCard(
              icon: Icons.home_outlined,
              title: 'I rent a property',
              subtitle: 'Track my rent payments and build my rental history.',
              selected: _role == OnboardingRole.renter,
              onTap: () => _select(OnboardingRole.renter),
            ),
            const SizedBox(height: AppSpacing.sm),
            ChoiceCard(
              icon: Icons.apartment_outlined,
              title: 'I own property',
              subtitle: 'Manage my buildings, units, tenants and collect rent.',
              selected: _role == OnboardingRole.owner,
              onTap: () => _select(OnboardingRole.owner),
            ),
            const SizedBox(height: AppSpacing.sm),
            ChoiceCard(
              icon: Icons.manage_accounts_outlined,
              title: 'I manage properties',
              subtitle:
                  'Manage buildings, units and tenants on behalf of owners.',
              selected: _role == OnboardingRole.manager,
              onTap: () => _select(OnboardingRole.manager),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_error != null) ...[
              InlineMessage(message: _error!),
              const SizedBox(height: AppSpacing.sm),
              if (_alreadyRegistered) ...[
                SecondaryButton(label: 'Sign In', onPressed: _signInInstead),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (_draftLost) ...[
                SecondaryButton(label: 'Start again', onPressed: _startAgain),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
            PrimaryButton(
              label: 'Continue',
              isLoading: _loading,
              onPressed: _role == null ? null : _confirm,
            ),
          ],
        ),
      ),
    );
  }
}
