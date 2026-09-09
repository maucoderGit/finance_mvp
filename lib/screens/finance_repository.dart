import 'package:drift/drift.dart' as drift;
import 'package:finance_mvp/screens/database.dart' as database;

class MonthlySummary {
  final double income;
  final double expenses;

  MonthlySummary({required this.income, required this.expenses});
}

class FinanceRepository {
  final database.AppDatabase db;

  FinanceRepository(this.db);

  Stream<List<database.Transaction>> watchTransactions() {
    return (db.select(db.transactions)).watch();
  }

  Stream<List<database.Account>> watchAccounts() {
    return (db.select(db.accounts)).watch();
  }

  Future<List<database.ExchangeRate>> getRatesForCurrency(String currencyCode) {
    return (db.select(db.currencyRates)
          ..where((tbl) => tbl.currencyCode.equals(currencyCode))
          ..orderBy([(t) => drift.OrderingTerm(expression: t.date, mode: drift.OrderingMode.desc)]))
        .get();
  }

  Future<void> addExchangeRate(database.CurrencyRatesCompanion rate) {
    // Use insert with onConflict to update if a rate for that day already exists
    return db.into(db.currencyRates).insert(rate, mode: drift.InsertMode.insertOrReplace);
  }

  Future<String> getBaseCurrencyCode() async {
    final setting = await (db.select(db.userSettings)..where((tbl) => tbl.id.equals(0))).getSingleOrNull();
    // Default to USD if not set
    return setting?.baseCurrencyCode ?? 'USD';
  }

  Stream<database.UserSetting?> watchUserSettings() {
    return (db.select(db.userSettings)..where((tbl) => tbl.id.equals(0))).watchSingleOrNull();
  }

  Future<void> setBaseCurrency(String currencyCode) async {
    final setting = database.UserSettingsCompanion(
      id: const drift.Value(0),
      baseCurrencyCode: drift.Value(currencyCode),
    );
    await db.into(db.userSettings).insert(
          setting,
          mode: drift.InsertMode.insertOrReplace,
        );
  }

  Future<void> updateUserSettings(database.UserSettingsCompanion settings) async {
    // Ensure we are only ever updating the single user setting row.
    final companion = settings.copyWith(id: const drift.Value(0));
    await db.into(db.userSettings).insert(
          companion,
          companion, // Use the companion with the ID set.
          mode: drift.InsertMode.insertOrReplace,
        );
    await db.update(db.userSettings).replace(
          setting,
          mode: drift.InsertMode.insertOrReplace,
        );
  }

  Future<void> createTransaction(database.TransactionsCompanion transaction) {
    return db.into(db.transactions).insert(transaction);
  }

  Future<void> createAccountWithInitialTransaction(
      database.AccountsCompanion account, double initialBalance) async {
    await db.transaction(() async {
      final newAccount = await db.into(db.accounts).insertReturning(account);

      if (initialBalance != 0.0) {
        await createTransaction(
          database.TransactionsCompanion(
            amount: drift.Value(initialBalance),
            accountId: drift.Value(newAccount.id),
            currencyCode: drift.Value(newAccount.currencyCode),
            date: drift.Value(DateTime.now()),
            categoryId: const drift.Value.absent(), // Or a default "Initial Balance" category
            reference: const drift.Value('Initial Balance'),
          ),
        );
      }
    });
  }

  Stream<MonthlySummary> watchMonthlySummary(DateTime date) {
    final startOfMonth = DateTime(date.year, date.month, 1);
    final endOfMonth = DateTime(date.year, date.month + 1, 0, 23, 59, 59);

    final query = db.select(db.transactions)
      ..where((t) => t.date.isBetween(drift.Variable(startOfMonth), drift.Variable(endOfMonth)));

    return db.transaction(() async {
      final transactionsInMonth = await query.get();
      double totalIncome = 0;
      double totalExpenses = 0;

      for (var t in transactionsInMonth) {
        if (t.amount > 0) {
          totalIncome += t.amount;
        } else {
          totalExpenses += t.amount.abs();
        }
      }
      return MonthlySummary(income: totalIncome, expenses: totalExpenses);
    }).asStream();
  }

  Future<double> convertAmount({
    required double amount,
    required String fromCode,
    required String toCode,
  }) async {
    if (fromCode == toCode) return amount;

    final baseCurrencyCode = await getBaseCurrencyCode();

    // Case 1: Converting from a foreign currency to the base currency (e.g., VES -> USD)
    if (toCode == baseCurrencyCode) {
      final rateQuery = db.select(db.currencyRates)
        ..where((r) => r.currencyCode.equals(fromCode))
        ..orderBy([(r) => drift.OrderingTerm(expression: r.date, mode: drift.OrderingMode.desc)])
        ..limit(1);
      final rate = await rateQuery.getSingleOrNull();
      // If 1 USD = 36 VES, to convert VES to USD, we divide.
      return rate != null ? amount / rate.rate : amount;
    }

    // Case 2: Converting from the base currency to a foreign currency (e.g., USD -> VES)
    if (fromCode == baseCurrencyCode) {
      final rateQuery = db.select(db.currencyRates)
        ..where((r) => r.currencyCode.equals(toCode))
        ..orderBy([(r) => drift.OrderingTerm(expression: r.date, mode: drift.OrderingMode.desc)])
        ..limit(1);
      final rate = await rateQuery.getSingleOrNull();
      // If 1 USD = 36 VES, to convert USD to VES, we multiply.
      return rate != null ? amount * rate.rate : amount;
    }

    // Case 3: Converting between two foreign currencies (e.g., EUR -> VES)
    // First, convert fromCode to base currency, then base currency to toCode.
    final amountInBase = await convertAmount(amount: amount, fromCode: fromCode, toCode: baseCurrencyCode);
    return await convertAmount(amount: amountInBase, fromCode: baseCurrencyCode, toCode: toCode);
  }

  Future<double> calculateTotalBalance(String toCode) async {
    final allAccounts = await (db.select(db.accounts)).get();
    final allTransactions = await (db.select(db.transactions)).get();
    double total = 0;
    for (var account in allAccounts) {
      final accountBalance = allTransactions
          .where((t) => t.accountId == account.id)
          .fold<double>(0.0, (sum, t) => sum + t.amount);
      total += await convertAmount(amount: accountBalance, fromCode: account.currencyCode, toCode: toCode);
    }
    return total;
  }
}