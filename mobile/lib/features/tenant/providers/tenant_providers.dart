import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../data/shadow_rental_repository.dart';

final shadowRentalRepositoryProvider = Provider<ShadowRentalRepository>(
  (ref) => ApiShadowRentalRepository(ref.watch(apiClientProvider)),
);
