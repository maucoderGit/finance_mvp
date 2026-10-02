import 'package:drift/native.dart';
import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/database/app_database.dart';
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/screens/goals/goal_form_screen.dart';
import 'package:finance_mvp/screens/goals/goals_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'test_db.dart';

/// Only the wiring the repository tests can't see: that the screens write
/// through to the repo, and that funding a pot moves the card without the goal
/// row changing. Progress maths, conversion, projection and delete semantics
/// are asserted in finance_repository_test.dart instead of twice through a
/// slower, flakier widget harness.
void main() {
  setUpAll(() => useSystemSqlite());

  late AppDatabase db;
  late FinanceRepository repo;

  setUp(() {
    db = AppDatabase(executor: testConnection(NativeDatabase.memory()));
    repo = FinanceRepository(db);
  });

  tearDown(() => db.close());

  Future<void> mount(WidgetTester tester, Widget screen) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [Provider<FinanceRepository>.value(value: repo)],
        child: AppPalette(
          colors: AppColors.current,
          child: MaterialApp(home: screen),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the form writes a goal and its savings account',
      (tester) async {
    await mount(tester, const GoalFormScreen());

    // Two text fields only: name then target. Currency is a button, account a
    // dropdown, so neither is editable text.
    await tester.enterText(find.byType(TextField).at(0), 'Emergency fund');
    await tester.enterText(find.byType(TextField).at(1), '1000');
    // Below the fold once the keyboard is up.
    await tester.scrollUntilVisible(find.text('Save goal'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Save goal'));
    await tester.pumpAndSettle();

    final goal = (await db.select(db.goals).get()).single;
    expect(goal.name, 'Emergency fund');
    expect(goal.targetAmount, 1000);
    // The money has somewhere to live, and starts empty.
    expect((await repo.getAccountById(goal.accountId))!.icon, 'savings');
    expect((await repo.watchGoalsWithProgress().first).single.current, 0);
  });

  testWidgets('the form refuses an empty name and saves nothing',
      (tester) async {
    await mount(tester, const GoalFormScreen());

    await tester.enterText(find.byType(TextField).at(1), '1000');
    await tester.scrollUntilVisible(find.text('Save goal'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Save goal'));
    await tester.pumpAndSettle();

    expect(find.textContaining('name and a target'), findsOneWidget);
    // No half-created goal, and no orphaned account.
    expect(await db.select(db.goals).get(), isEmpty);
    expect(await repo.getAllAccounts(), isEmpty);
  });

  testWidgets('a funded pot moves the card without editing the goal',
      (tester) async {
    final goal = await repo.createGoalWithAccount(
      name: 'Laptop',
      targetAmount: 2000,
      currencyCode: 'USD',
      accountName: 'Laptop',
    );

    await mount(tester, const GoalsScreen());
    expect(find.text('0%'), findsOneWidget);

    await repo.createTransaction(TransactionsCompanion.insert(
      amount: 500,
      accountId: goal.accountId,
      currencyCode: 'USD',
      date: DateTime.now(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('25%'), findsOneWidget);
    // The number came from the ledger, so the goal row is untouched.
    expect((await repo.getGoalById(goal.id))!.targetAmount, 2000);
  });

  testWidgets('swiping a goal away asks first and keeps the pot',
      (tester) async {
    await repo.createGoalWithAccount(
      name: 'Doomed',
      targetAmount: 100,
      currencyCode: 'USD',
      accountName: 'Doomed',
    );

    await mount(tester, const GoalsScreen());
    await tester.drag(find.text('Doomed'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Delete "Doomed"?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await db.select(db.goals).get(), hasLength(1));

    await tester.drag(find.text('Doomed'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(await db.select(db.goals).get(), isEmpty);
    // The account and its transactions are the user's, not the goal's.
    expect(await repo.getAllAccounts(), hasLength(1));
  });
}
