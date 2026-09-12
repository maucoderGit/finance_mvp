import 'package:drift/drift.dart' as drift;
import 'package:finance_mvp/database/app_database.dart';

class MonthlySummary {
  final double income;
  final double expenses;

  MonthlySummary({required this.income, required this.expenses});
}

class FinanceRepository {
  final AppDatabase db;

  FinanceRepository(this.db);

  // ── Transactions ──

  Stream<List<Transaction>> watchTransactions() {
    return (db.select(db.transactions)).watch();
  }

  Future<void> createTransaction(TransactionsCompanion transaction) {
    return db.into(db.transactions).insert(transaction);
  }

  Future<void> updateTransaction(TransactionsCompanion transaction) {
    return db.into(db.transactions).insert(
          transaction,
          mode: drift.InsertMode.insertOrReplace,
        );
  }

  Future<void> deleteTransaction(int id) {
    return (db.delete(db.transactions)..where((t) => t.id.equals(id))).go();
  }

  // ── Accounts ──

  Stream<List<Account>> watchAccounts() {
    return (db.select(db.accounts)).watch();
  }

  Future<List<Account>> getAllAccounts() {
    return (db.select(db.accounts)).get();
  }

  Future<void> createAccountWithInitialTransaction(
      AccountsCompanion account, double initialBalance) async {
    await db.transaction(() async {
      final newAccount = await db.into(db.accounts).insertReturning(account);

      if (initialBalance != 0.0) {
        await createTransaction(
          TransactionsCompanion(
            amount: drift.Value(initialBalance),
            accountId: drift.Value(newAccount.id),
            currencyCode: drift.Value(newAccount.currencyCode),
            date: drift.Value(DateTime.now()),
            categoryId: const drift.Value.absent(),
            reference: const drift.Value('Initial Balance'),
            exchangeRateAtCreation: drift.Value(
                await _getExchangeRateForDate(
                    newAccount.currencyCode, DateTime.now())),
          ),
        );
      }
    });
  }

