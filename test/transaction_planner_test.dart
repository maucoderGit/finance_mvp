import 'package:drift/native.dart';
import 'package:finance_mvp/database/app_database.dart';
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/services/finance/transaction_planner.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_db.dart';

void main() {
  setUpAll(() => useSystemSqlite());

  late AppDatabase db;
  late FinanceRepository repo;
  late TransactionPlanner planner;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    repo = FinanceRepository(db);
    planner = TransactionPlanner(repo);
  });

  tearDown(() => db.close());

  Future<Account> account(String name, String code) async {
    await repo.createAccountWithInitialTransaction(
      AccountsCompanion.insert(
        name: name,
        currencyCode: code,
        icon: 'payments',
        iconColor: 0xFF4CAF50,
      ),
      0,
    );
    return (await repo.getAllAccounts()).firstWhere((a) => a.name == name);
  }

  group('intervalDate', () {
    test('weekly and biweekly step by fixed days', () {
      final due = DateTime(2026, 1, 15);
      expect(TransactionPlanner.intervalDate(due, 'weekly', 2),
          DateTime(2026, 1, 29));
      expect(TransactionPlanner.intervalDate(due, 'biweekly', 1),
          DateTime(2026, 1, 29));
    });

    test('monthly steps by calendar month', () {
      expect(TransactionPlanner.intervalDate(DateTime(2026, 1, 15), 'monthly', 1),
          DateTime(2026, 2, 15));
    });
  });

  group('buildDebtPlan', () {
    test('last quota absorbs the remainder and the schedule sums to total',
        () async {
      final plan = await planner.buildDebtPlan(
        title: 'Rent',
        total: 100,
        installmentCount: 3,
        firstDueDate: DateTime(2026, 3, 1),
        frequency: 'monthly',
        direction: 'creditor',
        currency: 'USD',
      );

      final amounts =
          plan.installments.map((c) => c.amount.value).toList();
      expect(amounts, [
        closeTo(33.33, 0.001),
        closeTo(33.33, 0.001),
        closeTo(33.34, 0.001),
      ]);
      expect(amounts.reduce((a, b) => a + b), closeTo(100, 0.001));
      expect(plan.debt.amount.value, 100);
      expect(plan.debt.description.value, 'Rent');
      expect(plan.installments[1].dueDate.value, DateTime(2026, 4, 1));
    });
  });

  group('buildTransferLegs', () {
    test('same-currency transfer keeps both legs 1:1', () async {
      final from = await account('A', 'USD');
      final to = await account('B', 'USD');

      final legs = await planner.buildTransferLegs(
        from: from,
        to: to,
        amount: 100,
        reference: 'move',
        date: DateTime(2026, 1, 1),
      );

      expect(legs.fromLeg.amount.value, -100);
      expect(legs.fromLeg.baseCurrencyAmount.value, -100);
      expect(legs.toLeg.amount.value, 100);
      expect(legs.toLeg.baseCurrencyAmount.value, 100);
      expect(legs.fromLeg.exchangeRateAtCreation.value, isNull);
    });

    test('cross-currency transfer values both legs at one rate', () async {
      final from = await account('Cash', 'USD');
      final to = await account('Bolivares', 'VES');
      await repo.addExchangeRate(CurrencyRatesCompanion.insert(
        currencyCode: 'VES',
        rate: 40,
        date: DateTime(2026, 1, 1),
      ));
      await repo.addMarketRate(MarketRatesCompanion.insert(
        rate: 50,
        date: DateTime(2026, 1, 1),
      ));

      final legs = await planner.buildTransferLegs(
        from: from,
        to: to,
        amount: 100,
        reference: 'move',
        date: DateTime(2026, 1, 1),
      );

      // The national leg executes at the parallel market price.
      expect(legs.toLeg.exchangeRateAtCreation.value, 50);
      expect(legs.fromLeg.exchangeRateAtCreation.value, isNull);
      expect(legs.toLeg.amount.value, 5000);
      expect(legs.toLeg.baseCurrencyAmount.value, 100);
      expect(legs.fromLeg.baseCurrencyAmount.value, -100);
      // VES leg logs the BCV-vs-market arbitrage (replacement loss on funding).
      expect(legs.toLeg.fxDelta.value, closeTo(-25, 0.001));
    });
  });
}
