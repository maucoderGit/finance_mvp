import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finance_mvp/screens/onboarding/onboarding_screen.dart';

void main() {
  testWidgets('Onboarding wizard walks through all steps', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    // Step 0: welcome.
    expect(find.text('Welcome to\nFinance'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    // Step 1: name.
    expect(find.text('How should we call you?'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Step 2: reference currency (USD preselected).
    expect(find.text('Reference currency'), findsOneWidget);
    expect(find.text('USD'), findsWidgets);
    expect(find.text('Primary reference for net worth'),
        findsNothing); // ensure subtitle is the right one
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Step 3: local currency.
    expect(find.text('Local currency'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Step 4: sync mode (Automatic preselected).
    expect(find.text('Exchange rates'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Step 5: first account — optional, use a template to add one.
    expect(find.text('Your first account'), findsOneWidget);
    await tester.tap(find.widgetWithText(ActionChip, 'Cash'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Step 5 is skippable: without adding an account, Next goes straight on.
    // (covered by walking again below via manual add)
    expect(find.text("You're all set!"), findsOneWidget);
    expect(find.text('USD'), findsOneWidget);
    expect(find.text('VES'), findsOneWidget);
    expect(find.text('1 account'), findsOneWidget);
    expect(find.text('Automatic sync'), findsOneWidget);
  });

  testWidgets('onboarding account step can be skipped', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }

    // Step 5 with no account added: Next just moves on — no accounts required.
    expect(find.text('Your first account'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text("You're all set!"), findsOneWidget);
    expect(find.text('0 accounts'), findsOneWidget);
  });
}