import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:finance_mvp/database/app_database.dart';
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_db.dart';

void main() {
  setUpAll(() => useSystemSqlite());

  late AppDatabase db;
  late FinanceRepository repo;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    repo = FinanceRepository(db);
  });

  tearDown(() => db.close());

  test('seeds default currencies, categories and settings', () async {
    final currencies = await repo.getAllCurrencies();
    final codes = currencies.map((c) => c.code).toSet();
    expect(codes, contains('USD'));
    expect(codes, contains('VES'));
    expect(codes, contains('EUR'));

    final categories = await repo.getAllCategories();
    expect(categories.length, 10);

    expect(await repo.getBaseCurrencyCode(), 'USD');
    expect(await repo.getNationalCurrencyCode(), 'VES');
    expect(await repo.getHasCompletedOnboarding(), isFalse);
  });

  test('updateUserSettings persists onboarding + profile fields', () async {
    await repo.addCurrency(CurrenciesCompanion.insert(
      code: 'MXN',
      name: 'Mexican Peso',
      symbol: r'$',
    ));

    await repo.updateUserSettings(const UserSettingsCompanion(
      username: drift.Value('Ana'),
      baseCurrencyCode: drift.Value('EUR'),
      nationalCurrencyCode: drift.Value('MXN'),
      currencySelectionMode: drift.Value('manual'),
      hasCompletedOnboarding: drift.Value(true),
    ));

    expect(await repo.getBaseCurrencyCode(), 'EUR');
    expect(await repo.getNationalCurrencyCode(), 'MXN');
    expect(await repo.getHasCompletedOnboarding(), isTrue);

    final settings = await repo.watchUserSettings().first;
    expect(settings!.username, 'Ana');
    expect(settings.currencySelectionMode, 'manual');
  });

  test('rate lookup picks the closest stored rate at or before a date',
      () async {
    final older = DateTime(2026, 1, 1);
    final newer = DateTime(2026, 1, 10);

    await repo.addExchangeRate(CurrencyRatesCompanion.insert(
      currencyCode: 'EUR',
      rate: 1.1,
      date: older,
    ));
    await repo.addExchangeRate(CurrencyRatesCompanion.insert(
      currencyCode: 'EUR',
      rate: 1.2,
      date: newer,
    ));

    final rate = await repo.getRateAtDate('EUR', DateTime(2026, 1, 5));
    expect(rate!.rate, 1.1);

    final after = await repo.getRateAtDate('EUR', DateTime(2026, 1, 15));
    expect(after!.rate, 1.2);
  });

  test('edit updates the same row and delete removes it', () async {
    await repo.addExchangeRate(CurrencyRatesCompanion.insert(
      currencyCode: 'EUR',
      rate: 1.1,
      date: DateTime(2026, 2, 1),
    ));
    await repo.addExchangeRate(CurrencyRatesCompanion.insert(
      currencyCode: 'EUR',
      rate: 1.2,
      date: DateTime(2026, 2, 2),
    ));

    final rates = await repo.getRatesForCurrency('EUR');
    expect(rates, hasLength(2));

    final first = rates.first;
    final edited = CurrencyRatesCompanion(
      id: drift.Value(first.id),
      currencyCode: drift.Value(first.currencyCode),
      rate: const drift.Value(1.15),
      date: drift.Value(first.date),
    );
    await repo.addExchangeRate(edited);

    final afterEdit = await repo.getRatesForCurrency('EUR');
    expect(afterEdit, hasLength(2));
    expect(afterEdit.first.id, first.id);
    expect(afterEdit.first.rate, 1.15);

    await repo.deleteExchangeRate(first.id);
    final afterDelete = await repo.getRatesForCurrency('EUR');
    expect(afterDelete, hasLength(1));
    expect(afterDelete.first.id, isNot(first.id));
  });

  test('partial settings patch preserves other stored values', () async {
    await repo.updateUserSettings(const UserSettingsCompanion(
      username: drift.Value('Ana'),
      baseCurrencyCode: drift.Value('USD'),
      nationalCurrencyCode: drift.Value('VES'),
      currencySelectionMode: drift.Value('manual'),
      hasCompletedOnboarding: drift.Value(true),
    ));

    await repo.updateUserSettings(UserSettingsCompanion(
      currencySelectionMode: const drift.Value('auto'),
      lastAutoFetchDate: drift.Value(DateTime(2026, 9, 11, 23, 33)),
    ));

    final setting = await repo.watchUserSettings().first;
    expect(setting!.username, 'Ana');
    expect(setting.baseCurrencyCode, 'USD');
    expect(setting.nationalCurrencyCode, 'VES');
    expect(setting.currencySelectionMode, 'auto');
    expect(setting.lastAutoFetchDate, DateTime(2026, 9, 11, 23, 33));
    expect(setting.hasCompletedOnboarding, isTrue);
  });

  test('adjustAccountBalance posts a delta transaction', () async {
    await repo.createAccountWithInitialTransaction(
      AccountsCompanion.insert(
        name: 'Cash',
        currencyCode: 'USD',
        icon: 'cash',
        iconColor: 0xFF4CAF50,
      ),
      100,
    );

    final account = (await repo.getAllAccounts()).first;
    expect(await repo.getAccountBalance(account.id), 100);

    await repo.adjustAccountBalance(
        accountId: account.id, currencyCode: 'USD', newBalance: 250);
    expect(await repo.getAccountBalance(account.id), 250);

    await repo.adjustAccountBalance(
        accountId: account.id, currencyCode: 'USD', newBalance: 250);
    final txs = await repo.watchTransactions().first;
    expect(txs.where((t) => t.accountId == account.id).length, 2);

    await repo.adjustAccountBalance(
        accountId: account.id, currencyCode: 'USD', newBalance: 150);
    expect(await repo.getAccountBalance(account.id), 150);
  });

  test('updateAccount patches name, icon and inclusion flag', () async {
    await repo.createAccountWithInitialTransaction(
      AccountsCompanion.insert(
        name: 'Cash',
        currencyCode: 'USD',
        icon: 'cash',
        iconColor: 0xFF4CAF50,
      ),
      100,
    );

    var account = (await repo.getAllAccounts()).first;
    expect(account.includeInRevaluation, isTrue);

    await repo.updateAccount(AccountsCompanion(
      id: drift.Value(account.id),
      name: const drift.Value('Wallet'),
      icon: const drift.Value('bank'),
      iconColor: const drift.Value(0xFF2196F3),
      includeInRevaluation: const drift.Value(false),
    ));

    account = (await repo.getAllAccounts()).first;
    expect(account.name, 'Wallet');
    expect(account.icon, 'bank');
    expect(account.iconColor, 0xFF2196F3);
    expect(account.includeInRevaluation, isFalse);
  });

  test('wipeAllData clears everything and restores fresh-install state',
      () async {
    await repo.addCurrency(CurrenciesCompanion.insert(
      code: 'MXN',
      name: 'Mexican Peso',
      symbol: r'$',
    ));
    await repo.createAccountWithInitialTransaction(
      AccountsCompanion.insert(
        name: 'Cash',
        currencyCode: 'MXN',
        icon: 'cash',
        iconColor: 0xFF4CAF50,
      ),
      100,
    );
    await repo.addExchangeRate(CurrencyRatesCompanion.insert(
      currencyCode: 'MXN',
      rate: 18.5,
      date: DateTime(2026, 1, 1),
    ));
    await repo.updateUserSettings(const UserSettingsCompanion(
      username: drift.Value('Ana'),
      baseCurrencyCode: drift.Value('MXN'),
      currencySelectionMode: drift.Value('manual'),
      hasCompletedOnboarding: drift.Value(true),
    ));

    // Contacts, debts and their quota schedule are wiped too — a "delete
    // everything" that leaves the ledger behind is a data-loss bug in the
    // other direction.
    final contact = await repo.findOrCreateContact('Ana', phone: '555');
    final debtId = await repo.createDebtWithInstallments(
      DebtsCompanion.insert(
        contactId: drift.Value(contact.id),
        amount: 100,
        currencyCode: 'MXN',
        date: DateTime(2026, 1, 1),
      ),
      [
        DebtInstallmentsCompanion.insert(
          debtId: 0,
          index: 0,
          amount: 50,
          dueDate: DateTime(2026, 2, 1),
        ),
        DebtInstallmentsCompanion.insert(
          debtId: 0,
          index: 1,
          amount: 50,
          dueDate: DateTime(2026, 3, 1),
        ),
      ],
    );
    expect(await repo.getDebtInstallments(debtId), hasLength(2));

    await repo.wipeAllData();

    expect(await repo.getAllAccounts(), isEmpty);
    expect((await repo.watchTransactions().first)
        .where((t) => t.accountId > 0), isEmpty);
    expect(await repo.getRatesForCurrency('MXN'), isEmpty);
    expect(await repo.getAllContacts(), isEmpty);
    expect(await repo.getAllDebts(), isEmpty);
    expect(await repo.getDebtInstallments(debtId), isEmpty);

    final currencies = await repo.getAllCurrencies();
    final codes = currencies.map((c) => c.code).toSet();
    expect(codes, {'USD', 'VES', 'EUR'});
    expect((await repo.getAllCategories()).length, 10);

    final setting = await repo.watchUserSettings().first;
    expect(setting!.username, 'User');
    expect(setting.baseCurrencyCode, 'USD');
    expect(setting.hasCompletedOnboarding, isFalse);
  });

  test('calculateTotalBalance converts all accounts to the target currency',
      () async {
    await repo.updateUserSettings(const UserSettingsCompanion(
      baseCurrencyCode: drift.Value('USD'),
      nationalCurrencyCode: drift.Value('VES'),
    ));

    await repo.addExchangeRate(CurrencyRatesCompanion.insert(
      currencyCode: 'VES',
      rate: 40.0,
      date: DateTime.now(),
    ));

    await repo.createAccountWithInitialTransaction(
      AccountsCompanion.insert(
        name: 'Cash',
        currencyCode: 'USD',
        icon: 'payments',
        iconColor: 0xFF4CAF50,
      ),
      100,
    );

    await repo.createAccountWithInitialTransaction(
      AccountsCompanion.insert(
        name: 'Bolivares',
        currencyCode: 'VES',
        icon: 'account_balance_wallet',
        iconColor: 0xFF2196F3,
      ),
      4000,
    );

    expect(await repo.calculateTotalBalance('USD'), closeTo(200, 0.001));
    expect(await repo.calculateTotalBalance('VES'), closeTo(8000, 0.001));
  });

  test('calculateTotalBalance values VES at the market rate when stored',
      () async {
    await repo.addExchangeRate(CurrencyRatesCompanion.insert(
      currencyCode: 'VES',
      rate: 36.5,
      date: DateTime.now(),
    ));
    await repo.addMarketRate(MarketRatesCompanion.insert(
      rate: 40.0,
      date: DateTime.now(),
    ));

    await repo.createAccountWithInitialTransaction(
      AccountsCompanion.insert(
        name: 'Cash',
        currencyCode: 'USD',
        icon: 'cash',
        iconColor: 0xFF4CAF50,
      ),
      60,
    );

    await repo.createAccountWithInitialTransaction(
      AccountsCompanion.insert(
        name: 'Bolivares',
        currencyCode: 'VES',
        icon: 'account_balance_wallet',
        iconColor: 0xFF2196F3,
      ),
      4000,
    );

    // 60 USD + 4000 VES at the market rate (40) = 160 USD.
    expect(await repo.calculateTotalBalance('USD'), closeTo(160, 0.001));
  });

  test('market rates are stored and fall back to the official rate', () async {
    expect(await repo.getLatestMarketRate(), isNull);

    await repo.addExchangeRate(CurrencyRatesCompanion.insert(
      currencyCode: 'VES',
      rate: 36.5,
      date: DateTime(2026, 1, 1),
    ));
    expect(await repo.getMarketRateWithFallback(DateTime(2026, 1, 10)),
        closeTo(36.5, 0.001));

    await repo.addMarketRate(MarketRatesCompanion.insert(
      rate: 40.0,
      date: DateTime(2026, 1, 10),
    ));
    expect((await repo.getLatestMarketRate())!.rate, closeTo(40, 0.001));
    expect(await repo.getMarketRateWithFallback(DateTime(2026, 1, 10)),
        closeTo(40, 0.001));
  });

  test('monthly summary sums fxDelta into fxImpact', () async {
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
    await repo.createTransaction(TransactionsCompanion(
      amount: const drift.Value(-2000),
      accountId: drift.Value(account.id),
      currencyCode: const drift.Value('USD'),
      date: drift.Value(now),
      fxDelta: const drift.Value(15.0),
    ));
    await repo.createTransaction(TransactionsCompanion(
      amount: const drift.Value(-1000),
      accountId: drift.Value(account.id),
      currencyCode: const drift.Value('USD'),
      date: drift.Value(now),
      fxDelta: const drift.Value(8.0),
    ));
    // Outside the current month: must not affect the aggregate.
    await repo.createTransaction(TransactionsCompanion(
      amount: const drift.Value(-500),
      accountId: drift.Value(account.id),
      currencyCode: const drift.Value('USD'),
      date: drift.Value(DateTime(now.year - 1, now.month, now.day)),
      fxDelta: const drift.Value(99.0),
    ));

    final summary = await repo.watchMonthlySummary(now).first;
    expect(summary.income, 0);
    expect(summary.expenses, closeTo(3000, 0.001));
    expect(summary.fxImpact, closeTo(23, 0.001));
  });

  test(
      'transfer legs are linked, ignored by the monthly summary and deleted as a pair',
      () async {
    await repo.createAccountWithInitialTransaction(
      AccountsCompanion.insert(
        name: 'Src',
        currencyCode: 'VES',
        icon: 'payments',
        iconColor: 0xFF4CAF50,
      ),
      0,
    );
    await repo.createAccountWithInitialTransaction(
      AccountsCompanion.insert(
        name: 'Dst',
        currencyCode: 'USD',
        icon: 'payments',
        iconColor: 0xFF4CAF50,
      ),
      0,
    );
    final accounts = await repo.getAllAccounts();
    final ves = accounts.firstWhere((a) => a.currencyCode == 'VES');
    final usd = accounts.firstWhere((a) => a.currencyCode == 'USD');

    await repo.addExchangeRate(CurrencyRatesCompanion.insert(
      currencyCode: 'VES',
      rate: 36.5,
      date: DateTime.now(),
    ));

    const groupId = 'g-42';
    await repo.createTransfer(
      groupId: groupId,
      fromLeg: TransactionsCompanion(
        amount: const drift.Value(-2000),
        accountId: drift.Value(ves.id),
        currencyCode: const drift.Value('VES'),
        date: drift.Value(DateTime.now()),
        exchangeRateAtCreation: const drift.Value(40.0),
        baseCurrencyAmount: const drift.Value(-50.0),
        fxDelta: const drift.Value(4.7945),
      ),
      toLeg: TransactionsCompanion(
        amount: const drift.Value(50),
        accountId: drift.Value(usd.id),
        currencyCode: const drift.Value('USD'),
        date: drift.Value(DateTime.now()),
        baseCurrencyAmount: const drift.Value(50.0),
      ),
    );

    final txs = await repo.watchTransactions().first;
    expect(txs, hasLength(2));
    expect(txs.every((t) => t.transferGroupId == groupId), isTrue);

    // Transfers move money between the user's own accounts: neither income,
    // expense nor FX impact.
    final summary = await repo.watchMonthlySummary(DateTime.now()).first;
    expect(summary.income, 0);
    expect(summary.expenses, 0);
    expect(summary.fxImpact, 0);

    // Deleting one leg must remove the whole pair.
    await repo.deleteTransaction(txs.first.id);
    expect(await repo.watchTransactions().first, isEmpty);
  });

  test('updateTransaction edits an existing payment and deleteTransaction removes it',
      () async {
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

    await repo.createTransaction(TransactionsCompanion(
      amount: const drift.Value(100.0),
      accountId: drift.Value(account.id),
      currencyCode: const drift.Value('USD'),
      date: drift.Value(DateTime(2026, 1, 1)),
      reference: const drift.Value('Rent'),
    ));

    final created = (await repo.db.select(repo.db.transactions).get()).single;
    expect(created.amount, closeTo(100.0, 0.001));

    await repo.updateTransaction(TransactionsCompanion(
      id: drift.Value(created.id),
      amount: const drift.Value(250.0),
      accountId: drift.Value(created.accountId),
      currencyCode: drift.Value(created.currencyCode),
      date: drift.Value(created.date),
      reference: const drift.Value('Rent (edited)'),
    ));

    final updated = (await repo.db.select(repo.db.transactions).get()).single;
    expect(updated.id, created.id);
    expect(updated.amount, closeTo(250.0, 0.001));
    expect(updated.reference, 'Rent (edited)');

    await repo.deleteTransaction(created.id);
    expect(await repo.db.select(repo.db.transactions).get(), isEmpty);
  });

  test('saveProfilePicturePath preserves other settings', () async {
    await repo.updateUserSettings(const UserSettingsCompanion(
      username: drift.Value('Tester'),
      baseCurrencyCode: drift.Value('USD'),
      nationalCurrencyCode: drift.Value('VES'),
      currencySelectionMode: drift.Value('manual'),
      hasCompletedOnboarding: drift.Value(true),
    ));

    await repo.saveProfilePicturePath('/tmp/pic.jpg');

    final settings =
        (await repo.db.select(repo.db.userSettings).get()).single;
    expect(settings.baseCurrencyCode, 'USD');
    expect(settings.nationalCurrencyCode, 'VES');
    expect(settings.username, 'Tester');
    expect(settings.currencySelectionMode, 'manual');
    expect(settings.hasCompletedOnboarding, isTrue);
    expect(settings.profilePicturePath, '/tmp/pic.jpg');
  });

  test('linked transactions reduce a debt and its open totals', () async {
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

    await repo.addDebt(DebtsCompanion.insert(
      direction: const drift.Value('debtor'),
      amount: 100,
      currencyCode: 'USD',
      date: DateTime(2026, 1, 1),
    ));
    final debt = (await repo.getAllDebts()).single;
    expect(await repo.getDebtRemaining(debt), closeTo(100, 0.001));

    Future<void> pay(double amount) => repo.createTransaction(
        TransactionsCompanion(
          amount: drift.Value(-amount),
          accountId: drift.Value(account.id),
          currencyCode: const drift.Value('USD'),
          date: drift.Value(DateTime(2026, 2, 1)),
          debtId: drift.Value(debt.id),
        ));

    await pay(40);
    expect(await repo.getDebtRemaining((await repo.getDebtById(debt.id))!),
        closeTo(60, 0.001));
    expect((await repo.getOpenDebtTotalsInBase()).owedToMe, closeTo(60, 0.001));

    // Another expense in a different currency is converted to the debt's
    // currency for the balance, and still counts in base totals.
    await repo.addCurrency(CurrenciesCompanion.insert(
      code: 'MXN',
      name: 'Mexican Peso',
      symbol: r'$',
    ));
    await repo.addExchangeRate(CurrencyRatesCompanion.insert(
      currencyCode: 'MXN',
      rate: 20.0,
      date: DateTime(2026, 2, 1),
    ));
    await repo.createTransaction(TransactionsCompanion(
      amount: const drift.Value(-200),
      accountId: drift.Value(account.id),
      currencyCode: const drift.Value('MXN'),
      date: drift.Value(DateTime(2026, 2, 2)),
      debtId: drift.Value(debt.id),
    ));
    // 200 MXN @ 20 = 10 USD paid toward a USD debt.
    expect(await repo.getDebtRemaining((await repo.getDebtById(debt.id))!),
        closeTo(50, 0.001));

    // Full repayment auto-empties the balance and drops it from totals.
    await pay(50);
    expect(await repo.getDebtRemaining((await repo.getDebtById(debt.id))!),
        closeTo(0, 0.001));
    expect((await repo.getOpenDebtTotalsInBase()).owedToMe, closeTo(0, 0.001));
  });

  test('debt remaining always lands on the currency minor-unit grid', () async {
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
    await repo.addCurrency(CurrenciesCompanion.insert(
      code: 'MXN',
      name: 'Mexican Peso',
      symbol: r'$',
    ));
    await repo.addExchangeRate(CurrencyRatesCompanion.insert(
      currencyCode: 'MXN',
      rate: 3.7,
      date: DateTime(2026, 1, 1),
    ));

    await repo.addDebt(DebtsCompanion.insert(
      amount: 100,
      currencyCode: 'USD',
      date: DateTime(2026, 1, 1),
    ));
    final debt = (await repo.getAllDebts()).single;

    // Two instalments that are exactly 100 USD apart at 3.7 (40 + 330 = 370),
    // but each stores its own raw division, so the paid total sums to
    // 99.99999999999999. The comparison that decides "is this settled?" runs
    // on that number, so it has to be on the currency's grid or a fully paid
    // debt never closes.
    Future<void> pay(double amount) => repo.createTransaction(
          TransactionsCompanion.insert(
            amount: -amount,
            accountId: account.id,
            currencyCode: 'MXN',
            date: DateTime(2026, 2, 1),
            baseCurrencyAmount: drift.Value(amount / 3.7),
            debtId: drift.Value(debt.id),
          ),
        );

    await pay(40);
    await pay(330);

    final remaining =
        await repo.getDebtRemaining((await repo.getDebtById(debt.id))!);
    // On the cent grid: multiplying by 100 leaves no fractional part.
    expect(remaining * 100, closeTo(remaining * 100, 1e-9));
    expect((await repo.getOpenDebtTotalsInBase()).owedToMe,
        closeTo(remaining, 1e-9));
    // Fully paid, so closed rather than left owing a ten-millionth of a cent.
    expect(remaining, 0);
    expect((await repo.getDebtById(debt.id))!.isSettled, isTrue);
  });

  test('conversions snap to the target currency minor unit', () async {
    await repo.addCurrency(CurrenciesCompanion.insert(
      code: 'JPY',
      name: 'Japanese Yen',
      symbol: r'¥',
      decimalDigits: const drift.Value(0),
    ));
    await repo.addCurrency(CurrenciesCompanion.insert(
      code: 'MXN',
      name: 'Mexican Peso',
      symbol: r'$',
      decimalDigits: const drift.Value(3),
    ));
    await repo.addExchangeRate(CurrencyRatesCompanion.insert(
      currencyCode: 'JPY',
      rate: 100.0,
      date: DateTime(2026, 1, 1),
    ));
    await repo.addExchangeRate(CurrencyRatesCompanion.insert(
      currencyCode: 'MXN',
      rate: 20.0,
      date: DateTime(2026, 1, 1),
    ));

    // USD is the base: 10 USD buys exactly 1000 JPY, which has no minor unit
    // below the yen.
    expect(
        await repo.convertAmount(
            amount: 10, fromCode: 'USD', toCode: 'JPY'),
        1000);
    // Three-digit money keeps its third decimal; two-digit money would have
    // thrown it away.
    expect(
        await repo.convertAmount(
            amount: 10, fromCode: 'USD', toCode: 'MXN'),
        200);
    expect(
        await repo.convertAmount(
            amount: 1, fromCode: 'USD', toCode: 'MXN'),
        20);
    expect(
        await repo.convertAmount(
            amount: 0.123, fromCode: 'USD', toCode: 'MXN'),
        2.46);
  });

  test('recording the final payment settles the debt without opening a screen',
      () async {
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

    await repo.addDebt(DebtsCompanion.insert(
      amount: 100,
      currencyCode: 'USD',
      date: DateTime(2026, 1, 1),
    ));
    final debt = (await repo.getAllDebts()).single;
    expect(debt.isSettled, isFalse);

    Future<int> pay(double amount) async {
      await repo.createTransaction(TransactionsCompanion.insert(
        amount: -amount,
        accountId: account.id,
        currencyCode: 'USD',
        date: DateTime(2026, 2, 1),
        debtId: drift.Value(debt.id),
      ));
      return (await repo.getTransactionsForDebt(debt.id)).single.id;
    }

    final paymentId = await pay(100);
    expect((await repo.getDebtById(debt.id))!.isSettled, isTrue);
    expect((await repo.getOpenDebtTotalsInBase()).owedToMe, closeTo(0, 0.001));

    // Removing that payment must reopen it, not leave a settled debt with
    // nothing behind it.
    await repo.deleteTransaction(paymentId);
    expect((await repo.getDebtById(debt.id))!.isSettled, isFalse);
    expect(
        (await repo.getOpenDebtTotalsInBase()).owedToMe, closeTo(100, 0.001));
  });

  test('deleting a debt unlinks its payments', () async {    await repo.createAccountWithInitialTransaction(
      AccountsCompanion.insert(
        name: 'Cash',
        currencyCode: 'USD',
        icon: 'payments',
        iconColor: 0xFF4CAF50,
      ),
      0,
    );
    final account = (await repo.getAllAccounts()).first;

    await repo.addDebt(DebtsCompanion.insert(
      direction: const drift.Value('debtor'),
      amount: 100,
      currencyCode: 'USD',
      date: DateTime(2026, 1, 1),
    ));
    final debt = (await repo.getAllDebts()).single;

    await repo.createTransaction(TransactionsCompanion(
      amount: const drift.Value(-30),
      accountId: drift.Value(account.id),
      currencyCode: const drift.Value('USD'),
      date: drift.Value(DateTime(2026, 2, 1)),
      debtId: drift.Value(debt.id),
    ));

    await repo.deleteDebt(debt.id);
    final tx = (await repo.db.select(repo.db.transactions).get()).single;
    expect(tx.debtId, isNull);
  });

  test('editing a debt-sourced transaction re-syncs its quota schedule',
      () async {
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

    await repo.createTransactionWithDebt(
      TransactionsCompanion(
        amount: const drift.Value(-300),
        accountId: drift.Value(account.id),
        currencyCode: const drift.Value('USD'),
        date: drift.Value(DateTime(2026, 3, 1)),
      ),
      DebtsCompanion.insert(
        direction: const drift.Value('creditor'),
        amount: 300,
        currencyCode: 'USD',
        date: DateTime(2026, 3, 1),
        dueDate: drift.Value(DateTime(2026, 4, 1)),
      ),
      [
        DebtInstallmentsCompanion(
          index: const drift.Value(0),
          amount: const drift.Value(100),
          dueDate: drift.Value(DateTime(2026, 4, 1)),
        ),
        DebtInstallmentsCompanion(
          index: const drift.Value(1),
          amount: const drift.Value(100),
          dueDate: drift.Value(DateTime(2026, 5, 1)),
        ),
        DebtInstallmentsCompanion(
          index: const drift.Value(2),
          amount: const drift.Value(100),
          dueDate: drift.Value(DateTime(2026, 6, 1)),
        ),
      ],
    );
    final tx = (await repo.db.select(repo.db.transactions).get()).single;
    final debt = (await repo.getDebtById(tx.sourceDebtId!))!;
    expect(await repo.getDebtInstallments(debt.id), hasLength(3));

    // Edit: amount 300 -> 270, fewer installments, new schedule.
    final rescheduled = [
      DebtInstallmentsCompanion(
        index: const drift.Value(0),
        amount: const drift.Value(140),
        dueDate: drift.Value(DateTime(2026, 4, 15)),
      ),
      DebtInstallmentsCompanion(
        index: const drift.Value(1),
        amount: const drift.Value(130),
        dueDate: drift.Value(DateTime(2026, 5, 15)),
      ),
    ];
    await repo.updateTransactionWithDebt(
      TransactionsCompanion(
        id: drift.Value(tx.id),
        amount: const drift.Value(-270),
        accountId: drift.Value(account.id),
        currencyCode: const drift.Value('USD'),
        date: drift.Value(DateTime(2026, 3, 1)),
      ),
      debt.id,
      debt.copyWith(
        amount: 270,
        dueDate: drift.Value(DateTime(2026, 4, 15)),
        frequency: const drift.Value('monthly'),
      ),
      rescheduled,
    );

    final updated = (await repo.getDebtById(debt.id))!;
    expect(updated.amount, closeTo(270, 0.001));
    final schedule = await repo.getDebtInstallments(debt.id);
    expect(schedule, hasLength(2));
    expect(schedule[0].amount, closeTo(140, 0.001));
    expect(schedule[1].amount, closeTo(130, 0.001));
    expect(schedule[1].dueDate, DateTime(2026, 5, 15));

    // Deleting the debt also nulls the source link on the transaction.
    await repo.deleteDebt(debt.id);
    final orphan = (await repo.db.select(repo.db.transactions).get()).single;
    expect(orphan.sourceDebtId, isNull);
  });

  test('cash flow buckets by calendar unit, empties included', () async {
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

    // A Wednesday, so week bucketing has a mid-week moment to floor away from.
    final now = DateTime(2026, 3, 11, 15, 30);

    Future<void> post(double amount, DateTime date, {String? transferGroupId}) =>
        repo.createTransaction(TransactionsCompanion.insert(
          amount: amount,
          accountId: account.id,
          currencyCode: 'USD',
          date: date,
          transferGroupId: drift.Value(transferGroupId),
        ));

    await post(-40, DateTime(2026, 3, 11, 9)); // today, out
    await post(200, DateTime(2026, 3, 11, 18)); // today, in
    await post(-15, DateTime(2026, 3, 9, 12)); // same week, out
    // A transfer leg is not spending, whatever its sign.
    await post(-999, DateTime(2026, 3, 11, 20), transferGroupId: 'g1');
    // Older than every window below: 12 weeks back reaches 22 Dec 2025.
    await post(-50, DateTime(2025, 12, 20, 12));

    final days =
        await repo.watchCashFlow(bucket: CashFlowBucket.day, now: now).first;
    expect(days, hasLength(30));
    expect(days.first.date, DateTime(2026, 2, 10));
    expect(days.last.date, DateTime(2026, 3, 11));
    expect(days.last.expenses, 40);
    expect(days.last.income, 200);
    expect(days[days.length - 3].expenses, 15); // 10 Mar, two days back
    // A day with nothing in it is still a point, at zero — skipping it would
    // draw a line straight across it.
    expect(days[days.length - 4].expenses, 0);
    expect(days.fold<double>(0, (s, p) => s + p.expenses), 55);

    final weeks =
        await repo.watchCashFlow(bucket: CashFlowBucket.week, now: now).first;
    expect(weeks, hasLength(12));
    // Weeks start Monday: 11 Mar 2026 is a Wednesday, so this one began 9 Mar.
    expect(weeks.last.date, DateTime(2026, 3, 9));
    expect(weeks.last.expenses, 55);
    expect(weeks[weeks.length - 2].expenses, 0);

    final months =
        await repo.watchCashFlow(bucket: CashFlowBucket.month, now: now).first;
    expect(months, hasLength(12));
    expect(months.first.date, DateTime(2025, 4, 1));
    expect(months.last.date, DateTime(2026, 3, 1));
    expect(months.last.expenses, 55);

    final years =
        await repo.watchCashFlow(bucket: CashFlowBucket.year, now: now).first;
    expect(years, hasLength(5));
    expect(years.first.date, DateTime(2022, 1, 1));
    expect(years.last.date, DateTime(2026, 1, 1));
    expect(years.last.expenses, 55);
  });

  // ── Goals ──

  group('goals', () {
    test('creating a goal opens the savings account holding its money', () async {
      final goal = await repo.createGoalWithAccount(
        name: 'Emergency fund',
        targetAmount: 1000,
        currencyCode: 'USD',
        accountName: 'Emergency fund',
      );

      final account = await repo.getAccountById(goal.accountId);
      expect(account, isNotNull);
      expect(account!.name, 'Emergency fund');
      expect(account.icon, 'savings');
      // A fresh pot is genuinely empty — no phantom starting balance.
      expect((await repo.watchGoalsWithProgress().first).single.current, 0);

      final stored = await repo.getGoalById(goal.id);
      expect(stored!.name, 'Emergency fund');
      expect(stored.targetAmount, 1000);
    });

    test('a goal can adopt an existing account instead of opening one', () async {
      final base = (await repo.getAllCurrencies()).firstWhere((c) => c.code == 'USD');
      final account = await db.into(db.accounts).insertReturning(
          AccountsCompanion.insert(
            name: 'Shared pot',
            currencyCode: base.code,
            icon: 'savings',
            iconColor: 1,
          ));

      await repo.createGoalWithAccount(
        name: 'Trip',
        targetAmount: 500,
        currencyCode: 'USD',
        accountName: 'ignored',
        accountId: account.id,
      );

      // No second account was created.
      expect(await repo.getAllAccounts(), hasLength(1));
    });

    test('progress is the backing account balance, not a stored number',
        () async {
      final goal = await repo.createGoalWithAccount(
        name: 'Laptop',
        targetAmount: 1000,
        currencyCode: 'USD',
        accountName: 'Laptop',
      );
      final account = await repo.getAccountById(goal.accountId);
      final category = (await repo.getAllCategories()).first;

      await repo.createTransaction(TransactionsCompanion.insert(
        amount: 250,
        categoryId: drift.Value(category.id),
        accountId: account!.id,
        currencyCode: 'USD',
        date: DateTime.now(),
      ));

      final progress =
          (await repo.watchGoalsWithProgress().first).single;
      expect(progress.current, 250);
      expect(progress.progress, closeTo(0.25, 1e-9));
      expect(progress.isReached, isFalse);
    });

    test('a transfer into the pot re-emits progress live', () async {
      final goal = await repo.createGoalWithAccount(
        name: 'Holiday',
        targetAmount: 1000,
        currencyCode: 'USD',
        accountName: 'Holiday',
      );
      final account = await repo.getAccountById(goal.accountId);
      final category = (await repo.getAllCategories()).first;

      final seen = <double>[];
      final sub = repo.watchGoalsWithProgress().listen((rows) {
        seen.add(rows.single.current);
      });
      // Let the first (empty) emission land.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await repo.createTransaction(TransactionsCompanion.insert(
        amount: 400,
        categoryId: drift.Value(category.id),
        accountId: account!.id,
        currencyCode: 'USD',
        date: DateTime.now(),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      // Funding a goal must move progress without editing the goal itself.
      expect(seen.first, 0);
      expect(seen.last, 400);
    });

    test('overfunded progress exceeds 100% rather than clamping', () async {
      final goal = await repo.createGoalWithAccount(
        name: 'Bike',
        targetAmount: 100,
        currencyCode: 'USD',
        accountName: 'Bike',
      );
      final account = await repo.getAccountById(goal.accountId);
      final category = (await repo.getAllCategories()).first;
      await repo.createTransaction(TransactionsCompanion.insert(
        amount: 250,
        categoryId: drift.Value(category.id),
        accountId: account!.id,
        currencyCode: 'USD',
        date: DateTime.now(),
      ));

      final progress = (await repo.watchGoalsWithProgress().first).single;
      // The card clamps the bar, but the number stays honest.
      expect(progress.progress, 2.5);
      expect(progress.isReached, isTrue);
    });

    test('a cross-currency pot converts into the goal currency', () async {
      final goal = await repo.createGoalWithAccount(
        name: 'Foreign pot',
        targetAmount: 100,
        currencyCode: 'USD',
        accountName: 'Foreign pot',
      );
      final account = await repo.getAccountById(goal.accountId);
      final category = (await repo.getAllCategories()).first;

      // Hold money in a currency worth twice as much, then let the rate land.
      final pot = account!;
      await repo.updateAccount(AccountsCompanion(
        id: drift.Value(pot.id),
        currencyCode: const drift.Value('VES'),
      ));
      await db.into(db.currencyRates).insert(CurrencyRatesCompanion.insert(
            currencyCode: 'VES',
            rate: 2.0,
            date: DateTime.now(),
          ));
      await repo.createTransaction(TransactionsCompanion.insert(
        amount: 50,
        categoryId: drift.Value(category.id),
        accountId: pot.id,
        currencyCode: 'VES',
        date: DateTime.now(),
      ));

      final progress = (await repo.watchGoalsWithProgress().first).single;
      // 50 VES at 2.0 per USD is 25 USD against a 100 USD target.
      expect(progress.current, 25);
      expect(progress.progress, closeTo(0.25, 1e-9));
    });

    test('no projection without a positive surplus, and a date with one',
        () async {
      final goal = await repo.createGoalWithAccount(
        name: 'Rainy day',
        targetAmount: 1200,
        currencyCode: 'USD',
        accountName: 'Rainy day',
      );
      final progress = (await repo.watchGoalsWithProgress().first).single;

      // Nothing in the ledger means no rate, so no date to promise.
      expect(await repo.projectGoalCompletion(progress), isNull);

      final category = (await repo.getAllCategories()).first;
      final now = DateTime.now();
      // Two closed months at +600/mo, 300 out of pocket.
      for (final month in [now.subtract(const Duration(days: 75)),
        now.subtract(const Duration(days: 45))]) {
        await repo.createTransaction(TransactionsCompanion.insert(
          amount: 600,
          categoryId: drift.Value(category.id),
          accountId: (await repo.getAccountById(goal.accountId))!.id,
          currencyCode: 'USD',
          date: month,
        ));
      }

      // The window is 3 closed months and the divide is by months in the
      // window, not months with activity — a quiet month really does drag the
      // rate down.
      final rate = await repo.averageMonthlySurplus();
      expect(rate, 400);
      final projected = await repo.projectGoalCompletion(progress,
          monthlyRate: rate);
      expect(projected, isNotNull);
      // 1200 to go at 400/mo is 3 months out.
      expect(projected!.month, DateTime(now.year, now.month + 3, now.day).month);
    });

    test('a reached goal is due now, not in the future', () async {
      final goal = await repo.createGoalWithAccount(
        name: 'Done',
        targetAmount: 50,
        currencyCode: 'USD',
        accountName: 'Done',
      );
      final account = await repo.getAccountById(goal.accountId);
      final category = (await repo.getAllCategories()).first;
      await repo.createTransaction(TransactionsCompanion.insert(
        amount: 50,
        categoryId: drift.Value(category.id),
        accountId: account!.id,
        currencyCode: 'USD',
        date: DateTime.now(),
      ));

      final progress = (await repo.watchGoalsWithProgress().first).single;
      final projected = await repo.projectGoalCompletion(progress);
      final now = DateTime.now();
      expect(projected!.year, now.year);
      expect(projected.month, now.month);
    });

    test('deleting a goal leaves its account and money alone', () async {
      final goal = await repo.createGoalWithAccount(
        name: 'Temp',
        targetAmount: 100,
        currencyCode: 'USD',
        accountName: 'Temp',
      );
      final account = await repo.getAccountById(goal.accountId);
      final category = (await repo.getAllCategories()).first;
      await repo.createTransaction(TransactionsCompanion.insert(
        amount: 30,
        categoryId: drift.Value(category.id),
        accountId: account!.id,
        currencyCode: 'USD',
        date: DateTime.now(),
      ));

      await repo.deleteGoal(goal.id);

      expect(await repo.getGoalById(goal.id), isNull);
      expect(await repo.getAllAccounts(), hasLength(1));
      expect(await db.select(db.transactions).get(), hasLength(1));
    });

    test('wiping data clears goals before their accounts', () async {
      await repo.createGoalWithAccount(
        name: 'Doomed',
        targetAmount: 100,
        currencyCode: 'USD',
        accountName: 'Doomed',
      );
      expect(await db.select(db.goals).get(), hasLength(1));

      await db.resetAllData();

      expect(await db.select(db.goals).get(), isEmpty);
      expect(await db.select(db.accounts).get(), isEmpty);
    });
  });
}