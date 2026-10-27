import 'package:flutter_test/flutter_test.dart';
import 'package:rentra/features/tenant/models/rent_schedule.dart';
import 'package:rentra/features/tenant/models/shadow_rental.dart';
import 'package:rentra/features/tenant/widgets/rental_labels.dart';

ShadowRental _rental({
  BillingCycle cycle = BillingCycle.monthly,
  int? dueDay = 5,
}) =>
    ShadowRental(
      id: 's1',
      rentAmount: 7000,
      billingCycle: cycle,
      destinationType: PaymentDestinationType.paybill,
      destinationNumber: '522522',
      status: ShadowRentalStatus.unverified,
      dueDayOfMonth: dueDay,
    );

void main() {
  group('nextRentDue, monthly', () {
    test('later this month', () {
      final due = nextRentDue(_rental(dueDay: 5), DateTime(2026, 10, 1, 18, 30))!;
      expect(due.date, DateTime(2026, 10, 5));
      expect(due.daysAway, 4);
    });

    test('today counts as due today', () {
      final due = nextRentDue(_rental(dueDay: 27), DateTime(2026, 10, 27, 23, 59))!;
      expect(due.date, DateTime(2026, 10, 27));
      expect(due.daysAway, 0);
    });

    test('already passed moves to next month', () {
      final due = nextRentDue(_rental(dueDay: 5), DateTime(2026, 10, 27))!;
      expect(due.date, DateTime(2026, 11, 5));
      expect(due.daysAway, 9);
    });

    test('rolls over the year', () {
      final due = nextRentDue(_rental(dueDay: 1), DateTime(2026, 12, 15))!;
      expect(due.date, DateTime(2027, 1, 1));
      expect(due.daysAway, 17);
    });

    test('a day past the end of a short month uses its last day', () {
      final due = nextRentDue(_rental(dueDay: 31), DateTime(2027, 2, 10))!;
      expect(due.date, DateTime(2027, 2, 28));
      final leap = nextRentDue(_rental(dueDay: 30), DateTime(2028, 2, 1))!;
      expect(leap.date, DateTime(2028, 2, 29));
    });

    test('no due day gives no date', () {
      expect(nextRentDue(_rental(dueDay: null), DateTime(2026, 10, 1)), isNull);
    });
  });

  test('daily rent is due today', () {
    final due = nextRentDue(_rental(cycle: BillingCycle.daily), DateTime(2026, 10, 27, 9))!;
    expect(due.date, DateTime(2026, 10, 27));
    expect(due.daysAway, 0);
  });

  test('weekly rent has no date because no weekday is stored', () {
    expect(nextRentDue(_rental(cycle: BillingCycle.weekly), DateTime(2026, 10, 27)), isNull);
  });

  test('ordinal', () {
    expect(
      [1, 2, 3, 4, 11, 12, 13, 21, 22, 23, 28].map(ordinal),
      ['1st', '2nd', '3rd', '4th', '11th', '12th', '13th', '21st', '22nd', '23rd', '28th'],
    );
  });

  group('dueSentence is calm and specific', () {
    test('days away', () {
      final r = _rental();
      expect(
        dueSentence(r, NextDue(DateTime(2026, 11, 5), 9)),
        'Next rent is due in 9 days, on 5 Nov 2026.',
      );
      expect(
        dueSentence(r, NextDue(DateTime(2026, 11, 5), 1)),
        'Next rent is due tomorrow, on 5 Nov 2026.',
      );
      expect(
        dueSentence(r, NextDue(DateTime(2026, 11, 5), 0)),
        'Next rent is due today, on 5 Nov 2026.',
      );
    });

    test('weekly and daily', () {
      expect(
        dueSentence(_rental(cycle: BillingCycle.weekly), null),
        'You pay rent every week.',
      );
      expect(
        dueSentence(
          _rental(cycle: BillingCycle.daily),
          NextDue(DateTime(2026, 10, 27), 0),
        ),
        'You pay rent daily. Today’s rent is due today.',
      );
    });
  });

  test('ended and converted rentals are not active', () {
    ShadowRental withStatus(ShadowRentalStatus s) => ShadowRental(
          id: 's',
          rentAmount: 1,
          billingCycle: BillingCycle.monthly,
          destinationType: PaymentDestinationType.till,
          destinationNumber: '1',
          status: s,
        );
    expect(withStatus(ShadowRentalStatus.unverified).isActive, isTrue);
    expect(withStatus(ShadowRentalStatus.ended).isActive, isFalse);
    expect(withStatus(ShadowRentalStatus.converted).isActive, isFalse);
  });
}
