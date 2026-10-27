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
        title: 'Nothing new yet',
        message:
            'Updates about your rent and your home will gather here, so nothing important slips past you. There is nothing you need to do for now.',
      ),
    );
  }
}
