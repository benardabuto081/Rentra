import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/copy_row.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/states.dart';
import '../../auth/providers/session_providers.dart';
import '../models/passkey.dart';
import '../providers/landlord_providers.dart';

/// Creates a passkey a new tenant uses to join a vacant unit.
class InviteTenantScreen extends ConsumerStatefulWidget {
  const InviteTenantScreen({
    super.key,
    required this.buildingId,
    required this.unitId,
  });

  final String buildingId;
  final String unitId;

  @override
  ConsumerState<InviteTenantScreen> createState() => _InviteTenantScreenState();
}

class _InviteTenantScreenState extends ConsumerState<InviteTenantScreen> {
  static const _expiryChoices = [7, 14, 30];

  int _days = 7;
  bool _loading = false;
  String? _error;
  Passkey? _passkey;

  Future<void> _create() async {
    final orgId = ref.read(currentOrgIdProvider);
    final userId = ref.read(currentUserProvider)?.id;
    if (orgId == null || userId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final passkey = await ref.read(passkeyRepositoryProvider).generate(
            unitId: widget.unitId,
            organizationId: orgId,
            generatedBy: userId,
            expiresInDays: _days,
          );
      if (!mounted) return;
      setState(() => _passkey = passkey);
      showSuccessSnackBar(context, 'Passkey created.');
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unitName = ref
        .watch(unitProvider((buildingId: widget.buildingId, unitId: widget.unitId)))
        .value
        ?.name;
    final passkey = _passkey;
    return Scaffold(
      appBar: AppBar(title: Text(unitName == null ? 'Invite a tenant' : 'Invite a tenant to $unitName')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: passkey == null ? _setup() : _result(passkey),
        ),
      ),
    );
  }

  List<Widget> _setup() => [
        const Text(
          'Your tenant enters this passkey when they set up Rentra, which links them to this unit.',
          style: AppTypography.body,
        ),
        const SizedBox(height: AppSpacing.md),
        if (_error != null) ...[
          InlineMessage(message: _error!),
          const SizedBox(height: AppSpacing.sm),
        ],
        const Text('How long should it work?', style: AppTypography.label),
        const SizedBox(height: AppSpacing.xs),
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: [
            for (final d in _expiryChoices)
              ButtonSegment(value: d, label: Text('$d days')),
          ],
          selected: {_days},
          onSelectionChanged: (s) => setState(() => _days = s.first),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Creating a new passkey replaces any earlier one for this unit.',
          style: AppTypography.caption,
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: 'Create passkey',
          isLoading: _loading,
          onPressed: _create,
        ),
      ];

  List<Widget> _result(Passkey passkey) => [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CopyRow(
                label: 'Passkey',
                value: passkey.code,
                valueStyle: AppTypography.display.copyWith(letterSpacing: 2),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                passkey.expiresAt == null
                    ? 'This passkey does not expire.'
                    : 'Works until ${formatDate(passkey.expiresAt!.toLocal())}.',
                style: AppTypography.bodySecondary,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'Share it in person or by message. Anyone with this passkey can join this unit, so give it only to your tenant.',
          style: AppTypography.body,
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(label: 'Done', onPressed: () => context.pop()),
      ];
}
