import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finance_mvp/screens/onboarding/onboarding_screen.dart';

void main() {
  testWidgets('Onboarding wizard walks through all steps', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    // Step 0: welcome.
    expect(find.text('Welcome to\nAtelier Finance'), findsOneWidget);
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

    // Step 5: summary.
    expect(find.text("You're all set!"), findsOneWidget);
    expect(find.text('USD'), findsOneWidget);
    expect(find.text('VES'), findsOneWidget);
    expect(find.text('Automatic sync'), findsOneWidget);
  });
}