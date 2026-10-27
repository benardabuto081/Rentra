import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/states.dart';
import '../models/shadow_rental.dart';
import '../providers/tenant_providers.dart';
import '../widgets/shadow_rental_form.dart';

class EditRentalScreen extends ConsumerWidget {
  const EditRentalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rental = ref.watch(activeShadowRentalProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit rental')),
      body: SafeArea(
        child: switch (rental) {
          AsyncData(value: final r?) => _EditForm(rental: r),
          AsyncData() => EmptyState(
              icon: Icons.home_outlined,
              title: 'No rental to edit',
              message:
                  'This rental has ended. You can add a new one from Home whenever you are ready.',
              actionLabel: 'Back to Home',
              onAction: () => context.go(AppRoutes.home),
            ),
          AsyncError(:final error) => ErrorState(
              error: error,
              onRetry: () => ref.invalidate(activeShadowRentalProvider),
            ),
          _ => const SkeletonList(),
        },
      ),
    );
  }
}

class _EditForm extends ConsumerStatefulWidget {
  const _EditForm({required this.rental});

  final ShadowRental rental;

  @override
  ConsumerState<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends ConsumerState<_EditForm> {
  bool _saving = false;
  bool _ending = false;
  String? _error;

  void _done(String message) {
    showSuccessSnackBar(context, message);
    ref.invalidate(activeShadowRentalProvider);
    context.canPop() ? context.pop() : context.go(AppRoutes.home);
  }

  Future<void> _save(ShadowRentalInput input) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(shadowRentalRepositoryProvider).update(
            widget.rental.id,
            nickname: input.nickname,
            address: input.address,
            rentAmount: input.rentAmount,
            billingCycle: input.billingCycle,
            dueDayOfMonth: input.dueDayOfMonth,
            destinationType: input.destinationType,
            destinationNumber: input.destinationNumber,
            referenceName: input.referenceName,
          );
      if (mounted) _done('Rental details saved.');
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _end() async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'End this rental?',
      message:
          'Use this when you have moved out. ${widget.rental.displayName} will no longer appear on Home. You can add a new rental at any time.',
      confirmLabel: 'End rental',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() {
      _ending = true;
      _error = null;
    });
    try {
      await ref.read(shadowRentalRepositoryProvider).end(widget.rental.id);
      if (mounted) _done('Your rental has ended.');
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _ending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShadowRentalForm(
      initial: widget.rental,
      submitLabel: 'Save changes',
      isSubmitting: _saving,
      error: _error,
      onSubmit: _save,
      footer: DestructiveButton(
        label: 'End this rental',
        icon: Icons.logout,
        isLoading: _ending,
        onPressed: _saving ? null : _end,
      ),
    );
  }
}
