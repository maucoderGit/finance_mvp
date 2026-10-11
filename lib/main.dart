import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/database/app_database.dart';
import 'package:finance_mvp/l10n/app_localizations.dart';
import 'package:finance_mvp/providers/currency_provider.dart';
import 'package:finance_mvp/providers/locale_provider.dart';
import 'package:finance_mvp/providers/notification_provider.dart';
import 'package:finance_mvp/providers/revaluation_provider.dart';
import 'package:finance_mvp/providers/theme_provider.dart';
import 'package:finance_mvp/screens/accounts/accounts_screen.dart';
import 'package:finance_mvp/screens/settings/config_screen.dart';
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/screens/overview/dashboard_screen.dart';
import 'package:finance_mvp/screens/overview/home_screen.dart';
import 'package:finance_mvp/screens/revaluation/revaluation_screen.dart';
import 'package:finance_mvp/screens/overview/root_screen.dart';
import 'package:finance_mvp/screens/transactions/transaction_screen.dart';
import 'package:finance_mvp/screens/transactions/transactions_screen.dart';
import 'package:finance_mvp/services/finance/revaluation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = AppDatabase();
  final themeProvider = await ThemeProvider.load();
  final localeProvider = await LocaleProvider.load();
  final notificationProvider = NotificationProvider(
    await SharedPreferences.getInstance(),
  );
  await notificationProvider.init();
  if (notificationProvider.enabled) {
    final locale =
        localeProvider.locale ?? WidgetsBinding.instance.platformDispatcher.locale;
    final l10n = await AppLocalizations.delegate.load(locale);
    await notificationProvider.configure(
      enabled: true,
      hour: notificationProvider.hour,
      minute: notificationProvider.minute,
      title: l10n.notificationReminderTitle,
      body: l10n.notificationReminderBody,
    );
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
        ChangeNotifierProvider<NotificationProvider>.value(
          value: notificationProvider,
        ),
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
    final locale = context.watch<LocaleProvider>().locale;
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
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
            '/v1/dashboard': (context) => const DashboardScreen(),
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
