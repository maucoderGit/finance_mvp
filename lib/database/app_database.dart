import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'daos/account_dao.dart';
import 'daos/transaction_dao.dart';
import 'daos/currency_dao.dart';

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
  BoolColumn get isRecurrenceEnabled =>
      boolean().withDefault(const Constant(false))();
  TextColumn get recurrenceType => text().nullable()();
  TextColumn get recurrenceEnds => text().nullable()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  RealColumn get exchangeRateAtCreation => real().nullable()();
  RealColumn get baseCurrencyAmount => real().nullable()();
}

class UserSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  TextColumn get baseCurrencyCode => text().references(Currencies, #code)();
  TextColumn get username => text().withDefault(const Constant('User'))();
  TextColumn get profilePicturePath => text().nullable()();
  TextColumn get currencySelectionMode =>
      text().withDefault(const Constant('auto'))();
  DateTimeColumn get lastAutoFetchDate => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ExchangeRateSnapshots extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get ratesJson => text()();
  TextColumn get source => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<String> get customConstraints => ['UNIQUE(date)'];
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
    ExchangeRateSnapshots,
    NetWorthHistory,
  ],
  daos: [AccountDao, TransactionDao, CurrencyDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

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
            await m.createTable(exchangeRateSnapshots);
            await m.createTable(netWorthHistory);
          }
        },
      );

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

      batch.insert(userSettings, const UserSettingsCompanion());
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
