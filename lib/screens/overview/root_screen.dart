import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/database/app_database.dart';
import 'package:finance_mvp/providers/currency_provider.dart';
import 'package:finance_mvp/screens/overview/home_screen.dart';
import 'package:finance_mvp/screens/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Entry widget: shows the onboarding wizard on first launch, then the home
/// screen. Reacts to the user-settings stream so it auto-switches after the
/// onboarding flow finishes.
class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyProvider = context.read<CurrencyProvider>();

    return StreamBuilder<UserSetting?>(
      stream: currencyProvider.watchUserSettings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }

        final settings = snapshot.data;
        final onboarded = settings?.hasCompletedOnboarding ?? false;

        return onboarded
            ? const HomeScreen()
            : const OnboardingScreen();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet,
                size: 72, color: context.colors.primary),
            const SizedBox(height: 16),
            Text(
              'Finance',
              style: TextStyle(
                color: context.colors.textDark,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: context.colors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}