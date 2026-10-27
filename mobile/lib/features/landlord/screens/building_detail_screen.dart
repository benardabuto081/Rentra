import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/text.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_body.dart';
import '../../../core/widgets/display.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/states.dart';
import '../models/building.dart';
import '../models/unit.dart';
import '../providers/landlord_providers.dart';
import '../widgets/status_labels.dart';

class BuildingDetailScreen extends ConsumerWidget {
  const BuildingDetailScreen({super.key, required this.buildingId});

  final String buildingId;

  Future<void> _deactivate(
    BuildContext context,
    WidgetRef ref,
    Building building,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Deactivate ${building.name}?',
      message:
          'It will no longer appear in My Properties. Its units and records are kept.',
      confirmLabel: 'Deactivate',
      destructive: true,
    );
    final orgId = ref.read(currentOrgIdProvider);
    if (!confirmed || orgId == null) return;
    try {
      await ref.read(buildingRepositoryProvider).deactivate(orgId, building.id);
      invalidatePortfolio(ref);
      if (!context.mounted) return;
      showSuccessSnackBar(context, '${building.name} deactivated.');
      context.go(AppRoutes.landlordProperties);
    } on AppException catch (e) {
      if (context.mounted) showErrorSnackBar(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final building = ref.watch(buildingProvider(buildingId));
    final units = ref.watch(unitsProvider(buildingId));
    Future<void> refresh() async {
      ref.invalidate(buildingProvider(buildingId));
      ref.invalidate(unitsProvider(buildingId));
      await ref.read(unitsProvider(buildingId).future);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(building.value?.name ?? 'Building'),
        actions: [
          if (building.value case final b?)
            PopupMenuButton<String>(
              tooltip: 'More actions',
              onSelected: (choice) => choice == 'edit'
                  ? context.push(AppRoutes.editBuilding(b.id))
                  : _deactivate(context, ref, b),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit building')),
                PopupMenuItem(value: 'deactivate', child: Text('Deactivate building')),
              ],
            ),
        ],
      ),
      floatingActionButton: units.value?.isNotEmpty == true
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.addUnits(buildingId)),
              icon: const Icon(Icons.add),
              label: const Text('Add units'),
            )
          : null,
      body: AsyncBody<Building>(
        value: building,
        onRetry: refresh,
        data: (b) => RefreshIndicator(
          onRefresh: refresh,
          child: AsyncBody<List<Unit>>(
            value: units,
            onRetry: refresh,
            data: (list) => list.isEmpty
                ? EmptyState(
                    icon: Icons.meeting_room_outlined,
                    title: 'No units yet',
                    message:
                        'Add the rooms, bedsitters or shops in ${b.name}. Each unit can then have its own tenant and rent.',
                    actionLabel: 'Add units',
                    onAction: () => context.push(AppRoutes.addUnits(b.id)),
                  )
                : _UnitList(building: b, units: list),
          ),
        ),
      ),
    );
  }
}

class _UnitList extends StatelessWidget {
  const _UnitList({required this.building, required this.units});

  final Building building;
  final List<Unit> units;

  @override
  Widget build(BuildContext context) {
    final occupied = units.where((u) => u.status == UnitStatus.occupied).length;
    final place = [building.address, building.city]
        .whereType<String>()
        .where((p) => p.trim().isNotEmpty)
        .join(', ');
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.xxxl + AppSpacing.md,
      ),
      itemCount: units.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (place.isNotEmpty) ...[
                    Text(place, style: AppTypography.bodySecondary),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  Text(
                    '$occupied of ${plural(units.length, 'unit')} occupied',
                    style: AppTypography.subheading,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.xxs),
                    child: LinearProgressIndicator(
                      value: units.isEmpty ? 0 : occupied / units.length,
                      minHeight: AppSpacing.xs,
                      semanticsLabel: 'Occupancy',
                      semanticsValue: units.isEmpty
                          ? '0%'
                          : '${(occupied * 100 / units.length).round()}%',
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        final unit = units[i - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: ListCard(
            title: unit.name,
            subtitle: '${unit.type.label} · ${formatMoney(unit.rentAmount)}',
            trailing: chipFor(unitStatus(unit.status)),
            onTap: () => context.go(AppRoutes.unit(building.id, unit.id)),
          ),
        );
      },
    );
  }
}
