import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/database/app_database.dart';
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/screens/transactions/transactions_screen.dart';
import 'package:finance_mvp/widgets/transaction_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'test_db.dart';

bool _inside(DateTime date, ({DateTime start, DateTime end}) r) =>
    !date.isBefore(r.start) && date.isBefore(r.end);

/// Mounts the page over an in-memory DB holding [seed], and unmounts + closes
/// it again so drift's stream-cleanup timers fire before teardown's
/// pending-timer check (same dance as root_screen_test). [setup] runs against
/// the repository before the widget mounts, for rows the seed references.
Future<void> pumpPage(
  WidgetTester tester, {
  required List<TransactionsCompanion> seed,
  required Future<void> Function(WidgetTester) body,
  Future<void> Function(FinanceRepository repo)? setup,
}) async {
  final db = AppDatabase(executor: NativeDatabase.memory());
  final repo = FinanceRepository(db);
  await setup?.call(repo);
  for (final t in seed) {
    await repo.createTransaction(t);
  }

  await tester.pumpWidget(
    MultiProvider(
      providers: [Provider<FinanceRepository>.value(value: repo)],
      child: AppPalette(
        colors: AppColors.current,
        child: const MaterialApp(home: TransactionPage()),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await body(tester);

  await tester.pumpWidget(const SizedBox());
  await tester.pump();
  db.close();
  await tester.pump(const Duration(milliseconds: 1));
}

TransactionsCompanion _tx(double amount, String reference) =>
    TransactionsCompanion.insert(
      accountId: 1,
      amount: amount,
      currencyCode: 'USD',
      reference: Value(reference),
      date: DateTime.now(),
    );

void main() {
  setUpAll(() => useSystemSqlite());

  // A Wednesday, mid-month, mid-year: catches off-by-one on week start and
  // on quarter boundaries.
  final anchor = DateTime(2026, 8, 19);

  test('week runs Monday to Monday', () {
    final r = Period.week.range(anchor)!;
    expect(r.start, DateTime(2026, 8, 17));
    expect(r.end, DateTime(2026, 8, 24));
    expect(_inside(anchor, r), isTrue);
    expect(_inside(DateTime(2026, 8, 16), r), isFalse);
    expect(_inside(DateTime(2026, 8, 24), r), isFalse);
  });

  test('month covers the calendar month only', () {
    final r = Period.month.range(anchor)!;
    expect(r.start, DateTime(2026, 8));
    expect(r.end, DateTime(2026, 9));
    expect(_inside(DateTime(2026, 7, 31), r), isFalse);
    expect(_inside(DateTime(2026, 8, 31, 23, 59), r), isTrue);
  });

  test('quarter groups three months and rolls the year over', () {
    expect(Period.quarter.range(anchor)!.start, DateTime(2026, 7));
    expect(Period.quarter.range(anchor)!.end, DateTime(2026, 10));
    final q1 = Period.quarter.range(DateTime(2026, 2, 3))!;
    expect(q1.start, DateTime(2026, 1));
    expect(q1.end, DateTime(2026, 4));
  });

  test('year covers january to december', () {
    final r = Period.year.range(anchor)!;
    expect(r.start, DateTime(2026));
    expect(r.end, DateTime(2027));
  });

  test('all has no bounds', () {
    expect(Period.all.range(anchor), isNull);
    expect(Period.all.title(anchor), 'All time');
  });

  test('titles name the current period differently from a past one', () {
    final now = DateTime.now();
    expect(Period.month.title(now), 'This month');
    expect(Period.quarter.title(DateTime(2025, 5)), 'Q2 2025');
    expect(Period.year.title(DateTime(2025, 5)), '2025');
    expect(Period.week.title(DateTime(2026, 8, 19)), 'Aug 17 – Aug 23');
  });

  testWidgets('summary amount follows the palette, not a hardcoded black',
      (tester) async {
    AppColors.useDark(true);
    addTearDown(() => AppColors.useDark(false));

    await pumpPage(tester, seed: [_tx(1234.56, 'Groceries')], body: (tester) async {
      final amount = tester.widget<Text>(find.descendant(
        of: find.byType(TransactionCard),
        matching: find.textContaining('1,234.56'),
      ));
      expect(amount.style?.color, AppColors.textDark);
      expect(find.text('Today'), findsOneWidget);
    });
  });

  testWidgets('search swaps the header for a field and narrows the list',
      (tester) async {
    await pumpPage(
      tester,
      seed: [_tx(10, 'Groceries'), _tx(20, 'Gasoline')],
      body: (tester) async {
        expect(find.byType(TextField), findsNothing);

        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Transactions'), findsNothing);
        expect(find.byIcon(Icons.add), findsNothing);

        await tester.enterText(find.byType(TextField), 'gas');
        await tester.pumpAndSettle();
        expect(find.text('Gasoline'), findsOneWidget);
        expect(find.text('Groceries'), findsNothing);
        expect(find.textContaining('No matches for "zzz"'), findsNothing);

        // The X in the field clears the query, the arrow leaves search mode.
        await tester.enterText(find.byType(TextField), 'zzz');
        await tester.pumpAndSettle();
        expect(find.text('No matches for "zzz"'), findsOneWidget);
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
        expect(find.text('Groceries'), findsOneWidget);

        await tester.tap(find.byType(IconButton).first);
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsNothing);
        expect(find.text('Transactions'), findsOneWidget);
      },
    );
  });

  testWidgets('search matches the contact and category behind a row',
      (tester) async {
    // Category id 1 is the seeded "Services" row.
    await pumpPage(
      tester,
      setup: (repo) async {
        await repo.findOrCreateContact('Ana Ruiz');
      },
      seed: [
        _tx(10, 'Invoice 1').copyWith(contactId: const Value(1)),
        _tx(20, 'Invoice 2').copyWith(categoryId: const Value(1)),
        _tx(30, 'Invoice 3'),
      ],
      body: (tester) async {
        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'ana ruiz');
        await tester.pumpAndSettle();
        expect(find.text('Invoice 1'), findsOneWidget);
        expect(find.text('Invoice 2'), findsNothing);

        await tester.enterText(find.byType(TextField), 'services');
        await tester.pumpAndSettle();
        expect(find.text('Invoice 2'), findsOneWidget);
        expect(find.text('Invoice 1'), findsNothing);
      },
    );
  });
}
