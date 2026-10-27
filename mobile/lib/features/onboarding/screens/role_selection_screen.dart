import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/buttons.dart';
import '../widgets/onboarding_widgets.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
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
              onTap: () => context.push(AppRoutes.tenantSetup),
            ),
            const SizedBox(height: AppSpacing.sm),
            ChoiceCard(
              icon: Icons.apartment_outlined,
              title: 'I own property',
              subtitle: 'Manage my buildings, units, tenants and collect rent.',
              onTap: () => context.push(AppRoutes.ownerSetup),
            ),
            const SizedBox(height: AppSpacing.sm),
            ChoiceCard(
              icon: Icons.manage_accounts_outlined,
              title: 'I manage properties',
              subtitle:
                  'I was invited to manage properties on behalf of an owner.',
              onTap: () => context.go(AppRoutes.tour),
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: AppTextButton(
                label: 'Skip for now',
                onPressed: () => context.go(AppRoutes.tour),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
