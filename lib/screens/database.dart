import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

class Currencies extends Table {
  TextColumn get code => text().withLength(min: 3, max: 3)();
  TextColumn get name => text()();
  TextColumn get symbol => text()();
  TextColumn get separator => text().withLength(min: 1, max: 1).withDefault(const Constant(','))();
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
  TextColumn get icon => text()(); // Stores the icon identifier or codePoint
  IntColumn get iconColor => integer()();
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
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  IntColumn get accountId => integer().references(Accounts, #id)();
  TextColumn get currencyCode => text().references(Currencies, #code)();
  TextColumn get reference => text().nullable()();
  TextColumn get contact => text().nullable()();

  // Recurrence settings from the UI
  BoolColumn get isRecurrenceEnabled => boolean().withDefault(const Constant(false))();
  TextColumn get recurrenceType => text().nullable()(); // e.g., 'Monthly'
  TextColumn get recurrenceEnds => text().nullable()(); // e.g., 'Until I cancel'

  DateTimeColumn get date => dateTime()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  
}

class UserSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  TextColumn get baseCurrencyCode => text().references(Currencies, #code)();
  TextColumn get username => text().withDefault(const Constant('User'))();
  TextColumn get profilePicturePath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}


@DriftDatabase(tables: [Currencies, CurrencyRates, Accounts, Categories, Transactions, UserSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}