import 'package:finance_mvp/services/finance/currency_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('snaps to the given number of decimal places', () {
    expect(quantizeTo(2.7397260273972603, 2), 2.74);
    expect(quantizeTo(2.7397260273972603, 8), 2.73972603);
    expect(quantizeTo(100.0, 0), 100);
  });

  test('zero decimal places rounds to a whole minor unit', () {
    // JPY-style: no fractional yen exist.
    expect(quantizeTo(1234.6, 0), 1235);
    expect(quantizeTo(1234.4, 0), 1234);
    expect(quantizeTo(0.5, 0), 1);
  });

  test('leaves no residue behind after a division', () {
    // The real contract: a converted amount lands exactly on the currency's
    // minor unit, so sums of it don't drift.
    expect(quantizeTo(100 / 36.5, 2), 2.74);
    expect(quantizeTo(0.1 + 0.2, 2), 0.3);
    expect(quantizeTo(0.1 + 0.2, 8), 0.30000000);
  });

  test('rounds a clean halfway case up, symmetrically for negatives', () {
    // 2.675 * 100 is exactly 267.5 in binary, so the tie is reachable. Decimal
    // halves that aren't (1.005 * 100 is 100.49999999999999) resolve to
    // whichever side the binary value actually falls on — not a contract here.
    expect(quantizeTo(2.675, 2), 2.68);
    expect(quantizeTo(-2.675, 2), -2.68);
  });

  test('leaves non-finite input alone instead of returning NaN', () {
    expect(quantizeTo(double.infinity, 2), double.infinity);
    expect(quantizeTo(double.nan, 2).isNaN, isTrue);
  });

  test('clamps absurd digit counts instead of overflowing', () {
    expect(quantizeTo(1.5, 99), 1.5);
    expect(quantizeTo(1.5, -3), 1.5);
  });
}
