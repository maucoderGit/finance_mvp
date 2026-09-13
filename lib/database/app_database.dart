import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

class Currencies extends Table {
  TextColumn get code => text().withLength(min: 3, max: 3)();
  TextColumn get name => text()();
  TextColumn get symbol => text()();
  TextColumn get separator =>
      text().withLength(min: 1, max: 1).withDefault(const Constant(','))();
  IntColumn get decimalDigits => integer().withDefault(const Constant(2))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {code};
}

@DataClassName('ExchangeRate')
class CurrencyRates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get currencyCode => text().references(Currencies, #code)();
  RealColumn get rate => real()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<String> get customConstraints => ['UNIQUE(currency_code, date)'];
}

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get subtitle => text().nullable()();
  TextColumn get currencyCode => text().references(Currencies, #code)();
  TextColumn get icon => text()();
  IntColumn get iconColor => integer()();
  BoolColumn get includeInRevaluation =>
      boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get icon => text()();
  IntColumn get color => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();
  IntColumn get accountId => integer().references(Accounts, #id)();
  TextColumn get currencyCode => text().references(Currencies, #code)();
  TextColumn get reference => text().nullable()();
  TextColumn get contact => text().nullable()();
  TextColumn get imagePath => text().nullable()();
  BoolColumn get isRecurrenceEnabled =>
      boolean().withDefault(const Constant(false))();
  TextColumn get recurrenceType => text().nullable()();
  TextColumn get recurrenceEnds => text().nullable()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  RealColumn get exchangeRateAtCreation => real().nullable()();
  RealColumn get baseCurrencyAmount => real().nullable()();
  RealColumn get fxDelta => real().nullable()();

  /// Groups the two legs of an internal transfer/menudeo. Null for plain
  /// income/expense transactions. Deleting one leg removes the whole pair.
  TextColumn get transferGroupId => text().nullable()();
}

/// Cached unofficial/parallel (P2P) VES→USD market rates, one row per day.
/// The official BCV rate lives in [CurrencyRates] as the VES rate; this table
/// holds the free-market price used for net-worth valuation and FX deltas.
class MarketRates extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get rate => real()();
  DateTimeColumn get date => dateTime().unique()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class UserSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  TextColumn get baseCurrencyCode => text().references(Currencies, #code)();
  TextColumn get username => text().withDefault(const Constant('User'))();
  TextColumn get profilePicturePath => text().nullable()();
  TextColumn get nationalCurrencyCode =>
      text().nullable().references(Currencies, #code)();
  TextColumn get currencySelectionMode =>
      text().withDefault(const Constant('auto'))();
  DateTimeColumn get lastAutoFetchDate => dateTime().nullable()();
  BoolColumn get hasCompletedOnboarding =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class NetWorthHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime().unique()();
  RealColumn get totalInBaseCurrency => real()();
  RealColumn get totalInNationalCurrency => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(
  tables: [
    Currencies,
    CurrencyRates,
    Accounts,
    Categories,
    Transactions,
    UserSettings,
    NetWorthHistory,
    MarketRates,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase({QueryExecutor? executor}) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaultData();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(accounts, accounts.includeInRevaluation);
            await m.addColumn(transactions, transactions.exchangeRateAtCreation);
            await m.addColumn(transactions, transactions.baseCurrencyAmount);
            await m.addColumn(
                userSettings, userSettings.currencySelectionMode);
            await m.addColumn(
                userSettings, userSettings.lastAutoFetchDate);
            await m.createTable(netWorthHistory);
          }
          if (from < 3) {
            await m.addColumn(
                userSettings, userSettings.nationalCurrencyCode);
            await m.addColumn(
                userSettings, userSettings.hasCompletedOnboarding);
          }
          if (from < 4) {
            await m.addColumn(transactions, transactions.imagePath);
          }
          if (from < 5) {
            // Fresh DBs get UNIQUE(currency_code, date) from customConstraints,
            // but pre-v5 installs never had it — so re-syncs piled up
            // duplicate rates. Dedupe (keep the newest id per code+date) and
            // add the index for existing databases.
            await m.database.customStatement(
              'DELETE FROM currency_rates WHERE id NOT IN '
              '(SELECT MAX(id) FROM currency_rates GROUP BY currency_code, date)',
            );
            await m.database.customStatement(
              'CREATE UNIQUE INDEX currency_rates_code_date '
              'ON currency_rates (currency_code, date)',
            );
          }
          if (from < 6) {
            await m.addColumn(transactions, transactions.fxDelta);
            await m.createTable(marketRates);
          }
          if (from < 7) {
            await m.addColumn(transactions, transactions.transferGroupId);
          }
        },
      );

  /// Delete every row across all tables, then re-seed the default currencies,
  /// categories and an un-onboarded settings row (fresh-install state).
  Future<void> resetAllData() async {
    await transaction(() async {
      // Children first so foreign keys never dangle regardless of enforcement.
      await delete(netWorthHistory).go();
      await delete(marketRates).go();
      await delete(currencyRates).go();
      await delete(transactions).go();
      await delete(accounts).go();
      await delete(categories).go();
      await delete(userSettings).go();
      await delete(currencies).go();
      await _seedDefaultData();
    });
  }

  Future<void> _seedDefaultData() async {
    final now = DateTime.now();

    await batch((batch) {
      batch.insertAll(currencies, [
        CurrenciesCompanion.insert(
          code: 'USD',
          name: 'US Dollar',
          symbol: r'$',
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        CurrenciesCompanion.insert(
          code: 'VES',
          name: 'Venezuelan Bolivar',
          symbol: 'Bs.',
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        CurrenciesCompanion.insert(
          code: 'EUR',
          name: 'Euro',
          symbol: '\u20ac',
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      ]);

      batch.insertAll(categories, [
        CategoriesCompanion.insert(
          name: 'Services',
          icon: 'home_repair_service',
          color: 0xFF4CAF50,
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        CategoriesCompanion.insert(
          name: 'Food',
          icon: 'restaurant',
          color: 0xFFFF9800,
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        CategoriesCompanion.insert(
          name: 'Transport',
          icon: 'directions_car',
          color: 0xFF2196F3,
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        CategoriesCompanion.insert(
          name: 'Shopping',
          icon: 'shopping_bag',
          color: 0xFFE91E63,
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        CategoriesCompanion.insert(
          name: 'Utilities',
          icon: 'bolt',
          color: 0xFF9C27B0,
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        CategoriesCompanion.insert(
          name: 'Entertainment',
          icon: 'movie',
          color: 0xFFFF5722,
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        CategoriesCompanion.insert(
          name: 'Health',
          icon: 'local_hospital',
          color: 0xFFF44336,
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        CategoriesCompanion.insert(
          name: 'Education',
          icon: 'school',
          color: 0xFF00BCD4,
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        CategoriesCompanion.insert(
          name: 'Salary',
          icon: 'payments',
          color: 0xFF8BC34A,
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        CategoriesCompanion.insert(
          name: 'Investments',
          icon: 'trending_up',
          color: 0xFF3F51B5,
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      ]);

      batch.insert(userSettings, const UserSettingsCompanion(
          id: Value(0),
          baseCurrencyCode: Value('USD'),
          nationalCurrencyCode: Value('VES'),
          hasCompletedOnboarding: Value(false),
        ));
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}
