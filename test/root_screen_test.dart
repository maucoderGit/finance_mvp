import 'package:drift/native.dart';
import 'package:finance_mvp/database/app_database.dart';
import 'package:finance_mvp/providers/currency_provider.dart';
import 'package:finance_mvp/providers/revaluation_provider.dart';
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/screens/overview/home_screen.dart';
import 'package:finance_mvp/screens/onboarding/onboarding_screen.dart';
import 'package:finance_mvp/screens/overview/root_screen.dart';
import 'package:finance_mvp/services/rates/exchange_rate_api_service.dart';
import 'package:finance_mvp/services/finance/revaluation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'test_db.dart';

void main() {
  setUpAll(() => useSystemSqlite());

  late AppDatabase db;
  late FinanceRepository repo;
  late RevaluationService service;
  late CurrencyProvider currencyProvider;
  late RevaluationProvider revaluationProvider;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    repo = FinanceRepository(db);
    service = RevaluationService(repo);
    currencyProvider = CurrencyProvider(
      repo,
      sources: [
        ExchangeRateApiService(
          client: MockClient((_) async => http.Response('[]', 200)),
        ),
      ],
    );
    revaluationProvider = RevaluationProvider(service);
  });

  tearDown(() {
    // Nothing left to release: the test body closes the DB and disposes
    // providers before the framework's timer invariant is checked.
  });

  Widget buildRoot() {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: db),
        Provider<FinanceRepository>.value(value: repo),
        Provider<RevaluationService>.value(value: service),
        ChangeNotifierProvider<CurrencyProvider>.value(value: currencyProvider),
        ChangeNotifierProvider<RevaluationProvider>.value(value: revaluationProvider),
      ],
      child: const MaterialApp(home: RootScreen()),
    );
  }

  testWidgets('first launch shows onboarding, then swaps to home', (tester) async {
    await tester.pumpWidget(buildRoot());
    await tester.pumpAndSettle();

    // Not onboarded yet → RootScreen renders the wizard.
    expect(find.text('Welcome to\nFinance'), findsOneWidget);

    // Walk the wizard to the end.
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Step: sync mode → choose manual so no HTTP is fired by the home screen.
    await tester.tap(find.text('Manual'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Step: first account → must register at least one to continue.
    await tester.enterText(
        find.byKey(const Key('onboarding-account-name')), 'Cash');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Finish → settings stream flips RootScreen to the home screen.
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(HomeScreen), findsWidgets);
    expect(find.text('Moves'), findsWidgets);
    expect(await repo.getHasCompletedOnboarding(), isTrue);

    // Unmount the tree and close the DB inside the body so drift's
    // stream-cleanup timers fire before teardown's invariant check.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    // close() must not block the fake-async zone; advance the clock instead
    // so its internal zero-delay timers and drift's cleanup run.
    db.close();
    await tester.pump(const Duration(milliseconds: 1));
    currencyProvider.dispose();
    revaluationProvider.dispose();
  });
}