  Future<double> getAccountBalance(int accountId) async {
    final allTransactions = await (db.select(db.transactions)
          ..where((t) => t.accountId.equals(accountId)))
        .get();
    return allTransactions.fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  Stream<double> watchAccountBalance(int accountId) {
    final query = db.select(db.transactions)
      ..where((t) => t.accountId.equals(accountId));
    return query.watch().map((txs) =>
        txs.fold<double>(0.0, (sum, t) => sum + t.amount));
  }

  // ── Exchange Rates ──

  Future<List<ExchangeRate>> getRatesForCurrency(String currencyCode) {
    return (db.select(db.currencyRates)
          ..where((tbl) => tbl.currencyCode.equals(currencyCode))
          ..orderBy([(t) =>
              drift.OrderingTerm(expression: t.date, mode: drift.OrderingMode.desc)]))
        .get();
  }

  Stream<List<ExchangeRate>> watchRatesForCurrency(String currencyCode) {
    return (db.select(db.currencyRates)
          ..where((tbl) => tbl.currencyCode.equals(currencyCode))
          ..orderBy([(t) =>
              drift.OrderingTerm(expression: t.date, mode: drift.OrderingMode.desc)]))
        .watch();
  }

  Future<ExchangeRate?> getLatestRate(String currencyCode) {
    return (db.select(db.currencyRates)
          ..where((r) => r.currencyCode.equals(currencyCode))
          ..orderBy([(r) =>
              drift.OrderingTerm(expression: r.date, mode: drift.OrderingMode.desc)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<ExchangeRate?> getRateAtDate(
      String currencyCode, DateTime date) {
    return (db.select(db.currencyRates)
          ..where((r) =>
              r.currencyCode.equals(currencyCode) &
              r.date.isSmallerOrEqualValue(date))
          ..orderBy([(r) =>
              drift.OrderingTerm(expression: r.date, mode: drift.OrderingMode.desc)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Rate ("1 base = X currency") at or before [date], falling back to the
  /// newest stored rate.
  Future<double?> getRateWithFallback(
          String currencyCode, DateTime date) async {
    final rate = await getRateAtDate(currencyCode, date);
    return rate?.rate ?? (await getLatestRate(currencyCode))?.rate;
  }

  Future<void> addExchangeRate(CurrencyRatesCompanion rate) {
    return db.into(db.currencyRates).insert(rate,
        mode: drift.InsertMode.insertOrReplace);
  }

  Future<void> addExchangeRatesBatch(List<CurrencyRatesCompanion> rates) {
    return db.batch((batch) {
      batch.insertAll(db.currencyRates, rates,
          mode: drift.InsertMode.insertOrReplace);
    });
  }

  Future<double?> _getExchangeRateForDate(
      String currencyCode, DateTime date) async {
    final rate = await getRateAtDate(currencyCode, date);
    return rate?.rate;
  }

  // ── User Settings ──

  Future<String> getBaseCurrencyCode() async {
    final setting = await (db.select(db.userSettings)
          ..where((tbl) => tbl.id.equals(0)))
        .getSingleOrNull();
    return setting?.baseCurrencyCode ?? 'USD';
  }

  Future<String> getNationalCurrencyCode() async {
    final setting = await (db.select(db.userSettings)
          ..where((tbl) => tbl.id.equals(0)))
        .getSingleOrNull();
    return setting?.nationalCurrencyCode ?? 'VES';
  }

  Future<bool> getHasCompletedOnboarding() async {
    final setting = await (db.select(db.userSettings)
          ..where((tbl) => tbl.id.equals(0)))
        .getSingleOrNull();
    return setting?.hasCompletedOnboarding ?? false;
  }

  Stream<UserSetting?> watchUserSettings() {
    return (db.select(db.userSettings)
          ..where((tbl) => tbl.id.equals(0)))
        .watchSingleOrNull();
  }

  /// Upsert settings row id=0 while preserving every stored value: plain
  /// insert-or-replace fills untouched columns with defaults, which would wipe
  /// username/national currency/onboarding. [patch] applies the caller's change
  /// on top of the row's current values (or defaults for a fresh row).
  Future<void> _updateSettings(
      UserSettingsCompanion Function(UserSettingsCompanion base) patch) async {
    final existing = await (db.select(db.userSettings)
          ..where((tbl) => tbl.id.equals(0)))
        .getSingleOrNull();

    final companion = existing != null
        ? patch(existing.toCompanion(false)).copyWith(id: const drift.Value(0))
        : patch(UserSettingsCompanion.insert(baseCurrencyCode: 'USD')).copyWith(
              id: const drift.Value(0),
              hasCompletedOnboarding: const drift.Value(true),
            );

    await db.into(db.userSettings)
        .insert(companion, mode: drift.InsertMode.insertOrReplace);
  }

  Future<void> setBaseCurrency(String currencyCode) {
    return _updateSettings(
        (c) => c.copyWith(baseCurrencyCode: drift.Value(currencyCode)));
  }

  Future<void> updateUserSettings(UserSettingsCompanion settings) {
    final companion = settings.copyWith(id: const drift.Value(0));
    return db.into(db.userSettings).insert(
          companion,
          mode: drift.InsertMode.insertOrReplace,
        );
  }

  Future<String?> getProfilePicturePath() async {
    final setting = await (db.select(db.userSettings)
          ..where((tbl) => tbl.id.equals(0)))
        .getSingleOrNull();
    return setting?.profilePicturePath;
  }

  Future<void> saveProfilePicturePath(String path) {
    return _updateSettings(
        (c) => c.copyWith(profilePicturePath: drift.Value(path)));
  }

  // ── Currencies ──

  Stream<List<Currency>> watchCurrencies() {
    return (db.select(db.currencies)).watch();
  }

  Future<List<Currency>> getAllCurrencies() {
    return (db.select(db.currencies)).get();
  }

  Future<Currency?> getCurrency(String code) {
    return (db.select(db.currencies)
          ..where((c) => c.code.equals(code)))
        .getSingleOrNull();
  }

  Future<void> addCurrency(CurrenciesCompanion currency) {
    return db.into(db.currencies).insert(currency);
  }

  // ── Categories ──

  Stream<List<Category>> watchCategories() {
    return (db.select(db.categories)).watch();
  }

  Future<List<Category>> getAllCategories() {
    return (db.select(db.categories)).get();
  }

  // ── Currency Conversion ──

  Future<double> convertAmount({
    required double amount,
    required String fromCode,
    required String toCode,
  }) async {
    if (fromCode == toCode) return amount;

    final baseCurrencyCode = await getBaseCurrencyCode();

    if (toCode == baseCurrencyCode) {
      final rate = await getLatestRate(fromCode);
      return rate != null ? amount / rate.rate : amount;
    }

    if (fromCode == baseCurrencyCode) {
      final rate = await getLatestRate(toCode);
      return rate != null ? amount * rate.rate : amount;
    }

    final amountInBase =
        await convertAmount(amount: amount, fromCode: fromCode, toCode: baseCurrencyCode);
    return await convertAmount(
        amount: amountInBase, fromCode: baseCurrencyCode, toCode: toCode);
  }

  // ── Balance Calculation (optimized with SQL aggregation) ──

  Future<double> calculateTotalBalance(String toCode) async {
    final allAccounts = await (db.select(db.accounts)).get();
    if (allAccounts.isEmpty) return 0;

    // Single grouped query: transaction totals per account (avoids N+1).
    final rows = await db.customSelect(
      'SELECT account_id AS accountId, SUM(amount) AS total '
      'FROM transactions GROUP BY account_id',
      readsFrom: {db.transactions},
    ).get();

    final totalByAccount = <int, double>{
      for (final row in rows)
        row.read<int>('accountId'): (row.data['total'] as num).toDouble(),
    };

    double total = 0;
    for (final account in allAccounts) {
      final balance = totalByAccount[account.id] ?? 0.0;
      total += await convertAmount(
          amount: balance, fromCode: account.currencyCode, toCode: toCode);
    }

    return total;
  }

  // ── Rate Snapshots ──

  Future<void> addRateSnapshot(ExchangeRateSnapshotsCompanion snapshot) {
    return db.into(db.exchangeRateSnapshots).insert(
          snapshot,
          mode: drift.InsertMode.insertOrReplace,
        );
  }

  Stream<List<ExchangeRateSnapshot>> watchRateSnapshots({int limit = 30}) {
    return (db.select(db.exchangeRateSnapshots)
          ..orderBy([(s) =>
              drift.OrderingTerm(expression: s.date, mode: drift.OrderingMode.desc)])
          ..limit(limit))
        .watch();
  }

  // ── Net Worth History ──

  Stream<List<NetWorthHistoryData>> watchNetWorthHistory({int limit = 90}) {
    return (db.select(db.netWorthHistory)
          ..orderBy([(n) =>
              drift.OrderingTerm(expression: n.date, mode: drift.OrderingMode.desc)])
          ..limit(limit))
        .watch();
  }

  Future<void> addNetWorthSnapshot(NetWorthHistoryCompanion snapshot) {
    return db.into(db.netWorthHistory).insert(
          snapshot,
          mode: drift.InsertMode.insertOrReplace,
        );
  }

  // ── Monthly Summary ──

  /// Convert a transaction to the base currency, preferring the rate captured
  /// at creation time (falls back to the latest stored rate).
  Future<double> toBaseAmount(Transaction transaction) async {
    final baseCode = await getBaseCurrencyCode();
    if (transaction.currencyCode == baseCode) return transaction.amount;
    final stored = transaction.baseCurrencyAmount;
    if (stored != null) return stored;
    return convertAmount(
      amount: transaction.amount,
      fromCode: transaction.currencyCode,
      toCode: baseCode,
    );
  }

  Stream<MonthlySummary> watchMonthlySummary(DateTime date) {
    final startOfMonth = DateTime(date.year, date.month, 1);
    final endOfMonth = DateTime(date.year, date.month + 1, 0, 23, 59, 59);

    final query = db.select(db.transactions)
      ..where((t) =>
          t.date.isBetween(drift.Variable(startOfMonth), drift.Variable(endOfMonth)));

    return db.transaction(() async {
      final transactionsInMonth = await query.get();
      double totalIncome = 0;
      double totalExpenses = 0;

      for (final t in transactionsInMonth) {
        final baseAmount = await toBaseAmount(t);
        if (baseAmount > 0) {
          totalIncome += baseAmount;
        } else {
          totalExpenses += baseAmount.abs();
        }
      }
      return MonthlySummary(income: totalIncome, expenses: totalExpenses);
    }).asStream();
  }
}
