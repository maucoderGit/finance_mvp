import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:finance_mvp/database/app_database.dart';
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/screens/debts/debts_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'test_db.dart';

Future<(AppDatabase, FinanceRepository)> pumpDebtsScreen(
  WidgetTester tester, {
  List<DebtsCompanion> seed = const [],
}) async {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final db = AppDatabase(executor: NativeDatabase.memory());
  final repo = FinanceRepository(db);

  for (final debt in seed) {
    await repo.addDebt(debt);
  }

  final navigatorKey = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MultiProvider(
      providers: [Provider<FinanceRepository>.value(value: repo)],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: SizedBox()),
      ),
    ),
  );

  navigatorKey.currentState!.push(
    MaterialPageRoute(builder: (_) => const DebtsScreen()),
  );
  await tester.pumpAndSettle();

  return (db, repo);
}

void main() {
  setUpAll(() => useSystemSqlite());

testWidgets('lists debts by direction with per-row detail', (tester) async {
    final (db, repo) = await pumpDebtsScreen(tester, seed: [
      DebtsCompanion.insert(
        direction: const drift.Value('debtor'),
        amount: 100,
        currencyCode: 'USD',
        date: DateTime(2026, 1, 1),
      ),
      DebtsCompanion.insert(
        direction: const drift.Value('creditor'),
        amount: 50,
        currencyCode: 'USD',
        date: DateTime(2026, 1, 2),
      ),
    ]);

    expect(find.textContaining(r'$100.00'), findsWidgets);
    expect(find.textContaining(r'$50.00'), findsWidgets);
    expect(find.textContaining(r'$100.00 of $100.00'), findsOneWidget);
    expect(find.textContaining(r'$50.00 of $50.00'), findsOneWidget);
    expect(find.text(r'They owe me · $100.00 of $100.00 · Jan 01, 2026'),
        findsOneWidget);
    expect(find.text(r'I owe · $50.00 of $50.00 · Jan 02, 2026'),
        findsOneWidget);
    expect(find.text('I owe'), findsWidgets); // summary label present

    await db.close();
  });

  testWidgets('adds, settles and reopens a debt', (tester) async {
    final (db, repo) = await pumpDebtsScreen(tester);

    // Add: "They owe me 75 USD".
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '75');
    await tester.tap(find.text('Save Debt'));
    await tester.pumpAndSettle();
    expect(find.text('Debt'), findsOneWidget);
    expect(find.textContaining(r'$75.00'), findsWidgets);

    // Edit: toggle Settled.
    await tester.tap(find.text('Debt'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Debt'));
    await tester.pumpAndSettle();

    expect(find.text('Settled'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsNothing);

    var debts = await repo.getAllDebts();
    expect(debts.single.isSettled, isTrue);

    // Reopen from the settled row.
    await tester.tap(find.byIcon(Icons.restore).first);
    await tester.pumpAndSettle();
    debts = await repo.getAllDebts();
    expect(debts.single.isSettled, isFalse);

    await db.close();
  });
}