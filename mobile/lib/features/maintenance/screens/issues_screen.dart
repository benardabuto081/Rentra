import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/async_body.dart';
import '../../../core/widgets/display.dart';
import '../../../core/widgets/states.dart';
import '../../landlord/providers/landlord_providers.dart';
import '../../landlord/widgets/status_labels.dart';
import '../models/maintenance_request.dart';
import '../providers/maintenance_providers.dart';

/// Status filters, in the order they are offered. Null means all.
const _filters = <IssueStatus?>[
  IssueStatus.pending,
  IssueStatus.inProgress,
  IssueStatus.resolved,
  IssueStatus.cancelled,
  null,
];

class IssuesScreen extends ConsumerStatefulWidget {
  const IssuesScreen({super.key});

  @override
  ConsumerState<IssuesScreen> createState() => _IssuesScreenState();
}

class _IssuesScreenState extends ConsumerState<IssuesScreen> {
  IssueStatus? _filter = IssueStatus.pending;

  @override
  Widget build(BuildContext context) {
    final issues = ref.watch(issuesProvider);
    final index = ref.watch(portfolioIndexProvider).value;
    Future<void> refresh() => ref.refresh(issuesProvider.future);

    return Scaffold(
      appBar: AppBar(title: const Text('Operations')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              children: [
                for (final f in _filters) ...[
                  ChoiceChip(
                    label: Text(f?.label ?? 'All'),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: AsyncBody<List<MaintenanceRequest>>(
              value: issues,
              onRetry: refresh,
              data: (all) {
                final list = _filter == null
                    ? all
                    : all.where((i) => i.status == _filter).toList();
                if (list.isEmpty) return _empty(all.isEmpty);
                return RefreshIndicator(
                  onRefresh: refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, i) {
                      final issue = list[i];
                      final where = index?.unitLabel(issue.unitId, buildingId: issue.buildingId) ?? 'Unit';
                      final when = issue.createdAt == null
                          ? ''
                          : ' · ${formatDate(issue.createdAt!.toLocal())}';
                      return ListCard(
                        title: issue.title,
                        subtitle: '$where$when\n${issuePriority(issue.priority).$1}',
                        trailing: chipFor(issueStatus(issue.status)),
                        onTap: () => context.go(AppRoutes.issue(issue.id)),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(bool noneAtAll) {
    if (noneAtAll) {
      return const EmptyState(
        icon: Icons.build_outlined,
        title: 'No issues reported',
        message:
            'When a tenant reports a problem, it appears here so you can assign someone and follow it through to resolved.',
      );
    }
    return EmptyState(
      icon: Icons.check_circle_outline,
      title: _filter == IssueStatus.pending
          ? 'No open issues'
          : 'Nothing ${_filter?.label.toLowerCase()}',
      message: 'There are no issues with this status right now.',
      actionLabel: 'Show all issues',
      onAction: () => setState(() => _filter = null),
    );
  }
}
