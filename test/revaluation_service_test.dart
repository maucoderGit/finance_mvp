import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:finance_mvp/database/app_database.dart';
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/services/finance/revaluation_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_db.dart';

void main() {
  setUpAll(() => useSystemSqlite());

  late AppDatabase db;
  late FinanceRepository repo;
  late RevaluationService service;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    repo = FinanceRepository(db);
    service = RevaluationService(repo);
  });

  tearDown(() => db.close());

  Future<int> createAccount(String name, String currencyCode) async {
    final account = await db.into(db.accounts).insertReturning(
          AccountsCompanion.insert(
            name: name,
            currencyCode: currencyCode,
            icon: 'payments',
            iconColor: 0xFF4CAF50,
          ),
        );
    return account.id;
  }

  test('computes unrealized FX gain/loss per account', () async {
    final depositDate = DateTime.now().subtract(const Duration(days: 30));

    await repo.addExchangeRate(CurrencyRatesCompanion.insert(
      currencyCode: 'EUR',
      rate: 1.1,
      date: depositDate,
    ));

    final accountId = await createAccount('Euro Savings', 'EUR');

    const deposit = 100.0;
    const costBasis = 100.0 / 1.1;
    await repo.createTransaction(TransactionsCompanion.insert(
      amount: deposit,
      accountId: accountId,
      currencyCode: 'EUR',
      date: depositDate,
      exchangeRateAtCreation: const drift.Value(1.1),
      baseCurrencyAmount: const drift.Value(costBasis),
    ));

    await repo.addExchangeRate(CurrencyRatesCompanion.insert(
      currencyCode: 'EUR',
      rate: 1.0,
      date: DateTime.now(),
    ));

    final results = await service.getUnrealizedGainLossByAccount();
    expect(results, hasLength(1));

    final result = results.first;
    expect(result.balanceInNativeCurrency, closeTo(100, 0.001));
    expect(result.costBasisInBase, closeTo(90.909, 0.01));
    expect(result.currentValueInBase, closeTo(100, 0.001));
    expect(result.unrealizedGainLoss, closeTo(9.091, 0.01));
    expect(result.percentChange, closeTo(10, 0.1));
  });

  test('purchasing power history reflects national currency weakening',
      () async {
    final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));
    await repo.addExchangeRate(CurrencyRatesCompanion.insert(
      currencyCode: 'VES',
      rate: 10.0,
      date: twoWeeksAgo,
    ));
    await repo.addExchangeRate(CurrencyRatesCompanion.insert(
      currencyCode: 'VES',
      rate: 20.0,
      date: DateTime.now(),
    ));

    final history = await service.getPurchasingPowerHistory('VES');
    expect(history.length, 2);

    expect(history.first.valueInBase, closeTo(0.1, 0.001));
    expect(history.last.valueInBase, closeTo(0.05, 0.001));
    expect(history.last.cumulativeChange, closeTo(-0.5, 0.01));
  });

  test('summary reports purchasing power erosion over one year', () async {
    final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
    await repo.addExchangeRate(CurrencyRatesCompanion.insert(
      currencyCode: 'VES',
      rate: 100.0,
      date: oneYearAgo,
    ));
    await repo.addExchangeRate(CurrencyRatesCompanion.insert(
      currencyCode: 'VES',
      rate: 150.0,
      date: DateTime.now(),
    ));

    final summary = await service.getRevaluationSummary();
    expect(summary.nationalCurrencyCode, 'VES');
    expect(summary.nationalCurrencyRate, closeTo(150, 0.001));
    expect(summary.nationalCurrencyRateOneYearAgo, closeTo(100, 0.001));
    expect(summary.purchasingPowerChangePercent, closeTo(50, 0.01));
  });

  test('records and reads back daily net worth in both currencies', () async {
    await repo.addExchangeRate(CurrencyRatesCompanion.insert(
      currencyCode: 'VES',
      rate: 40.0,
      date: DateTime.now(),
    ));

    final usdAccount = await createAccount('Cash', 'USD');
    await repo.createTransaction(TransactionsCompanion.insert(
      amount: 60,
      accountId: usdAccount,
      currencyCode: 'USD',
      date: DateTime.now(),
    ));

    final vesAccount = await createAccount('Bolivares', 'VES');
    await repo.createTransaction(TransactionsCompanion.insert(
      amount: 4000,
      accountId: vesAccount,
      currencyCode: 'VES',
      date: DateTime.now(),
    ));

    await service.recordDailyNetWorth();

    final history = await service.getNetWorthHistory();
    expect(history, hasLength(1));
    expect(history.first.baseAmount, closeTo(160, 0.001));
    expect(history.first.nationalAmount, closeTo(6400, 0.001));
  });
}