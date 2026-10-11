import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:finance_mvp/database/app_database.dart';
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_db.dart';

/// The dashboard derives every figure from repository methods, so this tests
/// those derivations directly — the month summary, the spending-by-category
/// grouping and the balance total. Nothing here pumps a widget tree.
void main() {
  setUpAll(() => useSystemSqlite());

  late AppDatabase db;
  late FinanceRepository repo;

  setUp(() async {
    db = AppDatabase(executor: testConnection(NativeDatabase.memory()));
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
  });

  tearDown(() => db.close());

  Future<Account> cashAccount() async => (await repo.getAllAccounts()).first;

  Future<void> post(Account account, double amount, DateTime date,
          {Value<int?> categoryId = const Value.absent()}) =>
      repo.createTransaction(TransactionsCompanion.insert(
        amount: amount,
        accountId: account.id,
        currencyCode: 'USD',
        date: date,
        categoryId: categoryId,
      ));

  test('calculateTotalBalance sums every account in the base currency',
      () async {
    final account = await cashAccount();
    final now = DateTime.now();
    await post(account, 200, now);
    await post(account, -55, now);
    await post(account, -45, now.subtract(const Duration(days: 45)));

    expect(await repo.calculateTotalBalance('USD'), 100);
  });

  test('watchSpendingByCategory groups this month only, largest first',
      () async {
    final account = await cashAccount();
    final now = DateTime.now();
    final categoryId = await db.into(db.categories).insert(
          CategoriesCompanion.insert(
              name: 'Food', icon: 'restaurant', color: 0xFFFF9800),
        );

    await post(account, -30, now, categoryId: Value(categoryId));
    await post(account, -10, now);
    // Older spending and income must not leak into the current cycle.
    await post(account, -999, now.subtract(const Duration(days: 45)));
    await post(account, 500, now);

    final spending = await repo.watchSpendingByCategory(now).first;
    expect(spending.map((c) => c.name), ['Food', 'Uncategorized']);
    expect(spending[0].icon, 'restaurant');
    expect(spending[0].color, 0xFFFF9800);
    expect(spending[0].amount, 30);
    expect(spending[1].amount, 10);
  });

  test('monthly summary derives income, expenses and net', () async {
    final account = await cashAccount();
    final now = DateTime.now();
    await post(account, 200, now);
    await post(account, -55, now);

    final summary = await repo.watchMonthlySummary(now).first;
    expect(summary.income, 200);
    expect(summary.expenses, 55);
    expect(summary.income - summary.expenses, 145);
  });
}