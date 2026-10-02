import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:finance_mvp/database/app_database.dart';
import 'package:finance_mvp/services/finance/currency_converter.dart';
import 'package:finance_mvp/services/finance/recurrence.dart';

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

  Map<String, int>? _decimalDigitsCache;

  // ── Transactions ──

  Stream<List<Transaction>> watchTransactions() {
    return (db.select(db.transactions)).watch();
  }

  Future<void> createTransaction(TransactionsCompanion transaction) async {
    await db.into(db.transactions).insert(transaction);
    await _syncDebtSettlement(transaction.debtId.value);
  }

  /// Persist a transaction and its related debt (with the installment
  /// schedule, if the payment is split) atomically, so a failure mid-save
  /// can't leave the payment recorded but no debt behind. The new debt is
  /// linked from the transaction via [Transactions.sourceDebtId].
  Future<void> createTransactionWithDebt(
    TransactionsCompanion transaction,
    DebtsCompanion debt,
    List<DebtInstallmentsCompanion> installments,
  ) {
    return db.transaction(() async {
      final debtId = await db.into(db.debts).insert(debt);
      await db.into(db.transactions).insert(
          transaction.copyWith(sourceDebtId: drift.Value(debtId)));
      for (final installment in installments) {
        await db.into(db.debtInstallments).insert(
            installment.copyWith(debtId: drift.Value(debtId)));
      }
    });
  }

  /// Update a transaction and, when it was the source of a debt, re-sync that
  /// debt and its quota schedule with the edited values. The transaction row
  /// is written with insertOrReplace (same as [updateTransaction]) so streams
  /// watching it fire.
  Future<void> updateTransactionWithDebt(
    TransactionsCompanion transaction,
    int debtId,
    Debt debt,
    List<DebtInstallmentsCompanion> installments,
  ) {
    return db.transaction(() async {
      await db.into(db.transactions).insert(
          transaction.copyWith(sourceDebtId: drift.Value(debtId)),
          mode: drift.InsertMode.insertOrReplace);
      await db.update(db.debts).replace(debt);
      await (db.delete(db.debtInstallments)
            ..where((t) => t.debtId.equals(debtId)))
          .go();
      for (final installment in installments) {
        await db.into(db.debtInstallments).insert(
            installment.copyWith(debtId: drift.Value(debtId)));
      }
      // This transaction may itself be a payment against another debt.
      await _syncDebtSettlement(transaction.debtId.value);
    });
  }

  /// Insert a debt and its quota schedule in one transaction. Returns the new
  /// debt id, wired into every installment row.
  Future<int> createDebtWithInstallments(
    DebtsCompanion debt,
    List<DebtInstallmentsCompanion> installments,
  ) {
    return db.transaction(() async {
      final debtId = await db.into(db.debts).insert(debt);
      for (final installment in installments) {
        await db.into(db.debtInstallments).insert(
            installment.copyWith(debtId: drift.Value(debtId)));
      }
      return debtId;
    });
  }

  Future<void> updateTransaction(TransactionsCompanion transaction) async {
    await db.into(db.transactions).insert(
          transaction,
          mode: drift.InsertMode.insertOrReplace,
        );
    await _syncDebtSettlement(transaction.debtId.value);
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
    // Removing the last payment reopens a debt that had auto-settled.
    await _syncDebtSettlement(existing.debtId);
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

  /// Minor-unit scale of [currencyCode] — how many decimal places money in it
  /// is actually divisible to. Drives [quantizeTo] at the money boundaries;
  /// not a display setting. Cached because conversions read it per call.
  Future<int> getDecimalDigits(String currencyCode) async {
    _decimalDigitsCache ??= {
      for (final c in await getAllCurrencies()) c.code: c.decimalDigits,
    };
    return _decimalDigitsCache![currencyCode] ?? 2;
  }

  /// Forget the cached scales after a currency is added or edited.
  void invalidateCurrencyScales() => _decimalDigitsCache = null;

  Future<void> addCurrency(CurrenciesCompanion currency) {
    invalidateCurrencyScales();
    return db.into(db.currencies).insert(currency);
  }

  // ── Categories ──

  Stream<List<Category>> watchCategories() {
    return (db.select(db.categories)).watch();
  }

  Future<List<Category>> getAllCategories() {
    return (db.select(db.categories)).get();
  }

  // ── Contacts ──

  Future<List<Contact>> getAllContacts() {
    return (db.select(db.contacts)).get();
  }

  Future<Contact?> getContactById(int id) {
    return (db.select(db.contacts)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  /// Returns the existing contact with that exact name, or creates it. A
  /// [phone] is only stored on creation.
  Future<Contact> findOrCreateContact(String name, {String? phone}) async {
    final trimmed = name.trim();
    final existing = await (db.select(db.contacts)
          ..where((c) => c.name.equals(trimmed)))
        .getSingleOrNull();
    if (existing != null) return existing;
    return db.into(db.contacts).insertReturning(
        ContactsCompanion.insert(name: trimmed, phone: drift.Value(phone)));
  }

  Future<void> updateContact(Contact contact) =>
      db.update(db.contacts).replace(contact);

  /// Unlinks live transactions before removing the contact row (FK guard).
  Future<void> deleteContact(int id) => db.transaction(() async {
        await (db.update(db.transactions)
              ..where((t) => t.contactId.equals(id)))
            .write(
                const TransactionsCompanion(contactId: drift.Value(null)));
        await (db.delete(db.contacts)..where((c) => c.id.equals(id))).go();
      });

  // ── Debts ──

  Future<List<Debt>> getAllDebts() => (db.select(db.debts)).get();

  Future<Debt?> getDebtById(int id) {
    return (db.select(db.debts)..where((d) => d.id.equals(id)))
        .getSingleOrNull();
  }

  /// Transactions recorded as payments against this debt (newest first).
  Future<List<Transaction>> getTransactionsForDebt(int debtId) {
    final query = db.select(db.transactions)
      ..where((t) => t.debtId.equals(debtId))
      ..orderBy([(t) => drift.OrderingTerm.desc(t.date)]);
    return query.get();
  }

  Future<void> addDebt(DebtsCompanion debt) => db.into(db.debts).insert(debt);

  Future<void> updateDebt(Debt debt) => db.update(db.debts).replace(debt);

  /// The quota schedule of a split debt, in payment order.
  Future<List<DebtInstallment>> getDebtInstallments(int debtId) {
    final query = db.select(db.debtInstallments)
      ..where((t) => t.debtId.equals(debtId))
      ..orderBy([(t) => drift.OrderingTerm.asc(t.index)]);
    return query.get();
  }

  /// Deletes a debt (and its installment schedule) and unlinks both the
  /// transactions linked as payments and the one that sourced the debt, so no
  /// FK reference is left dangling.
  Future<void> deleteDebt(int id) => db.transaction(() async {
        await (db.delete(db.debtInstallments)
              ..where((t) => t.debtId.equals(id)))
            .go();
        await (db.update(db.transactions)
              ..where((t) => t.debtId.equals(id)))
            .write(const TransactionsCompanion(debtId: drift.Value(null)));
        await (db.update(db.transactions)
              ..where((t) => t.sourceDebtId.equals(id)))
            .write(
                const TransactionsCompanion(sourceDebtId: drift.Value(null)));
        await (db.delete(db.debts)..where((d) => d.id.equals(id))).go();
      });

  /// Outstanding balance of a debt: original [Debt.amount] minus the total
  /// value of transactions linked as payments, expressed in the debt's
  /// currency. Payments are valued from each transaction's base-currency
  /// amount (rate at transaction creation), then converted to the debt
  /// currency at today's rate when they differ.
  Future<double> getDebtRemaining(Debt debt) async {
    final payments = await (db.select(db.transactions)
          ..where((t) => t.debtId.equals(debt.id)))
        .get();
    final base = await getBaseCurrencyCode();

    var paidInBase = 0.0;
    for (final tx in payments) {
      final inBase = tx.baseCurrencyAmount ??
          (tx.currencyCode == base
              ? tx.amount
              : await convertAmount(
                  amount: tx.amount, fromCode: tx.currencyCode,
                  toCode: base));
      paidInBase += inBase.abs();
    }

    final paidInDebtCurrency = debt.currencyCode == base
        ? paidInBase
        : await convertAmount(
            amount: paidInBase, fromCode: base, toCode: debt.currencyCode);
    // Snapped to the debt currency's minor unit: this value is compared
    // against zero to decide whether the debt is settled, so a converted
    // remainder like 1.4e-14 must not survive as "still owed".
    return quantizeTo(debt.amount - paidInDebtCurrency,
        await getDecimalDigits(debt.currencyCode))
        .clamp(0.0, debt.amount);
  }

  /// Keep a debt's `isSettled` in step with what has actually been paid:
  /// settles at zero, reopens once a payment is removed. Called from the
  /// transaction write/delete paths, so the flag is correct the moment a
  /// payment is recorded rather than the next time the debts list is opened.
  Future<void> _syncDebtSettlement(int? debtId) async {
    if (debtId == null) return;
    final debt = await getDebtById(debtId);
    if (debt == null) return;
    final settled = await getDebtRemaining(debt) <= 0;
    if (debt.isSettled == settled) return;
    await updateDebt(debt.copyWith(isSettled: settled));
  }

  /// Totals of unpaid debts in the base currency: [owedToMe] is what others
  /// owe me, [owedByMe] what I owe others. Fully paid and manually settled
  /// debts are excluded.
  Future<({double owedToMe, double owedByMe})> getOpenDebtTotalsInBase() async {
    final base = await getBaseCurrencyCode();
    final debts =
        await (db.select(db.debts)..where((d) => d.isSettled.equals(false)))
            .get();
    double owedToMe = 0, owedByMe = 0;
    for (final debt in debts) {
      final remaining = await getDebtRemaining(debt);
      if (remaining <= 0) continue;
      final inBase = await convertAmount(
        amount: remaining,
        fromCode: debt.currencyCode,
        toCode: base,
      );
      if (debt.direction == 'creditor') {
        owedByMe += inBase;
      } else {
        owedToMe += inBase;
      }
    }
    return (owedToMe: owedToMe, owedByMe: owedByMe);
  }

  // ── Recurring Transactions ──

  /// Materialise every occurrence of every enabled recurrence that has come
  /// due on or before [now], and return how many transactions were created.
  ///
  /// Safe to call as often as you like: it counts from
  /// [Transactions.recurrenceGeneratedCount], so a second run on the same day
  /// creates nothing.
  Future<int> materializeDueRecurrences({DateTime? now}) async {
    final today = DateTime(now?.year ?? DateTime.now().year,
        now?.month ?? DateTime.now().month, now?.day ?? DateTime.now().day);

    // Templates only: a generated occurrence has recurrenceParentId set, and
    // recurrence disabled, so it can never act as its own series.
    final templates = await (db.select(db.transactions)
          ..where((t) =>
              t.isRecurrenceEnabled.equals(true) &
              t.recurrenceParentId.isNull()))
        .get();

    var created = 0;
    for (final t in templates) {
      final rule = _ruleOf(t);
      if (rule == null) continue;

      var index = t.recurrenceGeneratedCount + 1;
      var made = 0;
      while (made < maxOccurrencesPerRun) {
        final due = rule.occurrence(index);
        if (due == null || due.isAfter(today)) break;
        await db.into(db.transactions).insert(_occurrenceOf(t, due));
        made++;
        index++;
      }

      if (made > 0) {
        created += made;
        await (db.update(db.transactions)
              ..where((row) => row.id.equals(t.id)))
            .write(TransactionsCompanion(
                recurrenceGeneratedCount: drift.Value(t.recurrenceGeneratedCount + made)));
      }
    }
    return created;
  }

  /// Ceiling on occurrences generated per series per run. A daily recurrence
  /// untouched for a year would otherwise dump 365 rows into the ledger the
  /// first time the app opens; the rest catch up on later opens.
  static const maxOccurrencesPerRun = 12;

  /// The rule described by a stored transaction, or null when it isn't a
  /// usable series (no recognised type).
  static Recurrence? _ruleOf(Transaction t) {
    final type = RecurrenceType.tryParse(t.recurrenceType);
    if (type == null) return null;
    return Recurrence(
      type: type,
      anchor: DateTime(t.date.year, t.date.month, t.date.day),
      interval: t.recurrenceInterval,
      end: RecurrenceEnd.tryParse(t.recurrenceEnds),
      endDate: t.recurrenceEndDate,
      totalCount: t.recurrenceTotalCount,
    );
  }

  /// A generated occurrence: the template's money and description, stamped with
  /// its own date and pointed back at the template.
  ///
  /// The captured FX fields are deliberately left null so balance reads
  /// re-derive them at the rate for *this* date — reusing the rate the template
  /// was saved at would value a two-year-old rent payment at today's rate.
  ///
  /// Debt and source-debt links are not carried over either: an occurrence the
  /// user never confirmed shouldn't quietly move a debt balance.
  TransactionsCompanion _occurrenceOf(Transaction t, DateTime date) {
    return TransactionsCompanion.insert(
      amount: t.amount,
      categoryId: drift.Value(t.categoryId),
      accountId: t.accountId,
      currencyCode: t.currencyCode,
      reference: drift.Value(t.reference),
      contactId: drift.Value(t.contactId),
      imagePath: drift.Value(t.imagePath),
      isRecurrenceEnabled: const drift.Value(false),
      recurrenceParentId: drift.Value(t.id),
      date: date,
    );
  }

  /// The next due date for a recurrence template, for display. Null when the
  /// series is over.
  Future<DateTime?> getNextOccurrence(Transaction template, {DateTime? from}) async {
    final rule = _ruleOf(template);
    if (rule == null) return null;
    return rule.nextOccurrenceOnOrAfter(from ?? DateTime.now());
  }

  // ── Currency Conversion ──

  /// Convert [amount] between two currencies at the latest stored rate.
  ///
  /// The result is quantized to the *target* currency's minor unit, so a value
  /// that no longer exists in the target's scale (0.001 USD) never becomes a
  /// stored balance or a debt payment.
  Future<double> convertAmount({
    required double amount,
    required String fromCode,
    required String toCode,
  }) async {
    if (fromCode == toCode) return amount;

    final baseCurrencyCode = await getBaseCurrencyCode();

    if (toCode == baseCurrencyCode) {
      final rate = await getLatestRate(fromCode);
      return _quantizeIn(rate != null ? amount / rate.rate : amount, toCode);
    }

    if (fromCode == baseCurrencyCode) {
      final rate = await getLatestRate(toCode);
      return _quantizeIn(rate != null ? amount * rate.rate : amount, toCode);
    }

    final amountInBase = await convertAmount(
        amount: amount, fromCode: fromCode, toCode: baseCurrencyCode);
    return await convertAmount(
        amount: amountInBase, fromCode: baseCurrencyCode, toCode: toCode);
  }

  /// Round [value] to [code]'s minor unit. Every converted amount goes through
  /// here so float residue never leaves this class.
  Future<double> _quantizeIn(double value, String code) async =>
      quantizeTo(value, await getDecimalDigits(code));

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
        return _quantizeIn(
            fromCode == nationalCode ? amount / marketRate : amount * marketRate,
            toCode);
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
  /// at creation time (falls back to the latest stored rate). Quantized to the
  /// base currency's minor unit so the monthly summary doesn't accumulate
  /// per-row conversion residue.
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
