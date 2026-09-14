import 'package:drift/native.dart';
import 'package:finance_mvp/database/app_database.dart';
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/screens/contacts/contacts_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'test_db.dart';

Future<(AppDatabase, FinanceRepository)> pumpContactsScreen(
  WidgetTester tester, {
  List<(String, String)> seed = const [],
}) async {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final db = AppDatabase(executor: NativeDatabase.memory());
  final repo = FinanceRepository(db);

  for (final (name, phone) in seed) {
    await repo.findOrCreateContact(name, phone: phone.isEmpty ? null : phone);
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
    MaterialPageRoute(builder: (_) => const ContactsScreen()),
  );
  await tester.pumpAndSettle();

  return (db, repo);
}

void main() {
  setUpAll(() => useSystemSqlite());

  testWidgets('lists contacts, filters by search', (tester) async {
    final (db, repo) = await pumpContactsScreen(tester, seed: [
      ('La Casa', '+58 412 555 0101'),
      ('Panaderia El Sol', ''),
    ]);

    expect(find.text('La Casa'), findsOneWidget);
    expect(find.text('Panaderia El Sol'), findsOneWidget);
    expect(find.text('+58 412 555 0101'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'sol');
    await tester.pumpAndSettle();
    expect(find.text('La Casa'), findsNothing);
    expect(find.text('Panaderia El Sol'), findsOneWidget);

    await db.close();
  });

  testWidgets('adds, edits and deletes a contact', (tester) async {
    final (db, repo) = await pumpContactsScreen(tester, seed: [('Acme', '')]);

    // Add via the form sheet.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Oslo Co');
    await tester.tap(find.text('Add contact'));
    await tester.pumpAndSettle();
    expect(find.text('Oslo Co'), findsOneWidget);

    // Edit: rename to "Fulfillment Co".
    await tester.tap(find.text('Oslo Co'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Fulfillment Co');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(find.text('Fulfillment Co'), findsOneWidget);
    expect(find.text('Oslo Co'), findsNothing);

    // Delete Acme (has no transactions, straight removal).
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Acme'), findsNothing);
    expect(find.text('Fulfillment Co'), findsOneWidget);

    final contacts = await repo.getAllContacts();
    expect(contacts.map((c) => c.name), ['Fulfillment Co']);

    await db.close();
  });
}