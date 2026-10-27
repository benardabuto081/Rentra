import 'package:flutter_test/flutter_test.dart';
import 'package:rentra/core/utils/money.dart';

void main() {
  group('parseMoney', () {
    test('accepts TypeORM decimal strings', () {
      expect(parseMoney('12500.00'), 12500);
      expect(parseMoney('7000.50'), 7000.5);
      expect(parseMoney(' 300 '), 300);
    });

    test('accepts numbers', () {
      expect(parseMoney(12500), 12500);
      expect(parseMoney(99.9), 99.9);
    });

    test('accepts thousands separators', () {
      expect(parseMoney('12,500'), 12500);
    });

    test('rejects anything else', () {
      expect(() => parseMoney(null), throwsFormatException);
      expect(() => parseMoney('abc'), throwsFormatException);
      expect(() => parseMoney(true), throwsFormatException);
      expect(() => parseMoney(double.nan), throwsFormatException);
    });
  });

  group('formatMoney', () {
    test('drops decimals for whole amounts', () {
      expect(formatMoney(12500), 'KES 12,500');
      expect(formatMoney(12500.0), 'KES 12,500');
      expect(formatMoney(0), 'KES 0');
      expect(formatMoney(1250000), 'KES 1,250,000');
    });

    test('keeps two decimals when there are cents', () {
      expect(formatMoney(12500.5), 'KES 12,500.50');
      expect(formatMoney(99.99), 'KES 99.99');
    });

    test('rounds floating point noise', () {
      expect(formatMoney(0.1 + 0.2), 'KES 0.30');
      expect(formatMoney(1000.004), 'KES 1,000');
    });
  });
}
