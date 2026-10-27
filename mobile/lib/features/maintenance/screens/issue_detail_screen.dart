import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_body.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/display.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/sheets.dart';
import '../../../core/widgets/text_fields.dart';
import '../../landlord/providers/landlord_providers.dart';
import '../../landlord/widgets/status_labels.dart';
import '../models/maintenance_request.dart';
import '../providers/maintenance_providers.dart';

class IssueDetailScreen extends ConsumerWidget {
  const IssueDetailScreen({super.key, required this.issueId});

  final String issueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issue = ref.watch(issueProvider(issueId));
    final index = ref.watch(portfolioIndexProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Issue')),
      body: AsyncBody<MaintenanceRequest>(
        value: issue,
        onRetry: () => ref.invalidate(issueProvider(issueId)),
        data: (i) => RefreshIndicator(
          onRefresh: () => ref.refresh(issueProvider(issueId).future),
          child: _Body(
            issue: i,
            where: index?.unitLabel(i.unitId, buildingId: i.buildingId) ?? 'Unit',
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.issue, required this.where});

  final MaintenanceRequest issue;
  final String where;

  bool get _open =>
      issue.status == IssueStatus.pending || issue.status == IssueStatus.inProgress;

  void _after(BuildContext context, WidgetRef ref, bool done, String message) {
    if (!done || !context.mounted) return;
    invalidateIssues(ref);
    showSuccessSnackBar(context, message);
  }

  Future<void> _assign(BuildContext context, WidgetRef ref) async {
    String? name;
    final done = await showTextSheet(
      context: context,
      title: 'Who is handling this?',
      message: 'The issue will show as in progress.',
      label: 'Name',
      hint: 'e.g. Juma the plumber',
      initial: issue.assignedTo,
      requiredMessage: 'Enter who is handling this.',
      submitLabel: 'Assign',
      onSubmit: (value) async {
        await ref
            .read(maintenanceRepositoryProvider)
            .assign(issue.organizationId, issue.id, value);
        name = value;
      },
    );
    if (context.mounted) _after(context, ref, done, 'Assigned to $name.');
  }

  Future<void> _resolve(BuildContext context, WidgetRef ref) async {
    final done = await showAppBottomSheet<bool>(
      context: context,
      builder: (_) => _ResolveSheet(issue: issue),
    );
    if (context.mounted) _after(context, ref, done ?? false, 'Issue resolved.');
  }

  Future<void> _priority(BuildContext context, WidgetRef ref) async {
    final done = await showChoiceSheet<IssuePriority>(
      context: context,
      title: 'Change priority',
      selected: issue.priority,
      options: [
        for (final p in IssuePriority.values) DropdownOption(p, p.label),
      ],
      submitLabel: 'Save priority',
      onSubmit: (p) => ref
          .read(maintenanceRepositoryProvider)
          .setPriority(issue.organizationId, issue.id, p),
    );
    if (context.mounted) _after(context, ref, done, 'Priority updated.');
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Cancel this issue?',
      message:
          'Use this if it was reported by mistake or is no longer needed. It stays in your records as cancelled.',
      confirmLabel: 'Cancel issue',
      cancelLabel: 'Keep it',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await ref
          .read(maintenanceRepositoryProvider)
          .cancel(issue.organizationId, issue.id);
      if (context.mounted) _after(context, ref, true, 'Issue cancelled.');
    } on AppException catch (e) {
      if (context.mounted) showErrorSnackBar(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i = issue;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.sm),
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(i.title, style: AppTypography.subheading),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  chipFor(issueStatus(i.status)),
                  chipFor(issuePriority(i.priority)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(i.description, style: AppTypography.body),
              const SizedBox(height: AppSpacing.sm),
              DetailRow(label: 'Where', value: where),
              DetailRow(label: 'Category', value: i.category.label),
              if (i.createdAt != null)
                DetailRow(label: 'Reported', value: formatDate(i.createdAt!.toLocal())),
              if (i.assignedTo?.trim().isNotEmpty == true)
                DetailRow(label: 'Handled by', value: i.assignedTo!),
              if (i.resolvedAt != null)
                DetailRow(label: 'Resolved', value: formatDate(i.resolvedAt!.toLocal())),
              if (i.cost != null) DetailRow(label: 'Cost', value: formatMoney(i.cost!)),
              if (i.resolutionNotes?.trim().isNotEmpty == true)
                DetailRow(label: 'What was done', value: i.resolutionNotes!),
            ],
          ),
        ),
        if (_open) ...[
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(label: 'Mark resolved', onPressed: () => _resolve(context, ref)),
          const SizedBox(height: AppSpacing.xs),
          SecondaryButton(
            label: i.assignedTo == null ? 'Assign someone' : 'Change who is handling it',
            onPressed: () => _assign(context, ref),
          ),
          const SizedBox(height: AppSpacing.xs),
          SecondaryButton(label: 'Change priority', onPressed: () => _priority(context, ref)),
          const SizedBox(height: AppSpacing.xs),
          DestructiveButton(label: 'Cancel issue', onPressed: () => _cancel(context, ref)),
        ],
      ],
    );
  }
}

class _ResolveSheet extends ConsumerStatefulWidget {
  const _ResolveSheet({required this.issue});

  final MaintenanceRequest issue;

  @override
  ConsumerState<_ResolveSheet> createState() => _ResolveSheetState();
}

class _ResolveSheetState extends ConsumerState<_ResolveSheet> {
  final _notes = TextEditingController();
  final _cost = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    _cost.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SheetFrame(
      title: 'Mark as resolved',
      message: 'A short note helps if the same problem comes back.',
      submitLabel: 'Mark resolved',
      fields: [
        AppTextField(
          label: 'What was done',
          controller: _notes,
          hint: 'e.g. Replaced the kitchen tap washer',
          maxLines: 3,
          textInputAction: TextInputAction.newline,
          textCapitalization: TextCapitalization.sentences,
          validator: Validators.required('Please describe what was done.'),
        ),
        const SizedBox(height: AppSpacing.sm),
        MoneyField(
          label: 'Cost (optional)',
          controller: _cost,
          validator: (v) => (v == null || v.trim().isEmpty) ? null : Validators.amount(v),
        ),
      ],
      onSubmit: () {
        final cost = _cost.text.trim();
        return ref.read(maintenanceRepositoryProvider).resolve(
              widget.issue.organizationId,
              widget.issue.id,
              resolutionNotes: _notes.text.trim(),
              cost: cost.isEmpty ? null : parseMoney(cost),
            );
      },
    );
  }
}
