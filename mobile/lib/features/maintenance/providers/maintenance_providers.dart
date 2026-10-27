import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../data/maintenance_repository.dart';

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>(
  (ref) => ApiMaintenanceRepository(ref.watch(apiClientProvider)),
);
