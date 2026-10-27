import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentra/core/router/app_routes.dart';

import 'helpers/app_harness.dart';
import 'helpers/fake_backend.dart';

/// Visits every screen on a 360x640 phone at 1.3x text and checks that
/// nothing overflows, every tap target is at least 48dp, and every tappable
/// control has a label.
void main() {
  const size = Size(360, 640);
  const scale = 1.3;

  Future<void> check(WidgetTester tester, String route) async {
    expect(tester.takeException(), isNull, reason: 'layout on $route');
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline), reason: route);
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline), reason: route);
    await expectLater(tester, meetsGuideline(textContrastGuideline), reason: route);
  }

  testWidgets('signed-out and onboarding screens', (tester) async {
    final handle = tester.ensureSemantics();
    final c = await pumpRentra(tester, backend: FakeBackend(), logicalSize: size, textScale: scale);
    for (final route in [
      AppRoutes.welcome,
      AppRoutes.login,
      AppRoutes.createAccount,
      AppRoutes.verifyEmail,
      AppRoutes.privacy,
      AppRoutes.role,
    ]) {
      await goTo(tester, c, route);
      await check(tester, route);
    }
    handle.dispose();
  });

  testWidgets('independent tenant screens', (tester) async {
    final handle = tester.ensureSemantics();
    final backend = FakeBackend()..addShadowRental();
    final c = await pumpRentra(
      tester,
      backend: backend,
      session: tenantSession,
      logicalSize: size,
      textScale: scale,
    );
    for (final route in [
      AppRoutes.home,
      AppRoutes.payments,
      AppRoutes.household,
      AppRoutes.activity,
      AppRoutes.account,
      AppRoutes.rentalEdit,
      AppRoutes.rentalSetup,
      AppRoutes.tenantSetup,
      AppRoutes.tour,
    ]) {
      await goTo(tester, c, route);
      await check(tester, route);
    }
    handle.dispose();
  });

  testWidgets('tenant without a rental', (tester) async {
    final handle = tester.ensureSemantics();
    final c = await pumpRentra(
      tester,
      backend: FakeBackend(),
      session: tenantSession,
      logicalSize: size,
      textScale: scale,
    );
    for (final route in [AppRoutes.home, AppRoutes.payments]) {
      await goTo(tester, c, route);
      await check(tester, route);
    }
    handle.dispose();
  });

  testWidgets('landlord screens', (tester) async {
    final handle = tester.ensureSemantics();
    final backend = FakeBackend();
    final ids = seedPortfolio(backend);
    final c = await pumpRentra(
      tester,
      backend: backend,
      session: landlordSession,
      logicalSize: size,
      textScale: scale,
    );
    for (final route in [
      AppRoutes.landlordDashboard,
      AppRoutes.landlordProperties,
      AppRoutes.building(ids.building),
      AppRoutes.unit(ids.building, ids.vacant),
      AppRoutes.unit(ids.building, ids.occupied),
      AppRoutes.landlordTenants,
      AppRoutes.tenancy(ids.tenancy),
      AppRoutes.landlordPayments,
      AppRoutes.payment(ids.payment),
      AppRoutes.landlordOperations,
      AppRoutes.issue(ids.issue),
      AppRoutes.landlordAccount,
      AppRoutes.newBuilding,
      AppRoutes.editBuilding(ids.building),
      AppRoutes.addUnits(ids.building, afterNewBuilding: true),
      AppRoutes.editUnit(ids.building, ids.vacant),
      AppRoutes.inviteTenant(ids.building, ids.vacant),
      AppRoutes.recordPayment(tenancyId: ids.tenancy),
      AppRoutes.editPortfolio,
      AppRoutes.ownerSetup,
    ]) {
      await goTo(tester, c, route);
      await check(tester, route);
    }
    handle.dispose();
  });

  testWidgets('empty landlord', (tester) async {
    final handle = tester.ensureSemantics();
    final c = await pumpRentra(
      tester,
      backend: FakeBackend(),
      session: landlordSession,
      logicalSize: size,
      textScale: scale,
    );
    for (final route in [
      AppRoutes.landlordDashboard,
      AppRoutes.landlordProperties,
      AppRoutes.landlordTenants,
      AppRoutes.landlordPayments,
      AppRoutes.landlordOperations,
      AppRoutes.recordPayment(),
    ]) {
      await goTo(tester, c, route);
      await check(tester, route);
    }
    handle.dispose();
  });
}
