import 'package:rentra/features/auth/data/session_store.dart';
import 'package:rentra/features/auth/models/session.dart';
import 'package:rentra/features/tenant/data/shadow_rental_repository.dart';
import 'package:rentra/features/tenant/models/shadow_rental.dart';

class MemorySessionStore implements SessionStore {
  MemorySessionStore([this.session]);

  Session? session;

  @override
  Future<Session?> read() async => session;

  @override
  Future<void> save(Session s) async => session = s;

  @override
  Future<void> clear() async => session = null;
}

/// In-memory stand-in for the shadow rental backend.
class MemoryShadowRentals implements ShadowRentalRepository {
  final List<ShadowRental> rentals = [];
  int _next = 1;

  @override
  Future<List<ShadowRental>> list() async => rentals.reversed.toList();

  @override
  Future<ShadowRental> get(String id) async =>
      rentals.firstWhere((r) => r.id == id);

  @override
  Future<ShadowRental> create({
    String? nickname,
    String? address,
    required double rentAmount,
    BillingCycle? billingCycle,
    int? dueDayOfMonth,
    required PaymentDestinationType destinationType,
    required String destinationNumber,
    String? referenceName,
  }) async {
    final rental = ShadowRental(
      id: 's${_next++}',
      nickname: nickname,
      address: address,
      rentAmount: rentAmount,
      billingCycle: billingCycle ?? BillingCycle.monthly,
      dueDayOfMonth: dueDayOfMonth,
      destinationType: destinationType,
      destinationNumber: destinationNumber,
      referenceName: referenceName,
      status: ShadowRentalStatus.unverified,
    );
    rentals.add(rental);
    return rental;
  }

  @override
  Future<ShadowRental> update(
    String id, {
    String? nickname,
    String? address,
    double? rentAmount,
    BillingCycle? billingCycle,
    int? dueDayOfMonth,
    PaymentDestinationType? destinationType,
    String? destinationNumber,
    String? referenceName,
  }) async {
    final i = rentals.indexWhere((r) => r.id == id);
    final r = rentals[i];
    return rentals[i] = ShadowRental(
      id: r.id,
      nickname: nickname ?? r.nickname,
      address: address ?? r.address,
      rentAmount: rentAmount ?? r.rentAmount,
      billingCycle: billingCycle ?? r.billingCycle,
      dueDayOfMonth: dueDayOfMonth ?? r.dueDayOfMonth,
      destinationType: destinationType ?? r.destinationType,
      destinationNumber: destinationNumber ?? r.destinationNumber,
      referenceName: referenceName ?? r.referenceName,
      status: r.status,
    );
  }

  @override
  Future<ShadowRental> end(String id) async {
    final i = rentals.indexWhere((r) => r.id == id);
    final r = rentals[i];
    return rentals[i] = ShadowRental(
      id: r.id,
      nickname: r.nickname,
      rentAmount: r.rentAmount,
      billingCycle: r.billingCycle,
      dueDayOfMonth: r.dueDayOfMonth,
      destinationType: r.destinationType,
      destinationNumber: r.destinationNumber,
      status: ShadowRentalStatus.ended,
    );
  }
}
