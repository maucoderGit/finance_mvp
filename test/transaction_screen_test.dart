import 'package:drift/native.dart';
import 'package:finance_mvp/database/app_database.dart';
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/screens/transactions/transaction_screen.dart';
import 'package:finance_mvp/widgets/numpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'test_db.dart';

Future<(AppDatabase, FinanceRepository)> pumpTransactionScreen(
  WidgetTester tester, {
  required List<String> currencyCodes,
}) async {
  tester.view.physicalSize = const Size(1000, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final db = AppDatabase(executor: NativeDatabase.memory());
  final repo = FinanceRepository(db);

  for (final code in currencyCodes) {
    await repo.createAccountWithInitialTransaction(
      AccountsCompanion.insert(
        name: 'Account $code',
        currencyCode: code,
        icon: 'payments',
        iconColor: 0xFF4CAF50,
      ),
      0,
    );
  }

  final navigatorKey = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MultiProvider(
      providers: [Provider<FinanceRepository>.value(value: repo)],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: SizedBox()),
      ),
    ),
  );

  navigatorKey.currentState!.push(
    MaterialPageRoute(builder: (_) => const TransactionScreen()),
  );
  await tester.pumpAndSettle();

  return (db, repo);
}

Future<void> tapNumpad(WidgetTester tester, List<String> keys) async {
  final numpad = find.byType(Numpad);
  for (final key in keys) {
    await tester.tap(find.descendant(of: numpad, matching: find.text(key)));
    await tester.pump();
  }
}

void main() {
  setUpAll(() => useSystemSqlite());

  testWidgets('numpad amount 2000 is stored as 2000.00', (tester) async {
    final (db, repo) = await pumpTransactionScreen(tester, currencyCodes: ['USD']);

    await tapNumpad(tester, ['2', '0', '0', '0']);

    await tester.tap(find.text('Add details'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final transactions = await repo.db.select(repo.db.transactions).get();
    expect(transactions, hasLength(1));
    expect(transactions.single.amount, closeTo(2000.0, 0.001));

    await db.close();
  });

  testWidgets('numpad supports decimals (2000.50 stored as 2000.50)',
      (tester) async {
    final (db, repo) = await pumpTransactionScreen(tester, currencyCodes: ['USD']);

    await tapNumpad(tester, ['2', '0', '0', '0', '.', '5', '0']);

    await tester.tap(find.text('Add details'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final transactions = await repo.db.select(repo.db.transactions).get();
    expect(transactions.single.amount, closeTo(2000.50, 0.001));

    await db.close();
  });

  testWidgets('basic transactions hide the exchange rate field',
      (tester) async {
    final (db, repo) = await pumpTransactionScreen(tester, currencyCodes: ['VES']);

    await tapNumpad(tester, ['2', '0', '0', '0']);

    await tester.tap(find.text('Add details'));
    await tester.pumpAndSettle();

    final rateField = find.byWidgetPredicate((w) =>
        w is TextField && w.decoration?.hintText == 'Rate');
    expect(rateField, findsNothing);

    await db.close();
  });

  testWidgets('internal transfer writes two linked legs with the manual rate',
      (tester) async {
    final (db, repo) =
        await pumpTransactionScreen(tester, currencyCodes: ['VES', 'USD']);
    await repo.addExchangeRate(CurrencyRatesCompanion.insert(
      currencyCode: 'VES',
      rate: 36.5,
      date: DateTime.now(),
    ));

    await tapNumpad(tester, ['2', '0', '0', '0']);

    await tester.tap(find.text('Add details'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Transfer'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Select To Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Account USD'));
    await tester.pumpAndSettle();

    // The rate field only appears for the cross-currency transfer.
    final rateField = find.byWidgetPredicate((w) =>
        w is TextField && w.decoration?.hintText == 'Rate');
    expect(rateField, findsOneWidget);
    await tester.enterText(rateField, '40');

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final accounts = await repo.getAllAccounts();
    final vesAccount = accounts.firstWhere((a) => a.currencyCode == 'VES');
    final usdAccount = accounts.firstWhere((a) => a.currencyCode == 'USD');
    final transactions = await repo.db.select(repo.db.transactions).get();
    expect(transactions, hasLength(2));
    expect(transactions.map((t) => t.transferGroupId).toSet(), hasLength(1));

    final vesLeg =
        transactions.firstWhere((t) => t.accountId == vesAccount.id);
    final usdLeg = transactions.firstWhere((t) => t.accountId == usdAccount.id);

    expect(vesLeg.amount, closeTo(-2000, 0.001));
    expect(vesLeg.exchangeRateAtCreation, closeTo(40.0, 0.001));
    expect(vesLeg.baseCurrencyAmount, closeTo(-50.0, 0.001));
    // Gap savings: 2000 VES moved out at 40 instead of the official 36.5.
    expect(vesLeg.fxDelta, closeTo(4.7945, 0.01));

    expect(usdLeg.amount, closeTo(50.0, 0.001));
    expect(usdLeg.baseCurrencyAmount, closeTo(50.0, 0.001));
    expect(usdLeg.exchangeRateAtCreation, isNull);

    await db.close();
  });
}