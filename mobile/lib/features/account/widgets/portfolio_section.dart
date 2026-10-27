import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_body.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/display.dart';
import '../../../core/widgets/states.dart';
import '../../landlord/models/organization.dart';
import '../../landlord/providers/landlord_providers.dart';

class PortfolioSection extends ConsumerWidget {
  const PortfolioSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'My Properties'),
        AsyncBody<Organization>(
          value: ref.watch(organizationProvider),
          onRetry: () => ref.invalidate(organizationProvider),
          loading: const SkeletonBox(height: AppSpacing.xxxl * 3, radius: AppRadii.card),
          data: (org) {
            String show(String? v) =>
                v == null || v.trim().isEmpty ? 'Not added yet' : v.trim();
            return AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DetailRow(label: 'Business name', value: org.name),
                  DetailRow(label: 'Phone', value: show(org.phone)),
                  DetailRow(label: 'Email', value: show(org.email)),
                  DetailRow(label: 'Address', value: show(org.address)),
                  DetailRow(label: 'City', value: show(org.city)),
                  const SizedBox(height: AppSpacing.sm),
                  SecondaryButton(
                    label: 'Edit details',
                    icon: Icons.edit_outlined,
                    onPressed: () => context.push(AppRoutes.editPortfolio),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
