import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/text.dart';
import '../../../core/widgets/async_body.dart';
import '../../../core/widgets/display.dart';
import '../../../core/widgets/states.dart';
import '../models/building.dart';
import '../models/dashboard.dart';
import '../providers/landlord_providers.dart';

class PropertiesScreen extends ConsumerWidget {
  const PropertiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buildings = ref.watch(buildingsProvider);
    final summaries = ref.watch(buildingSummariesProvider).value ?? const [];
    final tenancies = ref.watch(currentTenanciesProvider).value;

    Future<void> refresh() async {
      ref.invalidate(buildingSummariesProvider);
      ref.invalidate(currentTenanciesProvider);
      ref.invalidate(buildingsProvider);
      await ref.read(buildingsProvider.future);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Properties')),
      floatingActionButton: buildings.value?.isNotEmpty == true
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.newBuilding),
              icon: const Icon(Icons.add),
              label: const Text('Add building'),
            )
          : null,
      body: AsyncBody<List<Building>>(
        value: buildings,
        onRetry: refresh,
        data: (list) => list.isEmpty
            ? EmptyState(
                icon: Icons.apartment_outlined,
                title: 'No buildings yet',
                message:
                    'Add a building and its units to start inviting tenants and recording rent.',
                actionLabel: 'Add a building',
                onAction: () => context.push(AppRoutes.newBuilding),
              )
            : RefreshIndicator(
                onRefresh: refresh,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.xxxl + AppSpacing.md,
                  ),
                  itemCount: list.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ListCard(
                            icon: Icons.people_outline,
                            title: 'Tenants',
                            subtitle: tenancies == null
                                ? 'Everyone currently renting from you'
                                : plural(tenancies.length, 'current tenant'),
                            onTap: () => context.go(AppRoutes.landlordTenants),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const SectionHeader(title: 'Buildings'),
                        ],
                      );
                    }
                    final building = list[i - 1];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: _BuildingCard(
                        building: building,
                        summary: _summaryFor(summaries, building.id),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  static BuildingSummary? _summaryFor(List<BuildingSummary> all, String id) {
    for (final s in all) {
      if (s.buildingId == id) return s;
    }
    return null;
  }
}

class _BuildingCard extends StatelessWidget {
  const _BuildingCard({required this.building, required this.summary});

  final Building building;
  final BuildingSummary? summary;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final place = [building.address, building.city]
        .whereType<String>()
        .where((p) => p.trim().isNotEmpty)
        .join(', ');
    final occupancy = s == null
        ? null
        : s.totalUnits == 0
            ? 'No units yet'
            : '${s.occupiedUnits} of ${plural(s.totalUnits, 'unit')} occupied';
    return ListCard(
      icon: Icons.apartment_outlined,
      title: building.name,
      subtitle: [if (place.isNotEmpty) place, if (occupancy != null) occupancy]
          .join('\n'),
      onTap: () => context.go(AppRoutes.building(building.id)),
    );
  }
}
