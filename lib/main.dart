import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/database/app_database.dart';
import 'package:finance_mvp/providers/currency_provider.dart';
import 'package:finance_mvp/providers/revaluation_provider.dart';
import 'package:finance_mvp/providers/theme_provider.dart';
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
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = AppDatabase();
  final themeProvider = await ThemeProvider.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
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
              CurrencyProvider(context.read<FinanceRepository>())
                ..startDailyAutoSync(),
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
    return Consumer<ThemeProvider>(
      builder: (context, theme, _) {
        AppColors.useDark(theme.dark);
        // Transparent system bars (edge-to-edge, enabled in Android
        // styles.xml); SafeArea keeps forms clear of the gesture bar.
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarContrastEnforced: false,
          statusBarIconBrightness:
              theme.dark ? Brightness.light : Brightness.dark,
          systemNavigationBarIconBrightness:
              theme.dark ? Brightness.light : Brightness.dark,
        ));
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Financial Dashboard',
          themeMode: theme.mode,
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          builder: (context, child) => AppPalette(
            colors: AppColors.current,
            child: SafeArea(top: false, child: child!),
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
      },
    );
  }

  ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor:
          dark ? AppColors.darkBackground : AppColors.background,
      primaryColor: dark ? AppColors.darkPrimary : AppColors.primary,
      cardColor: dark ? AppColors.darkCardBackground : AppColors.cardBackground,
      secondaryHeaderColor:
          dark ? AppColors.darkBackground : AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? AppColors.darkBackground : AppColors.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: dark ? AppColors.darkTextDark : AppColors.textDark,
        ),
      ),
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: dark ? AppColors.darkPrimary : AppColors.primary,
        secondary:
            dark ? AppColors.darkCardBackground : AppColors.cardBackground,
        surface: dark ? AppColors.darkBackground : AppColors.background,
        onPrimary: Colors.white,
        onSecondary: dark ? AppColors.darkTextDark : AppColors.textDark,
        onSurface: dark ? AppColors.darkTextDark : AppColors.textDark,
        error: Colors.red,
        onError: Colors.white,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
