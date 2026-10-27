import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentra/core/router/app_router.dart';
import 'package:rentra/core/router/app_routes.dart';

import '../helpers/app_harness.dart';
import '../helpers/fake_backend.dart';

void main() {
  List<String> tabLabels(WidgetTester tester) => tester
      .widget<NavigationBar>(find.byType(NavigationBar))
      .destinations
      .map((d) => (d as NavigationDestination).label)
      .toList();

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(label),
    ));
    await tester.pumpAndSettle();
  }

  int selected(WidgetTester tester) =>
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

  testWidgets('tenant shell has the tenant tabs and each opens its screen',
      (tester) async {
    final backend = FakeBackend()..addShadowRental();
    final c = await pumpRentra(tester, backend: backend, session: tenantSession);

    expect(tabLabels(tester), ['Home', 'Payments', 'Household', 'Activity', 'Account']);
    expect(c.read(routerProvider).state.matchedLocation, AppRoutes.home);
    expect(find.text('Bedsitter in Kasarani'), findsOneWidget);

    const expectations = {
      'Payments': 'How to pay',
      'Household': 'Households are coming soon',
      'Activity': 'Nothing new yet',
      'Account': 'Sign Out',
    };
    var index = 1;
    for (final entry in expectations.entries) {
      await openTab(tester, entry.key);
      expect(find.text(entry.value), findsOneWidget, reason: entry.key);
      expect(selected(tester), index++, reason: entry.key);
    }
  });

  testWidgets('tenant shell keeps each tab where it was', (tester) async {
    final backend = FakeBackend()..addShadowRental();
    await pumpRentra(tester, backend: backend, session: tenantSession);

    await openTab(tester, 'Account');
    await openTab(tester, 'Home');
    expect(selected(tester), 0);
    expect(find.text('Bedsitter in Kasarani'), findsOneWidget);
  });

  testWidgets('landlord shell has the landlord tabs and each opens its screen',
      (tester) async {
    final backend = FakeBackend();
    seedPortfolio(backend);
    final c = await pumpRentra(tester, backend: backend, session: landlordSession);

    expect(tabLabels(tester), ['Dashboard', 'Properties', 'Payments', 'Operations', 'Account']);
    expect(c.read(routerProvider).state.matchedLocation, AppRoutes.landlordDashboard);
    expect(find.text('What needs my attention today?'), findsOneWidget);

    const expectations = {
      'Properties': 'My Properties',
      'Payments': 'Record payment',
      'Operations': 'Kitchen sink is leaking under the cabinet',
      'Account': 'Edit details',
    };
    var index = 1;
    for (final entry in expectations.entries) {
      await openTab(tester, entry.key);
      expect(find.text(entry.value), findsWidgets, reason: entry.key);
      expect(selected(tester), index++, reason: entry.key);
    }
  });

  testWidgets('landlord tab keeps its place inside Properties', (tester) async {
    final backend = FakeBackend();
    seedPortfolio(backend);
    final c = await pumpRentra(tester, backend: backend, session: landlordSession);

    await openTab(tester, 'Properties');
    await tester.tap(find.text('Kamau Court Apartments, Kasarani'));
    await tester.pumpAndSettle();
    await openTab(tester, 'Payments');
    await openTab(tester, 'Properties');
    expect(c.read(routerProvider).state.matchedLocation, startsWith('${AppRoutes.landlordProperties}/'));

    await openTab(tester, 'Properties');
    expect(c.read(routerProvider).state.matchedLocation, AppRoutes.landlordProperties);
  });

  testWidgets('each role is kept out of the other shell', (tester) async {
    final c = await pumpRentra(tester, backend: FakeBackend(), session: tenantSession);
    await goTo(tester, c, AppRoutes.landlordDashboard);
    expect(tabLabels(tester).first, 'Home');
  });
}
