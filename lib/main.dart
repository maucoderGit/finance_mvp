import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/screens/config.dart';
import 'package:finance_mvp/screens/currency_screen.dart';
import 'package:finance_mvp/screens/home_screen.dart';
import 'package:finance_mvp/screens/transaction_screen.dart';
import 'package:finance_mvp/screens/transactions_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Financial Dashboard',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        cardColor: AppColors.cardBackground,
        secondaryHeaderColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.cardBackground,
          surface: AppColors.background,
        ),
        fontFamily: 'Inter', // A modern font, add it to your pubspec.yaml
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/v1/home',
      routes: {
        '/v1/home': (context) => const HomeScreen(),
        '/v1/config': (context) => const ConfigScreen(),
        '/v1/config/currency': (context) => const CurrencyScreen(),
        '/v1/transactions': (context) => const TransactionPage(),
        '/v1/transactions/create': (context) => const TransactionScreen(),
      },
    );
  }
}