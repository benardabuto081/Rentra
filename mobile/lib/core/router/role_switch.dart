import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/models/app_user.dart';
import '../../features/auth/providers/session_providers.dart';

/// Shows [tenant] to tenants and [manager] to landlords and caretakers.
class RoleSwitch extends ConsumerWidget {
  const RoleSwitch({super.key, required this.tenant, required this.manager});

  final Widget tenant;
  final Widget manager;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserProvider.select((u) => u?.role));
    if (role == null) return const SizedBox.shrink();
    return role == UserRole.tenant ? tenant : manager;
  }
}
