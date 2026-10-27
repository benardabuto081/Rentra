import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../landlord/providers/landlord_providers.dart';
import '../data/payment_repository.dart';
import '../models/payment.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => ApiPaymentRepository(ref.watch(apiClientProvider)),
);

typedef MonthKey = ({int month, int year});

String _org(Ref ref) {
  final orgId = ref.watch(currentOrgIdProvider);
  if (orgId == null) throw StateError('No portfolio for this account');
  return orgId;
}

final monthPaymentsProvider = FutureProvider.family<List<Payment>, MonthKey>(
  (ref, key) => ref
      .watch(paymentRepositoryProvider)
      .forMonth(_org(ref), month: key.month, year: key.year),
);

final monthStatsProvider = FutureProvider.family<PaymentStats, MonthKey>(
  (ref, key) => ref
      .watch(paymentRepositoryProvider)
      .stats(_org(ref), month: key.month, year: key.year),
);

final arrearsProvider = FutureProvider<List<Payment>>(
  (ref) => ref.watch(paymentRepositoryProvider).arrears(_org(ref)),
);

final paymentProvider = FutureProvider.family<Payment, String>(
  (ref, id) => ref.watch(paymentRepositoryProvider).get(_org(ref), id),
);

final tenantPaymentsProvider = FutureProvider.family<List<Payment>, String>(
  (ref, tenancyId) =>
      ref.watch(paymentRepositoryProvider).forTenant(_org(ref), tenancyId),
);

/// Refreshes every payment view and the dashboard totals.
void invalidatePayments(WidgetRef ref) {
  ref.invalidate(monthPaymentsProvider);
  ref.invalidate(monthStatsProvider);
  ref.invalidate(arrearsProvider);
  ref.invalidate(paymentProvider);
  ref.invalidate(tenantPaymentsProvider);
  ref.invalidate(dashboardProvider);
}
