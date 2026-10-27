import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/text.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/display.dart';
import '../../../core/widgets/greeting_header.dart';
import '../../../core/widgets/states.dart';
import '../../auth/providers/session_providers.dart';
import '../providers/landlord_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final dashboard = ref.watch(dashboardProvider);
    Future<void> refresh() => ref.refresh(dashboardProvider.future);
    final header = GreetingHeader(
      firstName: user?.firstName,
      initial: user?.initial ?? 'R',
      subtitle: 'Here is what needs your attention today.',
    );

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: refresh,
          child: switch (dashboard) {
            AsyncData(:final value) => ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                children: [
                  header,
                  if (value.overview.totalBuildings == 0)
                    EmptyState(
                      icon: Icons.apartment_outlined,
                      title: 'Add your first building',
                      message:
                          'Once your buildings and units are in Rentra, you can invite tenants, record rent and follow up on issues from one place.',
                      actionLabel: 'Add a building',
                      onAction: () => context.push(AppRoutes.newBuilding),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: _Content(data: value),
                    ),
                ],
              ),
            AsyncError(:final error) => ListView(
                children: [header, ErrorState(error: error, onRetry: refresh)],
              ),
            _ => ListView(
                physics: const NeverScrollableScrollPhysics(),
                children: [header, const SkeletonList(itemCount: 4)],
              ),
          },
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final o = data.overview;
    final f = data.financial;
    final vacant = data.buildings.fold<int>(0, (sum, b) => sum + b.vacantUnits);
    final totalUnits = data.buildings.fold<int>(0, (sum, b) => sum + b.totalUnits);

    final attention = <Widget>[
      if (o.openIssues > 0)
        ListCard(
          icon: Icons.build_outlined,
          title: '${plural(o.openIssues, 'issue')} waiting for you',
          subtitle: 'Assign someone or mark them resolved.',
          onTap: () => context.go(AppRoutes.landlordOperations),
        ),
      if (f.outstandingCount > 0)
        ListCard(
          icon: Icons.payments_outlined,
          title: '${formatMoney(f.outstanding)} still to collect',
          subtitle: 'From ${plural(f.outstandingCount, 'unpaid or part-paid payment')}.',
          onTap: () => context.go(AppRoutes.landlordPayments),
        ),
      if (o.tenantsOnNotice > 0)
        ListCard(
          icon: Icons.event_busy_outlined,
          title: '${plural(o.tenantsOnNotice, 'tenant')} on notice',
          subtitle: 'Plan for their move-out.',
          onTap: () => context.go(AppRoutes.landlordTenants),
        ),
      if (vacant > 0)
        ListCard(
          icon: Icons.meeting_room_outlined,
          title: '${plural(vacant, 'unit')} vacant',
          subtitle: 'Invite a tenant with a passkey.',
          onTap: () => context.go(AppRoutes.landlordProperties),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'What needs my attention today?'),
        if (attention.isEmpty)
          const InlineMessage(
            message: 'Nothing needs your attention today. Everything is up to date.',
            tone: InlineTone.success,
          )
        else
          for (final item in attention) ...[
            item,
            const SizedBox(height: AppSpacing.xs),
          ],
        const SizedBox(height: AppSpacing.md),
        SectionHeader(title: 'This month · ${formatMonthYear(f.month, f.year)}'),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              DetailRow(label: 'Expected', value: formatMoney(f.expected)),
              DetailRow(label: 'Collected', value: formatMoney(f.collected)),
              DetailRow(label: 'Collection rate', value: '${f.collectionRate}%'),
              DetailRow(label: 'Outstanding (all months)', value: formatMoney(f.outstanding)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const SectionHeader(title: 'My Properties'),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: StatTile(
                  label: 'Buildings',
                  value: '${o.totalBuildings}',
                  icon: Icons.apartment_outlined,
                  onTap: () => context.go(AppRoutes.landlordProperties),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatTile(
                  label: 'Active tenants',
                  value: '${o.activeTenants}',
                  icon: Icons.people_outline,
                  onTap: () => context.go(AppRoutes.landlordTenants),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        StatTile(
          label: 'Units occupied',
          value: '${totalUnits - vacant} of $totalUnits',
          icon: Icons.meeting_room_outlined,
          onTap: () => context.go(AppRoutes.landlordProperties),
        ),
      ],
    );
  }
}
