import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/database/app_database.dart';
import 'package:finance_mvp/providers/currency_provider.dart';
import 'package:finance_mvp/providers/revaluation_provider.dart';
import 'package:finance_mvp/screens/accounts_screen.dart';
import 'package:finance_mvp/screens/config_screen.dart';
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/screens/home_screen.dart';
import 'package:finance_mvp/screens/revaluation_screen.dart';
import 'package:finance_mvp/screens/root_screen.dart';
import 'package:finance_mvp/screens/transaction_screen.dart';
import 'package:finance_mvp/screens/transactions_screen.dart';
import 'package:finance_mvp/services/revaluation_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final database = AppDatabase();

  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>(
          create: (_) => database,
          dispose: (_, db) => db.close(),
        ),
        ProxyProvider<AppDatabase, FinanceRepository>(
          update: (_, db, __) => FinanceRepository(db),
        ),
        ProxyProvider<FinanceRepository, RevaluationService>(
          update: (_, repo, __) => RevaluationService(repo),
        ),
        ChangeNotifierProvider<CurrencyProvider>(
          create: (context) =>
              CurrencyProvider(context.read<FinanceRepository>()),
        ),
        ChangeNotifierProvider<RevaluationProvider>(
          create: (context) =>
              RevaluationProvider(context.read<RevaluationService>()),
        ),
      ],
      child: const MyApp(),
    ),
  );
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
      initialRoute: '/v1/boot',
      routes: {
        '/v1/boot': (context) => const RootScreen(),
        '/v1/home': (context) => const HomeScreen(),
        '/v1/transactions': (context) => const TransactionPage(),
        '/v1/transactions/create': (context) => const TransactionScreen(),
        '/v1/accounts': (context) => const AccountsScreen(),
        '/v1/config': (context) => const ConfigScreen(),
        '/v1/revaluation': (context) => const RevaluationScreen(),
      },
    );
  }
}