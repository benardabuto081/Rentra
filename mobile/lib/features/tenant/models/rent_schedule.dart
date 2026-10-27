import 'dart:math';

import 'shadow_rental.dart';

class NextDue {
  const NextDue(this.date, this.daysAway);

  final DateTime date;
  final int daysAway;
}

/// When rent is next due, counted from [now] by calendar day.
///
/// Monthly rent falls on [ShadowRental.dueDayOfMonth], moved to the last day
/// of short months. Daily rent is due today. Weekly rent returns null because
/// the backend stores no weekday for it.
NextDue? nextRentDue(ShadowRental rental, DateTime now) {
  final today = DateTime.utc(now.year, now.month, now.day);
  switch (rental.billingCycle) {
    case BillingCycle.daily:
      return NextDue(DateTime(now.year, now.month, now.day), 0);
    case BillingCycle.weekly:
      return null;
    case BillingCycle.monthly:
      final day = rental.dueDayOfMonth;
      if (day == null || day < 1) return null;
      var due = _dayInMonth(today.year, today.month, day);
      if (due.isBefore(today)) due = _dayInMonth(today.year, today.month + 1, day);
      return NextDue(
        DateTime(due.year, due.month, due.day),
        due.difference(today).inDays,
      );
  }
}

DateTime _dayInMonth(int year, int month, int day) {
  final lastDay = DateTime.utc(year, month + 1, 0).day;
  return DateTime.utc(year, month, min(day, lastDay));
}

/// "1st", "2nd", "23rd".
String ordinal(int n) {
  final lastTwo = n % 100;
  if (lastTwo >= 11 && lastTwo <= 13) return '${n}th';
  return switch (n % 10) {
    1 => '${n}st',
    2 => '${n}nd',
    3 => '${n}rd',
    _ => '${n}th',
  };
}
