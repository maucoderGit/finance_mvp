import 'package:drift/native.dart';
import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/database/app_database.dart';
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/screens/overview/dashboard_screen.dart';
import 'package:finance_mvp/services/finance/currency_converter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'test_db.dart';

/// The dashboard's Spending/Income toggle and D/W/M/Y bar used to repaint and
/// nothing else. These assert each control changes the numbers on screen —
/// which is the whole claim — by expecting the production formatter's own
/// output, so the check holds under any locale.
void main() {
  setUpAll(() => useSystemSqlite());

  late AppDatabase db;
  late FinanceRepository repo;

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    repo = FinanceRepository(db);
    await repo.createAccountWithInitialTransaction(
      AccountsCompanion.insert(
        name: 'Cash',
        currencyCode: 'USD',
        icon: 'payments',
        iconColor: 0xFF4CAF50,
      ),
      0,
    );
    final account = (await repo.getAllAccounts()).first;
    final now = DateTime.now();

    Future<void> post(double amount, DateTime date) => repo.createTransaction(
          TransactionsCompanion.insert(
            amount: amount,
            accountId: account.id,
            currencyCode: 'USD',
            date: date,
          ),
        );

    // Today lands in every window; 45 days back only reaches the monthly and
    // yearly ones, which is what makes the filter distinguishable from a
    // highlight that changes nothing.
    await post(-55, now);
    await post(200, now);
    await post(-45, now.subtract(const Duration(days: 45)));
    await post(70, now.subtract(const Duration(days: 45)));
  });

  tearDown(() => db.close());

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [Provider<FinanceRepository>.value(value: repo)],
        child: AppPalette(
          colors: AppColors.current,
          child: const MaterialApp(home: DashboardScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  String money(double amount) => formatMoney(amount, currencyCode: 'USD');

  testWidgets('the bucket bar re-buckets the series', (tester) async {
    await mount(tester);

    expect(find.text('Spending · last 12 months'), findsOneWidget);
    expect(find.text(money(100)), findsOneWidget);

    await tester.tap(find.text('D'));
    await tester.pumpAndSettle();

    // The 45-day-old spending has fallen out of a 30-day window.
    expect(find.text('Spending · last 30 days'), findsOneWidget);
    expect(find.text(money(55)), findsOneWidget);
    expect(find.text(money(100)), findsNothing);
  });

  testWidgets('the Spending/Income toggle switches the plotted leg',
      (tester) async {
    await mount(tester);

    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();

    expect(find.text('Income · last 12 months'), findsOneWidget);
    expect(find.text(money(270)), findsOneWidget);
    expect(find.text(money(100)), findsNothing);

    await tester.tap(find.text('D'));
    await tester.pumpAndSettle();

    expect(find.text('Income · last 30 days'), findsOneWidget);
    expect(find.text(money(200)), findsOneWidget);
    expect(find.text(money(270)), findsNothing);
  });

  testWidgets('the dashboard ships no placeholder goals or dead bell',
      (tester) async {
    await mount(tester);

    expect(find.text('Goal Projections'), findsNothing);
    expect(find.text('Emergency Fund'), findsNothing);
    expect(find.text('Vacation to Italy'), findsNothing);
    expect(find.byIcon(Icons.notifications_none), findsNothing);
  });

  testWidgets('a ledger with no transactions still draws a flat zero line',
      (tester) async {
    await db.transaction(() async {
      await db.delete(db.transactions).go();
    });

    await mount(tester);

    expect(find.text('Spending · last 12 months'), findsOneWidget);
    expect(find.text(money(0)), findsOneWidget);
  });
}