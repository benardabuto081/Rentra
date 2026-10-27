import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../auth/providers/session_providers.dart';
import '../data/landlord_repositories.dart';
import '../models/building.dart';
import '../models/dashboard.dart';
import '../models/organization.dart';
import '../models/tenancy.dart';
import '../models/unit.dart';

final organizationRepositoryProvider = Provider<OrganizationRepository>(
  (ref) => ApiOrganizationRepository(ref.watch(apiClientProvider)),
);

final buildingRepositoryProvider = Provider<BuildingRepository>(
  (ref) => ApiBuildingRepository(ref.watch(apiClientProvider)),
);

final unitRepositoryProvider = Provider<UnitRepository>(
  (ref) => ApiUnitRepository(ref.watch(apiClientProvider)),
);

final tenancyRepositoryProvider = Provider<TenancyRepository>(
  (ref) => ApiTenancyRepository(ref.watch(apiClientProvider)),
);

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => ApiDashboardRepository(ref.watch(apiClientProvider)),
);

final passkeyRepositoryProvider = Provider<PasskeyRepository>(
  (ref) => ApiPasskeyRepository(ref.watch(apiClientProvider)),
);

/// The signed-in landlord's portfolio id.
final currentOrgIdProvider = Provider<String?>((ref) {
  final session = ref.watch(sessionControllerProvider).value;
  return session?.organization?.id ?? session?.user.organizationId;
});

String _requireOrg(Ref ref) {
  final orgId = ref.watch(currentOrgIdProvider);
  if (orgId == null) throw StateError('No portfolio for this account');
  return orgId;
}

final organizationProvider = FutureProvider<Organization>(
  (ref) => ref.watch(organizationRepositoryProvider).get(_requireOrg(ref)),
);

final buildingsProvider = FutureProvider<List<Building>>(
  (ref) => ref.watch(buildingRepositoryProvider).list(_requireOrg(ref)),
);

final buildingProvider = FutureProvider.family<Building, String>(
  (ref, buildingId) =>
      ref.watch(buildingRepositoryProvider).get(_requireOrg(ref), buildingId),
);

final unitsProvider = FutureProvider.family<List<Unit>, String>(
  (ref, buildingId) =>
      ref.watch(unitRepositoryProvider).list(_requireOrg(ref), buildingId),
);

typedef UnitKey = ({String buildingId, String unitId});

final unitProvider = FutureProvider.family<Unit, UnitKey>(
  (ref, key) => ref
      .watch(unitRepositoryProvider)
      .get(_requireOrg(ref), key.buildingId, key.unitId),
);

/// Tenancies that are still live: active or serving notice.
final currentTenanciesProvider = FutureProvider<List<Tenancy>>((ref) async {
  final all =
      await ref.watch(tenancyRepositoryProvider).list(_requireOrg(ref));
  return all.where((t) => t.status != TenancyStatus.vacated).toList();
});

final tenancyProvider = FutureProvider.family<Tenancy, String>(
  (ref, id) => ref.watch(tenancyRepositoryProvider).get(_requireOrg(ref), id),
);

final buildingSummariesProvider = FutureProvider<List<BuildingSummary>>(
  (ref) => ref.watch(dashboardRepositoryProvider).buildings(_requireOrg(ref)),
);

/// Buildings and units by id, so records that only carry ids can be shown
/// with human names.
class PortfolioIndex {
  const PortfolioIndex({required this.buildings, required this.units});

  final Map<String, Building> buildings;
  final Map<String, Unit> units;

  /// "A1 · Kamau Court".
  String unitLabel(String unitId, {String? buildingId}) {
    final unit = units[unitId];
    final building = buildings[unit?.buildingId ?? buildingId];
    return [unit?.name ?? 'Unit', if (building != null) building.name]
        .join(' · ');
  }
}

final portfolioIndexProvider = FutureProvider<PortfolioIndex>((ref) async {
  final buildings = await ref.watch(buildingsProvider.future);
  final unitLists = await Future.wait(
    buildings.map((b) => ref.watch(unitsProvider(b.id).future)),
  );
  return PortfolioIndex(
    buildings: {for (final b in buildings) b.id: b},
    units: {for (final list in unitLists) for (final u in list) u.id: u},
  );
});

typedef DashboardData = ({
  DashboardOverview overview,
  FinancialSummary financial,
  List<BuildingSummary> buildings,
});

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final orgId = _requireOrg(ref);
  final repo = ref.watch(dashboardRepositoryProvider);
  final now = DateTime.now();
  final results = await (
    repo.overview(orgId),
    repo.financial(orgId, month: now.month, year: now.year),
    repo.buildings(orgId),
  ).wait;
  return (
    overview: results.$1,
    financial: results.$2,
    buildings: results.$3,
  );
});

/// Refreshes everything that depends on buildings, units or tenancies.
void invalidatePortfolio(WidgetRef ref) {
  ref.invalidate(buildingsProvider);
  ref.invalidate(buildingProvider);
  ref.invalidate(unitsProvider);
  ref.invalidate(unitProvider);
  ref.invalidate(currentTenanciesProvider);
  ref.invalidate(tenancyProvider);
  ref.invalidate(buildingSummariesProvider);
  ref.invalidate(portfolioIndexProvider);
  ref.invalidate(dashboardProvider);
}

