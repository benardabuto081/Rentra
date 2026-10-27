import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../data/landlord_repositories.dart';
import '../models/dashboard.dart';

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

typedef LandlordHome = ({DashboardOverview overview, FinancialSummary financial});

/// Overview plus this month's money, loaded together for the landlord home.
final landlordHomeProvider =
    FutureProvider.family<LandlordHome, String>((ref, orgId) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  final now = DateTime.now();
  final results = await (
    repo.overview(orgId),
    repo.financial(orgId, month: now.month, year: now.year),
  ).wait;
  return (overview: results.$1, financial: results.$2);
});
