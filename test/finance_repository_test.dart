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

    await repo.wipeAllData();

    expect(await repo.getAllAccounts(), isEmpty);
    expect((await repo.watchTransactions().first)
        .where((t) => t.accountId > 0), isEmpty);
    expect(await repo.getRatesForCurrency('MXN'), isEmpty);

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
}