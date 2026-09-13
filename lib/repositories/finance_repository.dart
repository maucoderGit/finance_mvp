import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:finance_mvp/database/app_database.dart';

class MonthlySummary {
  final double income;
  final double expenses;

  /// Sum of `fxDelta` over the filtered transactions (USDT-lived Net FX
  /// Impact: positive = gap savings, negative = replacement loss).
  final double fxImpact;

  MonthlySummary({
    required this.income,
    required this.expenses,
    this.fxImpact = 0,
  });
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

  /// Delete a single income/expense, or both legs of a transfer (identified by
  /// [id] being either leg of the pair).
  Future<void> deleteTransaction(int id) async {
    final existing = await (db.select(db.transactions)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (existing == null) return;

    final groupId = existing.transferGroupId;
    if (groupId != null) {
      await (db.delete(db.transactions)..where((t) => t.transferGroupId.equals(groupId)))
          .go();
    } else {
      await (db.delete(db.transactions)..where((t) => t.id.equals(id))).go();
    }
  }

  /// Insert the two linked legs of an internal transfer/menudeo atomically:
  /// seeing half a transfer (one leg committed, the other not) would corrupt
  /// balances. Both rows share [groupId] on `transferGroupId`.
  Future<void> createTransfer({
    required String groupId,
    required TransactionsCompanion fromLeg,
    required TransactionsCompanion toLeg,
  }) {
    return db.transaction(() async {
      final from = fromLeg.copyWith(transferGroupId: drift.Value(groupId));
      final to = toLeg.copyWith(transferGroupId: drift.Value(groupId));
      await db.into(db.transactions).insert(from);
      await db.into(db.transactions).insert(to);
    });
  }

  Future<Transaction?> getTransaction(int id) {
    return (db.select(db.transactions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<Transaction>> getTransactionsByGroup(String groupId) {
    return (db.select(db.transactions)..where((t) => t.transferGroupId.equals(groupId)))
        .get();
  }

  // ── Accounts ──

  Stream<List<Account>> watchAccounts() {
    return (db.select(db.accounts)).watch();
  }

  Future<List<Account>> getAllAccounts() {
    return (db.select(db.accounts)).get();
  }

  Future<void> updateAccount(AccountsCompanion account) async {
    await (db.update(db.accounts)..where((a) => a.id.equals(account.id.value)))
        .write(account);
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
            exchangeRateAtCreation: drift.Value(await _getExchangeRateForDate(
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

  /// Set an account's balance to [newBalance] by posting a "Balance
  /// adjustment" transaction for the delta, keeping the ledger consistent.
  Future<void> adjustAccountBalance({
    required int accountId,
    required String currencyCode,
    required double newBalance,
  }) async {
    final current = await getAccountBalance(accountId);
    final delta = newBalance - current;
    if (delta == 0) return;
    await createTransaction(
      TransactionsCompanion(
        amount: drift.Value(delta),
        accountId: drift.Value(accountId),
        currencyCode: drift.Value(currencyCode),
        date: drift.Value(DateTime.now()),
        categoryId: const drift.Value.absent(),
        reference: const drift.Value('Balance adjustment'),
        exchangeRateAtCreation: drift.Value(
            await _getExchangeRateForDate(currencyCode, DateTime.now())),
      ),
    );
  }

  Stream<double> watchAccountBalance(int accountId) {
    final query = db.select(db.transactions)
      ..where((t) => t.accountId.equals(accountId));
    return query
        .watch()
        .map((txs) => txs.fold<double>(0.0, (sum, t) => sum + t.amount));
  }

  // ── Exchange Rates ──

  Future<List<ExchangeRate>> getRatesForCurrency(String currencyCode) {
    return (db.select(db.currencyRates)
          ..where((tbl) => tbl.currencyCode.equals(currencyCode))
          ..orderBy([
            (t) => drift.OrderingTerm(
                expression: t.date, mode: drift.OrderingMode.desc)
          ]))
        .get();
  }

  Stream<List<ExchangeRate>> watchRatesForCurrency(String currencyCode) {
    return (db.select(db.currencyRates)
          ..where((tbl) => tbl.currencyCode.equals(currencyCode))
          ..orderBy([
            (t) => drift.OrderingTerm(
                expression: t.date, mode: drift.OrderingMode.desc)
          ]))
        .watch();
  }

  Future<ExchangeRate?> getLatestRate(String currencyCode) {
    return (db.select(db.currencyRates)
          ..where((r) => r.currencyCode.equals(currencyCode))
          ..orderBy([
            (r) => drift.OrderingTerm(
                expression: r.date, mode: drift.OrderingMode.desc)
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<ExchangeRate?> getRateAtDate(String currencyCode, DateTime date) {
    return (db.select(db.currencyRates)
          ..where((r) =>
              r.currencyCode.equals(currencyCode) &
              r.date.isSmallerOrEqualValue(date))
          ..orderBy([
            (r) => drift.OrderingTerm(
                expression: r.date, mode: drift.OrderingMode.desc)
          ])
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
    return db
        .into(db.currencyRates)
        .insert(rate, mode: drift.InsertMode.insertOrReplace);
  }

  Future<void> addExchangeRatesBatch(List<CurrencyRatesCompanion> rates) {
    return db.batch((batch) {
      batch.insertAll(db.currencyRates, rates,
          mode: drift.InsertMode.insertOrReplace);
    });
  }

  Future<void> deleteExchangeRate(int id) {
    return (db.delete(db.currencyRates)..where((r) => r.id.equals(id))).go();
  }

  // ── Market (P2P) Rates ──

  /// Store the unofficial/parallel VES→USD rate for [rate.date], replacing any
  /// rate already recorded for that day.
  Future<void> addMarketRate(MarketRatesCompanion rate) {
    return db
        .into(db.marketRates)
        .insert(rate, mode: drift.InsertMode.insertOrReplace);
  }

  /// The newest stored market (P2P) rate, or null when none exists.
  Future<MarketRate?> getLatestMarketRate() {
    return (db.select(db.marketRates)
          ..orderBy([
            (r) => drift.OrderingTerm(
                expression: r.date, mode: drift.OrderingMode.desc)
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Market rate at or before [date], falling back to the official BCV rate
  /// when no parallel rate is known for the period.
  Future<double?> getMarketRateWithFallback(DateTime date) async {
    final rate = await (db.select(db.marketRates)
          ..where((r) => r.date.isSmallerOrEqualValue(date))
          ..orderBy([
            (r) => drift.OrderingTerm(
                expression: r.date, mode: drift.OrderingMode.desc)
          ])
          ..limit(1))
        .getSingleOrNull();
    final official = await getRateWithFallback('VES', date);
    return rate?.rate ?? official;
  }

  Future<DateTime?> getLastAutoFetchDate() async {
    final setting = await (db.select(db.userSettings)
          ..where((tbl) => tbl.id.equals(0)))
        .getSingleOrNull();
    return setting?.lastAutoFetchDate;
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
    return (db.select(db.userSettings)..where((tbl) => tbl.id.equals(0)))
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

    await db
        .into(db.userSettings)
        .insert(companion, mode: drift.InsertMode.insertOrReplace);
  }

  Future<void> setBaseCurrency(String currencyCode) {
    return _updateSettings(
        (c) => c.copyWith(baseCurrencyCode: drift.Value(currencyCode)));
  }

  /// Delete the stored profile picture, then reset the whole database to its
  /// fresh-install state (no accounts, transactions, rates or preferences).
  Future<void> wipeAllData() async {
    final setting = await (db.select(db.userSettings)
          ..where((tbl) => tbl.id.equals(0)))
        .getSingleOrNull();
    final profilePicture = setting?.profilePicturePath;
    if (profilePicture != null && profilePicture.isNotEmpty) {
      try {
        await File(profilePicture).delete();
      } catch (_) {
        // File may not exist; clearing the DB is what matters.
      }
    }
    await db.resetAllData();
  }

  /// Patch the settings row (id=0) with only the fields present in [settings],
  /// preserving every other stored value. Uses UPDATE so a partial patch
  /// (e.g. [CurrencyProvider] syncing just `lastAutoFetchDate`) never touches
  /// or requires the other columns.
  Future<void> updateUserSettings(UserSettingsCompanion settings) async {
    final companion = settings.copyWith(id: const drift.Value(0));
    final existing = await (db.select(db.userSettings)
          ..where((tbl) => tbl.id.equals(0)))
        .getSingleOrNull();

    if (existing != null) {
      await (db.update(db.userSettings)..where((tbl) => tbl.id.equals(0)))
          .write(companion);
    } else {
      await db.into(db.userSettings).insert(
            companion.copyWith(
              baseCurrencyCode: const drift.Value('USD'),
              hasCompletedOnboarding: const drift.Value(true),
            ),
            mode: drift.InsertMode.insertOrReplace,
          );
    }
  }

  Future<String?> getProfilePicturePath() async {
    final setting = await (db.select(db.userSettings)
          ..where((tbl) => tbl.id.equals(0)))
        .getSingleOrNull();
    return setting?.profilePicturePath;
  }

  Future<void> saveProfilePicturePath(String path) async {
    final old = await getProfilePicturePath();
    if (old != null && old != path) {
      final file = File(old);
      if (file.existsSync()) file.delete();
    }
    await _updateSettings(
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
    return (db.select(db.currencies)..where((c) => c.code.equals(code)))
        .getSingleOrNull();
  }

  /// Symbol of the base currency, defaulting to '$' when unknown.
  Future<String> getBaseCurrencySymbol() async {
    final code = await getBaseCurrencyCode();
    return (await getCurrency(code))?.symbol ?? r'$';
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

    final amountInBase = await convertAmount(
        amount: amount, fromCode: fromCode, toCode: baseCurrencyCode);
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
      total += await convertForNetWorth(
          amount: balance,
          fromCode: account.currencyCode,
          toCode: toCode);
    }

    return total;
  }

  /// Net-worth aggregation conversion: national-currency (VES) balances are
  /// valued at the parallel/market rate to reflect true replacement value,
  /// falling back to the official BCV rate when no market rate is stored.
  /// Non-national pairs behave exactly like [convertAmount].
  Future<double> convertForNetWorth({
    required double amount,
    required String fromCode,
    required String toCode,
  }) async {
    if (fromCode == toCode) return amount;

    final nationalCode = await getNationalCurrencyCode();
    if (fromCode == nationalCode || toCode == nationalCode) {
      final marketRate = await getMarketRateWithFallback(DateTime.now());
      if (marketRate != null && marketRate > 0) {
        if (fromCode == nationalCode) return amount / marketRate;
        return amount * marketRate;
      }
    }

    return convertAmount(amount: amount, fromCode: fromCode, toCode: toCode);
  }

  // ── Net Worth History ──

  Stream<List<NetWorthHistoryData>> watchNetWorthHistory({int limit = 90}) {
    return (db.select(db.netWorthHistory)
          ..orderBy([
            (n) => drift.OrderingTerm(
                expression: n.date, mode: drift.OrderingMode.desc)
          ])
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
      ..where((t) => t.date
          .isBetween(drift.Variable(startOfMonth), drift.Variable(endOfMonth)) &
          // Transfers only move money between the user's own accounts; they
          // are neither income nor expense and must not bend the summary.
          t.transferGroupId.isNull());

    return db.transaction(() async {
      final transactionsInMonth = await query.get();
      double totalIncome = 0;
      double totalExpenses = 0;
      double totalFxImpact = 0;

      for (final t in transactionsInMonth) {
        final baseAmount = await toBaseAmount(t);
        if (baseAmount > 0) {
          totalIncome += baseAmount;
        } else {
          totalExpenses += baseAmount.abs();
        }
        totalFxImpact += t.fxDelta ?? 0;
      }
      return MonthlySummary(
          income: totalIncome,
          expenses: totalExpenses,
          fxImpact: totalFxImpact);
    }).asStream();
  }
}
