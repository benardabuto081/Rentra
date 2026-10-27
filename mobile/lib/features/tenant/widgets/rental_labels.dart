import 'package:flutter/material.dart';

import '../../../core/utils/dates.dart';
import '../models/rent_schedule.dart';
import '../models/shadow_rental.dart';

String destinationNumberLabel(PaymentDestinationType type) => switch (type) {
      PaymentDestinationType.paybill => 'Paybill Number',
      PaymentDestinationType.till => 'Till Number',
      PaymentDestinationType.bank => 'Account Number',
    };

String destinationMethodLabel(PaymentDestinationType type) => switch (type) {
      PaymentDestinationType.paybill => 'M-Pesa Paybill',
      PaymentDestinationType.till => 'M-Pesa Till (Buy Goods)',
      PaymentDestinationType.bank => 'Bank transfer',
    };

IconData destinationIcon(PaymentDestinationType type) => switch (type) {
      PaymentDestinationType.paybill ||
      PaymentDestinationType.till =>
        Icons.phone_android_outlined,
      PaymentDestinationType.bank => Icons.account_balance_outlined,
    };

String perCycle(BillingCycle cycle) => switch (cycle) {
      BillingCycle.daily => 'per day',
      BillingCycle.weekly => 'per week',
      BillingCycle.monthly => 'per month',
    };

/// A calm sentence about when rent is next due.
String dueSentence(ShadowRental rental, NextDue? due) {
  if (due == null) {
    return switch (rental.billingCycle) {
      BillingCycle.weekly => 'You pay rent every week.',
      _ => 'Add a due day to see when rent is next due.',
    };
  }
  final when = switch (due.daysAway) {
    0 => 'today',
    1 => 'tomorrow',
    final n => 'in $n days',
  };
  if (rental.billingCycle == BillingCycle.daily) {
    return 'You pay rent daily. Today’s rent is due $when.';
  }
  return 'Next rent is due $when, on ${formatDate(due.date)}.';
}

String scheduleSentence(ShadowRental rental) => switch (rental.billingCycle) {
      BillingCycle.daily => 'Every day',
      BillingCycle.weekly => 'Every week',
      BillingCycle.monthly => rental.dueDayOfMonth == null
          ? 'Every month'
          : 'The ${ordinal(rental.dueDayOfMonth!)} of every month',
    };
