import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

class ShellTab {
  const ShellTab(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const tenantTabs = [
  ShellTab('Home', Icons.home_outlined, Icons.home),
  ShellTab('Payments', Icons.payments_outlined, Icons.payments),
  ShellTab('Household', Icons.people_outline, Icons.people),
  ShellTab('Activity', Icons.notifications_outlined, Icons.notifications),
  ShellTab('Account', Icons.person_outline, Icons.person),
];

const landlordTabs = [
  ShellTab('Dashboard', Icons.space_dashboard_outlined, Icons.space_dashboard),
  ShellTab('Properties', Icons.apartment_outlined, Icons.apartment),
  ShellTab('Payments', Icons.payments_outlined, Icons.payments),
  ShellTab('Operations', Icons.build_outlined, Icons.build),
  ShellTab('Account', Icons.person_outline, Icons.person),
];

class MainShell extends StatelessWidget {
  const MainShell({
    super.key,
    required this.navigationShell,
    required this.tabs,
  });

  final StatefulNavigationShell navigationShell;
  final List<ShellTab> tabs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
          destinations: [
            for (final tab in tabs)
              NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.selectedIcon),
                label: tab.label,
              ),
          ],
        ),
      ),
    );
  }
}
