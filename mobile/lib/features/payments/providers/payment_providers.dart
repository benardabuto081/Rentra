import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../data/payment_repository.dart';
import '../models/payment.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => ApiPaymentRepository(ref.watch(apiClientProvider)),
);

final paymentHistoryProvider =
    FutureProvider.family<List<Payment>, String>(
  (ref, orgId) => ref.watch(paymentRepositoryProvider).list(orgId),
);

final paymentArrearsProvider =
    FutureProvider.family<List<Payment>, String>(
  (ref, orgId) => ref.watch(paymentRepositoryProvider).arrears(orgId),
);
