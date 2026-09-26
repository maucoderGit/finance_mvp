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

class Contacts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// A personal loan: money someone owes me (`direction = 'debtor'`) or money
/// I owe (`direction = 'creditor'`), optionally linked to a contact.
class Debts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get contactId => integer().nullable().references(Contacts, #id)();
  TextColumn get direction => text().withDefault(const Constant('debtor'))();
  TextColumn get description => text().nullable()();
  RealColumn get amount => real()();
  TextColumn get currencyCode => text().references(Currencies, #code)();
  DateTimeColumn get date => dateTime()();

  /// When the debt (or an installment of a split transaction) is due.
  DateTimeColumn get dueDate => dateTime().nullable()();
  BoolColumn get isSettled => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// How the quota schedule is spaced (weekly/biweekly/monthly). Null for
  /// manual debts created without an installment plan.
  TextColumn get frequency => text().nullable()();
}

/// One installment ("cuota") of a debt split into a payment plan. The parent
/// [Debts] row holds the total; these rows describe the schedule — the amount
/// and due date of each quota, in order.
class DebtInstallments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get debtId => integer().references(Debts, #id)();
  IntColumn get index => integer()();
  RealColumn get amount => real()();
  DateTimeColumn get dueDate => dateTime()();
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();
  IntColumn get accountId => integer().references(Accounts, #id)();
  TextColumn get currencyCode => text().references(Currencies, #code)();
  TextColumn get reference => text().nullable()();

  /// The person/vendor this transaction is with. Relational so a contact can
  /// be tracked across many transactions (spending per contact, contacts list).
  IntColumn get contactId => integer().nullable().references(Contacts, #id)();

  /// When set, this transaction is a payment reducing the linked debt's
  /// outstanding amount.
  IntColumn get debtId => integer().nullable().references(Debts, #id)();

  /// When set, this transaction *was the source* of the linked debt and its
  /// quota schedule — debt mode was used at creation. Editing the transaction
  /// re-writes that debt/installment schedule.
  IntColumn get sourceDebtId => integer().nullable().references(Debts, #id)();
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
    Contacts,
    Debts,
    DebtInstallments,
    Transactions,
    UserSettings,
    NetWorthHistory,
    MarketRates,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase({QueryExecutor? executor}) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 13;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaultData();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await _addColumnIfMissing(m, accounts, accounts.includeInRevaluation);
            await _addColumnIfMissing(
                m, transactions, transactions.exchangeRateAtCreation);
            await _addColumnIfMissing(
                m, transactions, transactions.baseCurrencyAmount);
            await _addColumnIfMissing(
                m, userSettings, userSettings.currencySelectionMode);
            await _addColumnIfMissing(
                m, userSettings, userSettings.lastAutoFetchDate);
            await _createTableIfMissing(m, netWorthHistory);
          }
          if (from < 3) {
            await _addColumnIfMissing(
                m, userSettings, userSettings.nationalCurrencyCode);
            await _addColumnIfMissing(
                m, userSettings, userSettings.hasCompletedOnboarding);
          }
          if (from < 4) {
            await _addColumnIfMissing(m, transactions, transactions.imagePath);
          }
          if (from < 5) {
            // Fresh DBs get UNIQUE(currency_code, date) from customConstraints,
            // but pre-v5 installs never had it — so re-syncs piled up
            // duplicate rates. Dedupe (keep the newest id per code+date) and
            // add the index for existing databases. A `currency_rates` that is
            // absent or stuck on a stale pre-v5 schema (no currency_code/date)
            // is just an exchange-rate cache: rebuild it from the current
            // schema instead of trying to ALTER a table we can't trust.
            if (!await _hasColumns(
                m, 'currency_rates', ['currency_code', 'date'])) {
              if (await _tableExists(m, 'currency_rates')) {
                await m.deleteTable(currencyRates.actualTableName);
              }
              await m.createTable(currencyRates);
            } else {
              await m.database.customStatement(
                'DELETE FROM currency_rates WHERE id NOT IN '
                '(SELECT MAX(id) FROM currency_rates GROUP BY currency_code, date)',
              );
              await m.database.customStatement(
                'CREATE UNIQUE INDEX IF NOT EXISTS currency_rates_code_date '
                'ON currency_rates (currency_code, date)',
              );
            }
          }
          if (from < 6) {
            await _addColumnIfMissing(m, transactions, transactions.fxDelta);
            await _createTableIfMissing(m, marketRates);
          }
          if (from < 7) {
            await _addColumnIfMissing(
                m, transactions, transactions.transferGroupId);
          }
          if (from < 8) {
            await _createTableIfMissing(m, contacts);
            await _addColumnIfMissing(
                m, transactions, transactions.contactId);
            // Contact moved from a free-text column to a relational FK.
            if (await _hasColumns(m, 'transactions', ['contact'])) {
              await m.dropColumn(transactions, 'contact');
            }
          }
          if (from < 9) {
            await _createTableIfMissing(m, debts);
          }
          if (from < 10) {
            await _addColumnIfMissing(m, transactions, transactions.debtId);
          }
          if (from < 11) {
            await _addColumnIfMissing(m, debts, debts.dueDate);
          }
          if (from < 12) {
            await _createTableIfMissing(m, debtInstallments);
          }
          if (from < 13) {
            await _addColumnIfMissing(m, debts, debts.frequency);
            await _addColumnIfMissing(m, transactions, transactions.sourceDebtId);
          }
        },
        beforeOpen: (details) async {
          // Last line of defense: a DB from a much older app version (or one
          // mangled by crashed migrations) can carry a schema no upgrade step
          // knows how to repair — legacy columns drift declares no longer, or
          // NOT NULL columns drift never writes. If any declared column is
          // missing from a live table, rebuild everything from the current
          // schema. Cheap on healthy DBs: a handful of PRAGMA reads.
          if (!await _schemaMatchesDrift()) {
            for (final table in allTables) {
              await customStatement(
                  'DROP TABLE IF EXISTS "${table.actualTableName}"');
            }
            final migrator = Migrator(this);
            await migrator.createAll();
            await _seedDefaultData();
          }
        },
      );

  Future<void> _addColumnIfMissing(
    Migrator m,
    TableInfo<Table, DataClass> table,
    GeneratedColumn column,
  ) async {
    // A partially-created DB may lack the whole table, not just the column.
    // Creating it brings the full current schema, so the column is present and
    // the ALTER below becomes a no-op.
    if (!await _tableExists(m, table.actualTableName)) {
      await m.createTable(table);
      return;
    }
    final columns = await m.database
        .customSelect('PRAGMA table_info("${table.actualTableName}")')
        .get();
    final names = columns.map((r) => r.read<String>('name')).toSet();
    if (!names.contains(column.name)) {
      await m.addColumn(table, column);
    }
  }

  Future<void> _createTableIfMissing(
    Migrator m,
    TableInfo<Table, DataClass> table,
  ) async {
    if (!await _tableExists(m, table.actualTableName)) {
      await m.createTable(table);
    }
  }

  Future<bool> _tableExists(Migrator m, String name) async {
    final rows = await m.database
        .customSelect(
          'SELECT name FROM sqlite_master '
          'WHERE type = \'table\' AND name = ?',
          variables: [Variable(name)],
        )
        .get();
    return rows.isNotEmpty;
  }

  Future<bool> _hasColumns(
    Migrator m,
    String table,
    List<String> columns,
  ) async {
    final cols = await m.database
        .customSelect('PRAGMA table_info("$table")')
        .get();
    final names = cols.map((r) => r.read<String>('name')).toSet();
    return columns.every(names.contains);
  }

  Future<bool> _schemaMatchesDrift() async {
    for (final table in allTables) {
      final cols = await customSelect(
              'PRAGMA table_info("${table.actualTableName}")')
          .get();
      final names = cols.map((r) => r.read<String>('name')).toSet();
      if (!table.$columns.every((c) => names.contains(c.name))) {
        return false;
      }
    }
    return true;
  }

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
