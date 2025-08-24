import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/screens/home_screen.dart';
import 'package:finance_mvp/screens/invoice_screen.dart';
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
        fontFamily: 'Inter', // A modern font, add it to your pubspec.yaml
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/v1/home',
      routes: {
        '/v1/home': (context) => const HomeScreen(),
        '/v1/transactions': (context) => const TransactionPage(),
        '/v1/transactions/create': (context) => const transactionscreen(),
      },
    );
  }
}