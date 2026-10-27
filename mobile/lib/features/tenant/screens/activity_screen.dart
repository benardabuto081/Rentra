import 'package:flutter/material.dart';

import '../../../core/widgets/states.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: const EmptyState(
        icon: Icons.notifications_none_outlined,
        title: 'No activity yet',
        message:
            'Your activity timeline will appear here — payments, maintenance updates, household activity, and more.',
      ),
    );
  }
}
