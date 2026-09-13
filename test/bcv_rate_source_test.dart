import 'package:finance_mvp/services/rates/bcv_rate_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const bcvJson =
      '{"moneda":"USD","fuente":"oficial","nombre":"Dólar","compra":null,"venta":null,"promedio":832.4883,"fechaActualizacion":"2026-09-11T00:00:00-04:00"}';

  BcvRateSource source({List<int> status = const [200]}) {
    var calls = 0;
    return BcvRateSource(
      client: MockClient((_) async {
        final code = status[calls.clamp(0, status.length - 1)];
        calls++;
        return http.Response(code == 200 ? bcvJson : '{}', code);
      }),
    );
  }

  test('parses the official BCV rate for VES vs USD', () async {
    final rates = await source().fetchLatestRates(
      base: 'USD',
      quotes: const ['VES'],
    );
    expect(rates, {'VES': 832.4883});
  });

  test('only supports VES', () {
    expect(source().isSupported('VES'), isTrue);
    expect(source().isSupported('EUR'), isFalse);
  });

  test('returns empty for a non-USD base', () async {
    final rates = await source().fetchLatestRates(
      base: 'EUR',
      quotes: const ['VES'],
    );
    expect(rates, isEmpty);
  });

  test('throws on API error so callers can fall back', () {
    expect(
      () => source(status: [500]).fetchLatestRates(
        base: 'USD',
        quotes: const ['VES'],
      ),
      throwsA(anything),
    );
  });
}