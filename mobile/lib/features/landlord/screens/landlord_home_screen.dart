import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/greeting_header.dart';
import '../../../core/widgets/states.dart';
import '../../auth/providers/session_providers.dart';
import '../widgets/landlord_home_body.dart';

class LandlordHomeScreen extends ConsumerWidget {
  const LandlordHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();
    final header = GreetingHeader(
      firstName: user.firstName,
      initial: user.initial,
      subtitle: 'Property Dashboard',
    );
    return Scaffold(
      body: SafeArea(
        child: user.hasOrganization
            ? LandlordHomeBody(
                organizationId: user.organizationId!,
                header: header,
              )
            : ListView(
                children: [
                  header,
                  const EmptyState(
                    icon: Icons.apartment_outlined,
                    title: 'Your properties will appear here',
                    message:
                        'Your account is not linked to a property portfolio yet, so there is nothing to show.',
                  ),
                ],
              ),
      ),
    );
  }
}
