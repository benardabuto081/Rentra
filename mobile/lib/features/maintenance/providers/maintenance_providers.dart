import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../landlord/providers/landlord_providers.dart';
import '../data/maintenance_repository.dart';
import '../models/maintenance_request.dart';

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>(
  (ref) => ApiMaintenanceRepository(ref.watch(apiClientProvider)),
);

String _org(Ref ref) {
  final orgId = ref.watch(currentOrgIdProvider);
  if (orgId == null) throw StateError('No portfolio for this account');
  return orgId;
}

final issuesProvider = FutureProvider<List<MaintenanceRequest>>(
  (ref) => ref.watch(maintenanceRepositoryProvider).list(_org(ref)),
);

final issueProvider = FutureProvider.family<MaintenanceRequest, String>(
  (ref, id) => ref.watch(maintenanceRepositoryProvider).get(_org(ref), id),
);

void invalidateIssues(WidgetRef ref) {
  ref.invalidate(issuesProvider);
  ref.invalidate(issueProvider);
  ref.invalidate(dashboardProvider);
}
