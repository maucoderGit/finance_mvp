import 'package:finance_mvp/services/finance/fx_delta.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const bcv = 36.5;
  const market = 40.0;

  test('VES expense at BCV rate yields positive gap savings', () {
    final delta = fxDeltaUsdt(amountVes: -4000, bcvRate: bcv, marketRate: market);
    expect(delta, closeTo(9.589, 0.01));
    expect(delta, greaterThan(0));
  });

  test('VES income converted to USD yields negative replacement loss', () {
    final delta = fxDeltaUsdt(amountVes: 4000, bcvRate: bcv, marketRate: market);
    expect(delta, closeTo(-9.589, 0.01));
    expect(delta, lessThan(0));
  });

  test('zero gap (market == official) yields zero delta', () {
    expect(fxDeltaUsdt(amountVes: -4000, bcvRate: market, marketRate: market), 0);
  });

  test('degenerate rates yield zero instead of crashing', () {
    expect(fxDeltaUsdt(amountVes: -4000, bcvRate: 0, marketRate: market), 0);
    expect(fxDeltaUsdt(amountVes: -4000, bcvRate: bcv, marketRate: -1), 0);
    expect(fxDeltaUsdt(amountVes: 0, bcvRate: bcv, marketRate: market), 0);
  });
}