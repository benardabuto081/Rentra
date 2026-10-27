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
        title: 'No household yet',
        message:
            'Households will let you share rental awareness with the people you live with.',
      ),
    );
  }
}
