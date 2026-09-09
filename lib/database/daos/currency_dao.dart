import 'package:drift/drift.dart';
import '../app_database.dart';

part 'currency_dao.g.dart';

@DriftAccessor(tables: [Currencies, CurrencyRates, UserSettings])
class CurrencyDao extends DatabaseAccessor<AppDatabase>
    with _$CurrencyDaoMixin {
  CurrencyDao(super.db);

  Stream<List<Currency>> watchAllCurrencies() => select(currencies).watch();

  Future<List<Currency>> getAllCurrencies() => select(currencies).get();

  Future<Currency?> getCurrency(String code) =>
      (select(currencies)..where((c) => c.code.equals(code)))
          .getSingleOrNull();

  Future<int> insertCurrency(CurrenciesCompanion currency) =>
      into(currencies).insert(currency);

  Future<bool> updateCurrency(CurrenciesCompanion currency) =>
      update(currencies).replace(currency);

  // Exchange rates
  Stream<List<ExchangeRate>> watchRatesForCurrency(String currencyCode) {
    return (select(currencyRates)
          ..where((r) => r.currencyCode.equals(currencyCode))
          ..orderBy(
              [(r) => OrderingTerm.desc(r.date)]))
        .watch();
  }

  Future<List<ExchangeRate>> getRatesForCurrency(String currencyCode) {
    return (select(currencyRates)
          ..where((r) => r.currencyCode.equals(currencyCode))
          ..orderBy(
              [(r) => OrderingTerm.desc(r.date)]))
        .get();
  }

  Future<ExchangeRate?> getLatestRate(String currencyCode) {
    return (select(currencyRates)
          ..where((r) => r.currencyCode.equals(currencyCode))
          ..orderBy([(r) => OrderingTerm.desc(r.date)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<ExchangeRate?> getRateAtDate(String currencyCode, DateTime date) {
    return (select(currencyRates)
          ..where((r) =>
              r.currencyCode.equals(currencyCode) &
              r.date.isSmallerOrEqualValue(date))
          ..orderBy([(r) => OrderingTerm.desc(r.date)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> addExchangeRate(CurrencyRatesCompanion rate) {
    return into(currencyRates).insert(rate,
        mode: InsertMode.insertOrReplace);
  }

  Future<void> addExchangeRatesBatch(List<CurrencyRatesCompanion> rates) {
    return batch((batch) {
      batch.insertAll(currencyRates, rates,
          mode: InsertMode.insertOrReplace);
    });
  }

  // User settings
  Stream<UserSetting?> watchUserSettings() {
    return (select(userSettings)..where((s) => s.id.equals(0)))
        .watchSingleOrNull();
  }

  Future<UserSetting?> getUserSettings() {
    return (select(userSettings)..where((s) => s.id.equals(0)))
        .getSingleOrNull();
  }

  Future<String> getBaseCurrencyCode() async {
    final setting = await getUserSettings();
    return setting?.baseCurrencyCode ?? 'USD';
  }

  Future<void> setBaseCurrency(String currencyCode) {
    return into(userSettings).insert(
      UserSettingsCompanion(
        id: const Value(0),
        baseCurrencyCode: Value(currencyCode),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> updateUserSettings(UserSettingsCompanion settings) {
    final companion = settings.copyWith(id: const Value(0));
    return into(userSettings).insert(
      companion,
      mode: InsertMode.insertOrReplace,
    );
  }

  // Rate snapshots
  Future<void> addRateSnapshot(ExchangeRateSnapshotsCompanion snapshot) {
    return into(db.exchangeRateSnapshots).insert(snapshot,
        mode: InsertMode.insertOrReplace);
  }

  Future<List<ExchangeRateSnapshot>> getRateSnapshots(
      {int limit = 30}) {
    return (select(db.exchangeRateSnapshots)
          ..orderBy([(s) => OrderingTerm.desc(s.date)])
          ..limit(limit))
        .get();
  }

  Stream<List<ExchangeRateSnapshot>> watchRateSnapshots({int limit = 30}) {
    return (select(db.exchangeRateSnapshots)
          ..orderBy([(s) => OrderingTerm.desc(s.date)])
          ..limit(limit))
        .watch();
  }
}
