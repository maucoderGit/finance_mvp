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