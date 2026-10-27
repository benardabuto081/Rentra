import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/async_body.dart';
import '../../../core/widgets/display.dart';
import '../../../core/widgets/states.dart';
import '../models/tenancy.dart';
import '../providers/landlord_providers.dart';
import '../widgets/status_labels.dart';

class TenantsScreen extends ConsumerWidget {
  const TenantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenancies = ref.watch(currentTenanciesProvider);
    final index = ref.watch(portfolioIndexProvider).value;
    Future<void> refresh() async {
      ref.invalidate(portfolioIndexProvider);
      ref.invalidate(currentTenanciesProvider);
      await ref.read(currentTenanciesProvider.future);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tenants')),
      body: AsyncBody<List<Tenancy>>(
        value: tenancies,
        onRetry: refresh,
        data: (list) => list.isEmpty
            ? EmptyState(
                icon: Icons.people_outline,
                title: 'No tenants yet',
                message:
                    'Tenants appear here once they join a unit with a passkey. Invite one from any vacant unit.',
                actionLabel: 'Go to My Properties',
                onAction: () => context.go(AppRoutes.landlordProperties),
              )
            : RefreshIndicator(
                onRefresh: refresh,
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (context, i) {
                    final t = list[i];
                    return ListCard(
                      icon: Icons.person_outline,
                      title: index?.unitLabel(t.unitId, buildingId: t.buildingId) ?? 'Unit',
                      subtitle:
                          '${formatMoney(t.rentAmount)} a month · since ${formatDate(t.moveInDate)}',
                      trailing: chipFor(tenancyStatus(t.status)),
                      onTap: () => context.go(AppRoutes.tenancy(t.id)),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
