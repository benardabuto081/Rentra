import 'package:flutter/material.dart';

import '../../../core/widgets/states.dart';

class HouseholdScreen extends StatelessWidget {
  const HouseholdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Household')),
      body: const EmptyState(
        icon: Icons.people_outline,
        title: 'Households are coming soon',
        message:
            'You will be able to share your home with the people you live with, see contributions and stay in sync without chasing anyone. There is nothing you need to do for now.',
      ),
    );
  }
}
