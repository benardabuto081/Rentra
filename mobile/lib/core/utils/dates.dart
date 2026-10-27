import 'package:intl/intl.dart';

final _display = DateFormat('d MMM yyyy', 'en_US');
final _monthYear = DateFormat('MMMM yyyy', 'en_US');
final _shortMonthYear = DateFormat('MMM yyyy', 'en_US');
final _iso = DateFormat('yyyy-MM-dd', 'en_US');
final _monthName = DateFormat('MMMM', 'en_US');

String formatDate(DateTime date) => _display.format(date);

String formatMonthYear(int month, int year) =>
    _monthYear.format(DateTime(year, month));

String formatMonthName(int month) => _monthName.format(DateTime(2000, month));

String formatShortMonthYear(int month, int year) =>
    _shortMonthYear.format(DateTime(year, month));

/// `yyyy-MM-dd`, the date-only form the backend accepts.
String toIsoDate(DateTime date) => _iso.format(date);
