import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/display.dart';
import '../../../core/widgets/states.dart';
import '../providers/landlord_providers.dart';

class LandlordHomeBody extends ConsumerWidget {
  const LandlordHomeBody({
    super.key,
    required this.organizationId,
    required this.header,
  });

  final String organizationId;
  final Widget header;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(landlordHomeProvider(organizationId));
    Future<void> refresh() =>
        ref.refresh(landlordHomeProvider(organizationId).future);

    return RefreshIndicator(
      onRefresh: refresh,
      child: switch (home) {
        AsyncData(:final value) => ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            children: [
              header,
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: _Content(data: value),
              ),
            ],
          ),
        AsyncError(:final error) => ListView(
            children: [
              header,
              ErrorState(error: error, onRetry: refresh),
            ],
          ),
        _ => ListView(
            physics: const NeverScrollableScrollPhysics(),
            children: [header, const _Skeleton()],
          ),
      },
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.data});

  final LandlordHome data;

  @override
  Widget build(BuildContext context) {
    final o = data.overview;
    final f = data.financial;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TileRow(
          left: StatTile(
            label: 'Buildings',
            value: '${o.totalBuildings}',
            icon: Icons.apartment_outlined,
          ),
          right: StatTile(
            label: 'Active tenants',
            value: '${o.activeTenants}',
            icon: Icons.people_outline,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _TileRow(
          left: StatTile(
            label: 'On notice',
            value: '${o.tenantsOnNotice}',
            icon: Icons.event_busy_outlined,
          ),
          right: StatTile(
            label: 'Open issues',
            value: '${o.openIssues}',
            icon: Icons.build_outlined,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: 'This month · ${formatMonthYear(f.month, f.year)}'),
              _Line(label: 'Expected', child: MoneyText(f.expected)),
              _Line(label: 'Collected', child: MoneyText(f.collected)),
              _Line(
                label: 'Collection rate',
                child: Text('${f.collectionRate}%', style: AppTypography.label),
              ),
              _Line(label: 'Outstanding', child: MoneyText(f.outstanding)),
            ],
          ),
        ),
      ],
    );
  }
}

class _TileRow extends StatelessWidget {
  const _TileRow({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: right),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTypography.bodySecondary)),
          child,
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.sm),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: SkeletonBox(height: AppSpacing.xxxl + AppSpacing.lg, radius: AppRadii.card)),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: SkeletonBox(height: AppSpacing.xxxl + AppSpacing.lg, radius: AppRadii.card)),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: SkeletonBox(height: AppSpacing.xxxl + AppSpacing.lg, radius: AppRadii.card)),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: SkeletonBox(height: AppSpacing.xxxl + AppSpacing.lg, radius: AppRadii.card)),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          SkeletonBox(height: AppSpacing.xxxl * 2 + AppSpacing.lg, radius: AppRadii.card),
        ],
      ),
    );
  }
}
