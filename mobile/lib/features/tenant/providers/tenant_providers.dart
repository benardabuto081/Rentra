import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../auth/providers/session_providers.dart';
import '../data/shadow_rental_repository.dart';
import '../models/shadow_rental.dart';

final shadowRentalRepositoryProvider = Provider<ShadowRentalRepository>(
  (ref) => ApiShadowRentalRepository(ref.watch(apiClientProvider)),
);

/// The rental an independent tenant is currently tracking, newest first.
final activeShadowRentalProvider = FutureProvider<ShadowRental?>((ref) async {
  ref.watch(currentUserProvider.select((user) => user?.id));
  final rentals = await ref.watch(shadowRentalRepositoryProvider).list();
  for (final rental in rentals) {
    if (rental.isActive) return rental;
  }
  return null;
});
