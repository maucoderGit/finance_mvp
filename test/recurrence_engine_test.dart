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
  late int accountId;

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
    accountId = (await repo.getAllAccounts()).first.id;
  });

  tearDown(() => db.close());

  Future<int> saveTemplate({
    required DateTime date,
    String type = 'monthly',
    int interval = 1,
    String? ends,
    DateTime? endDate,
    int? totalCount,
    double amount = -50,
  }) async {
    await repo.createTransaction(TransactionsCompanion.insert(
      amount: amount,
      accountId: accountId,
      currencyCode: 'USD',
      reference: const drift.Value('Rent'),
      isRecurrenceEnabled: const drift.Value(true),
      recurrenceType: drift.Value(type),
      recurrenceInterval: drift.Value(interval),
      recurrenceEnds: drift.Value(ends),
      recurrenceEndDate: drift.Value(endDate),
      recurrenceTotalCount: drift.Value(totalCount),
      date: date,
    ));
    return (await repo.db.select(repo.db.transactions).get()).last.id;
  }

  test('a due occurrence is materialised on the app-open run', () async {
    final id = await saveTemplate(date: DateTime(2026, 1, 31));

    // Nothing due yet: the anchor's own month has passed but the 28th of Feb
    // hasn't arrived.
    expect(
        await repo.materializeDueRecurrences(
            now: DateTime(2026, 2, 27)),
        0);

    expect(
        await repo.materializeDueRecurrences(
            now: DateTime(2026, 2, 28)),
        1);

    final rows = await repo.db.select(repo.db.transactions).get();
    final generated = rows.where((r) => r.recurrenceParentId == id).toList();
    expect(generated, hasLength(1));
    expect(generated.single.date, DateTime(2026, 2, 28));
    // Carries the template's money and description, on its own date.
    expect(generated.single.amount, -50);
    expect(generated.single.reference, 'Rent');
    expect(generated.single.accountId, accountId);
    // ...and is not itself a series.
    expect(generated.single.isRecurrenceEnabled, isFalse);
    expect(generated.single.recurrenceType, isNull);
  });

  test('running twice on the same day creates nothing extra', () async {
    await saveTemplate(date: DateTime(2026, 1, 1));
    final now = DateTime(2026, 6, 15);
    expect(await repo.materializeDueRecurrences(now: now), 5);
    expect(await repo.materializeDueRecurrences(now: now), 0);
    expect(await repo.materializeDueRecurrences(now: now), 0);

    final generated = (await repo.db.select(repo.db.transactions).get())
        .where((r) => r.recurrenceParentId != null);
    expect(generated, hasLength(5));
  });

  test('a generated occurrence never spawns its own series', () async {
    final id = await saveTemplate(date: DateTime(2026, 1, 1));
    await repo.materializeDueRecurrences(now: DateTime(2026, 3, 1));

    // Every generated row is excluded by the parent-id filter the engine uses.
    final generated =
        (await repo.db.select(repo.db.transactions).get())
            .where((r) => r.recurrenceParentId == id)
            .toList();
    expect(generated, hasLength(2));
    for (final row in generated) {
      expect(row.isRecurrenceEnabled, isFalse);
    }
  });

  test('catches up after a long absence, one step at a time', () async {
    // A daily series: ~364 occurrences are due at once.
    await saveTemplate(date: DateTime(2026, 1, 1), type: 'daily');

    // Capped per run, so a daily series abandoned for months does not dump
    // hundreds of rows into the ledger at once.
    final first = await repo.materializeDueRecurrences(
        now: DateTime(2026, 12, 31));
    expect(first, FinanceRepository.maxOccurrencesPerRun);

    final second = await repo.materializeDueRecurrences(
        now: DateTime(2026, 12, 31));
    expect(second, FinanceRepository.maxOccurrencesPerRun);
  });

  test('a series that ends on a date stops generating', () async {
    await saveTemplate(
      date: DateTime(2026, 1, 31),
      ends: 'date',
      endDate: DateTime(2026, 3, 31),
    );

    expect(
        await repo.materializeDueRecurrences(
            now: DateTime(2026, 2, 28)),
        1);
    expect(
        await repo.materializeDueRecurrences(
            now: DateTime(2026, 3, 31)),
        1);
    // April would be past the end date, and March 31 already generated.
    expect(
        await repo.materializeDueRecurrences(
            now: DateTime(2026, 6, 30)),
        0);
  });

  test('a series with a total count stops after that many', () async {
    await saveTemplate(
        date: DateTime(2026, 1, 31),
        ends: 'count',
        totalCount: 3);

    // Occurrences 0 (the template), 1 and 2 — three in total.
    expect(
        await repo.materializeDueRecurrences(
            now: DateTime(2026, 12, 31)),
        2);
    expect(
        await repo.materializeDueRecurrences(
            now: DateTime(2027, 12, 31)),
        0);
  });

  test('a disabled recurrence generates nothing', () async {
    await repo.createTransaction(TransactionsCompanion.insert(
      amount: -50,
      accountId: accountId,
      currencyCode: 'USD',
      isRecurrenceEnabled: const drift.Value(false),
      recurrenceType: const drift.Value('monthly'),
      date: DateTime(2026, 1, 1),
    ));
    expect(
        await repo.materializeDueRecurrences(
            now: DateTime(2027, 1, 1)),
        0);
  });

  test('a row with no recognisable type is ignored rather than crashing',
      () async {
    await saveTemplate(date: DateTime(2026, 1, 1), type: 'fortnightly');
    expect(
        await repo.materializeDueRecurrences(
            now: DateTime(2027, 1, 1)),
        0);
  });

  test('generated rows drop the captured FX rate so reads re-derive it',
      () async {
    // A VES template with a captured rate: an occurrence dated months later
    // must not be valued at the rate captured when the template was saved.
    await repo.createAccountWithInitialTransaction(
      AccountsCompanion.insert(
        name: 'Bolivares',
        currencyCode: 'VES',
        icon: 'payments',
        iconColor: 0xFF4CAF50,
      ),
      0,
    );
    final ves = (await repo.getAllAccounts())
        .firstWhere((a) => a.currencyCode == 'VES');

    await repo.createTransaction(TransactionsCompanion.insert(
      amount: -1000,
      accountId: ves.id,
      currencyCode: 'VES',
      isRecurrenceEnabled: const drift.Value(true),
      recurrenceType: const drift.Value('monthly'),
      exchangeRateAtCreation: const drift.Value(36.5),
      baseCurrencyAmount: const drift.Value(27.397260273972603),
      date: DateTime(2026, 1, 31),
    ));
    final id = (await repo.db.select(repo.db.transactions).get()).last.id;

    await repo.materializeDueRecurrences(now: DateTime(2026, 2, 28));

    final generated = (await repo.db.select(repo.db.transactions).get())
        .singleWhere((r) => r.recurrenceParentId == id);
    expect(generated.baseCurrencyAmount, isNull);
    expect(generated.exchangeRateAtCreation, isNull);
    expect(generated.currencyCode, 'VES');
  });

  test('generated rows do not move a debt balance', () async {
    await repo.addDebt(DebtsCompanion.insert(
      amount: 500,
      currencyCode: 'USD',
      date: DateTime(2026, 1, 1),
    ));
    final debt = (await repo.getAllDebts()).single;

    // A template that is itself a payment against the debt.
    await repo.createTransaction(TransactionsCompanion.insert(
      amount: -100,
      accountId: accountId,
      currencyCode: 'USD',
      debtId: drift.Value(debt.id),
      isRecurrenceEnabled: const drift.Value(true),
      recurrenceType: const drift.Value('monthly'),
      date: DateTime(2026, 1, 1),
    ));

    expect(
        await repo.materializeDueRecurrences(
            now: DateTime(2026, 2, 1)),
        1);
    // The debt is untouched: an auto-generated occurrence the user never
    // confirmed shouldn't quietly reduce what they owe.
    expect(await repo.getDebtRemaining(debt), 400);
  });

  test('getNextOccurrence reports the upcoming due date', () async {
    final id = await saveTemplate(date: DateTime(2026, 1, 31));
    final template =
        (await repo.db.select(repo.db.transactions).get())
            .singleWhere((r) => r.id == id);

    expect(await repo.getNextOccurrence(template, from: DateTime(2026, 1, 31)),
        DateTime(2026, 2, 28));
    expect(await repo.getNextOccurrence(template, from: DateTime(2026, 3, 1)),
        DateTime(2026, 3, 31));
  });
}
