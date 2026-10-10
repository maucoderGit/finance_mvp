import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:finance_mvp/database/app_database.dart';
import 'package:finance_mvp/providers/currency_provider.dart';
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/services/rates/exchange_rate_api_service.dart';
import 'package:finance_mvp/services/rates/market_rate_source.dart';
import 'package:finance_mvp/services/rates/rate_source.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_db.dart';

/// A RateSource whose supported codes and returned rates are fixed, so sync
/// behaviour can be exercised without any HTTP.
class _FakeSource implements RateSource {
  _FakeSource(this._supported, this._rates, {this.throwOnFetch = false});

  final Set<String> _supported;
  final Map<String, double> _rates;
  final bool throwOnFetch;

  @override
  bool isSupported(String currencyCode) => _supported.contains(currencyCode);

  @override
  Future<Map<String, double>> fetchLatestRates({
    required String base,
    required List<String> quotes,
  }) async {
    if (throwOnFetch) throw Exception('source down');
    return {
      for (final q in quotes)
        if (_rates.containsKey(q)) q: _rates[q]!,
    };
  }

  @override
  void dispose() {}
}

/// Hits the provider's `source is ExchangeRateApiService` time-series branch.
class _FakeApi extends ExchangeRateApiService {
  _FakeApi(this._series);

  final Map<String, Map<String, double>> _series;

  @override
  Future<Map<String, Map<String, double>>> fetchTimeSeries({
    required String base,
    required List<String> quotes,
    required DateTime from,
    required DateTime to,
  }) async =>
      _series;
}

class _FakeMarket extends MarketRateSource {
  _FakeMarket(this._rate);
  final double? _rate;

  @override
  Future<double?> fetchLatestRate() async => _rate;
}

void main() {
  setUpAll(() => useSystemSqlite());

  late AppDatabase db;
  late FinanceRepository repo;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    repo = FinanceRepository(db);
  });

  tearDown(() => db.close());

  test('syncHistoricalRates stores every row before it returns', () async {
    final provider = CurrencyProvider(
      repo,
      sources: [
        _FakeApi({
          '2026-01-01': {'EUR': 0.9},
          '2026-01-02': {'EUR': 0.91},
          '2026-01-03': {'EUR': 0.92},
        }),
      ],
      marketRateSource: _FakeMarket(null),
    );

    final count = await provider.syncHistoricalRates('EUR', daysBack: 5);

    expect(count, 3);
    // The writes are awaited, so the rows are already persisted.
    expect(await repo.getRatesForCurrency('EUR'), hasLength(3));
  });

  test('syncRates does not flip a manual selection back to auto', () async {
    await repo.updateUserSettings(
        const UserSettingsCompanion(currencySelectionMode: Value('manual')));

    final provider = CurrencyProvider(
      repo,
      sources: [
        _FakeSource({'VES'}, {'VES': 40.0}),
      ],
      marketRateSource: _FakeMarket(41.0),
    );

    final updated = await provider.syncRates(force: true);

    expect(updated, 1);
    final settings = await repo.watchUserSettings().first;
    expect(settings!.currencySelectionMode, 'manual');
    expect(settings.lastAutoFetchDate, isNotNull);
    expect(provider.syncError, isNull);
  });

  test('syncRates surfaces a source failure even when a rate was stored',
      () async {
    final provider = CurrencyProvider(
      repo,
      sources: [
        _FakeSource({'VES'}, {'VES': 40.0}),
        _FakeSource({'VES'}, {}, throwOnFetch: true),
      ],
      marketRateSource: _FakeMarket(41.0),
    );

    final updated = await provider.syncRates(force: true);

    // One source succeeded, but the failure must not be reported as success.
    expect(updated, 1);
    expect(provider.syncError, isNotNull);
  });
}
