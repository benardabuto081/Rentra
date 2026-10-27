import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_body.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/display.dart';
import '../../../core/widgets/feedback.dart';
import '../models/unit.dart';
import '../providers/landlord_providers.dart';
import '../widgets/status_labels.dart';

class UnitDetailScreen extends ConsumerWidget {
  const UnitDetailScreen({
    super.key,
    required this.buildingId,
    required this.unitId,
  });

  final String buildingId;
  final String unitId;

  UnitKey get _key => (buildingId: buildingId, unitId: unitId);

  Future<void> _markVacant(BuildContext context, WidgetRef ref, Unit unit) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Mark ${unit.name} as vacant?',
      message: 'It will show as available, and you can invite a new tenant.',
      confirmLabel: 'Mark vacant',
      destructive: true,
    );
    final orgId = ref.read(currentOrgIdProvider);
    if (!confirmed || orgId == null) return;
    try {
      await ref.read(unitRepositoryProvider).vacate(orgId, buildingId, unitId);
      invalidatePortfolio(ref);
      if (context.mounted) showSuccessSnackBar(context, '${unit.name} is now vacant.');
    } on AppException catch (e) {
      if (context.mounted) showErrorSnackBar(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(unitProvider(_key));
    return Scaffold(
      appBar: AppBar(
        title: Text(unit.value?.name ?? 'Unit'),
        actions: [
          if (unit.hasValue)
            IconButton(
              tooltip: 'Edit unit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push(AppRoutes.editUnit(buildingId, unitId)),
            ),
        ],
      ),
      body: AsyncBody<Unit>(
        value: unit,
        onRetry: () => ref.invalidate(unitProvider(_key)),
        data: (u) => RefreshIndicator(
          onRefresh: () => ref.refresh(unitProvider(_key).future),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.sm),
            children: [
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(u.name, style: AppTypography.heading)),
                        chipFor(unitStatus(u.status)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DetailRow(label: 'Type', value: u.type.label),
                    DetailRow(label: 'Monthly rent', value: formatMoney(u.rentAmount)),
                    if (u.storageAmount > 0)
                      DetailRow(label: 'Storage charge', value: formatMoney(u.storageAmount)),
                    if (u.floor != null)
                      DetailRow(
                        label: 'Floor',
                        value: u.floor == 0 ? 'Ground floor' : '${u.floor}',
                      ),
                    if (u.description?.trim().isNotEmpty == true)
                      DetailRow(label: 'Notes', value: u.description!.trim()),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (u.currentTenantId case final tenancyId?)
                _TenantSection(tenancyId: tenancyId)
              else if (u.isVacant) ...[
                const SectionHeader(title: 'Find a tenant'),
                const Text(
                  'Create a passkey and give it to your new tenant. They enter it when they set up Rentra.',
                  style: AppTypography.bodySecondary,
                ),
                const SizedBox(height: AppSpacing.sm),
                PrimaryButton(
                  label: 'Invite a tenant',
                  icon: Icons.key_outlined,
                  onPressed: () =>
                      context.push(AppRoutes.inviteTenant(buildingId, unitId)),
                ),
              ] else
                DestructiveButton(
                  label: 'Mark as vacant',
                  onPressed: () => _markVacant(context, ref, u),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TenantSection extends ConsumerWidget {
  const _TenantSection({required this.tenancyId});

  final String tenancyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenancy = ref.watch(tenancyProvider(tenancyId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Tenant'),
        AsyncBody(
          value: tenancy,
          onRetry: () => ref.invalidate(tenancyProvider(tenancyId)),
          loading: const SizedBox(height: AppSpacing.xxxl),
          data: (t) => ListCard(
            icon: Icons.person_outline,
            title: 'Tenant since ${formatDate(t.moveInDate)}',
            subtitle: '${formatMoney(t.rentAmount)} a month',
            trailing: chipFor(tenancyStatus(t.status)),
            onTap: () => context.go(AppRoutes.tenancy(t.id)),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'To move this tenant out, open their tenancy.',
          style: AppTypography.caption,
        ),
      ],
    );
  }
}
