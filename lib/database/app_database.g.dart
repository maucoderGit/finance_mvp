// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CurrenciesTable extends Currencies
    with TableInfo<$CurrenciesTable, Currency> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CurrenciesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 3, maxTextLength: 3),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  @override
  late final GeneratedColumn<String> symbol = GeneratedColumn<String>(
      'symbol', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _separatorMeta =
      const VerificationMeta('separator');
  @override
  late final GeneratedColumn<String> separator = GeneratedColumn<String>(
      'separator', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 1),
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(','));
  static const VerificationMeta _decimalDigitsMeta =
      const VerificationMeta('decimalDigits');
  @override
  late final GeneratedColumn<int> decimalDigits = GeneratedColumn<int>(
      'decimal_digits', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(2));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [code, name, symbol, separator, decimalDigits, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'currencies';
  @override
  VerificationContext validateIntegrity(Insertable<Currency> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('symbol')) {
      context.handle(_symbolMeta,
          symbol.isAcceptableOrUnknown(data['symbol']!, _symbolMeta));
    } else if (isInserting) {
      context.missing(_symbolMeta);
    }
    if (data.containsKey('separator')) {
      context.handle(_separatorMeta,
          separator.isAcceptableOrUnknown(data['separator']!, _separatorMeta));
    }
    if (data.containsKey('decimal_digits')) {
      context.handle(
          _decimalDigitsMeta,
          decimalDigits.isAcceptableOrUnknown(
              data['decimal_digits']!, _decimalDigitsMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {code};
  @override
  Currency map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Currency(
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      symbol: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}symbol'])!,
      separator: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}separator'])!,
      decimalDigits: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}decimal_digits'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CurrenciesTable createAlias(String alias) {
    return $CurrenciesTable(attachedDatabase, alias);
  }
}

class Currency extends DataClass implements Insertable<Currency> {
  final String code;
  final String name;
  final String symbol;
  final String separator;
  final int decimalDigits;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Currency(
      {required this.code,
      required this.name,
      required this.symbol,
      required this.separator,
      required this.decimalDigits,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    map['symbol'] = Variable<String>(symbol);
    map['separator'] = Variable<String>(separator);
    map['decimal_digits'] = Variable<int>(decimalDigits);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CurrenciesCompanion toCompanion(bool nullToAbsent) {
    return CurrenciesCompanion(
      code: Value(code),
      name: Value(name),
      symbol: Value(symbol),
      separator: Value(separator),
      decimalDigits: Value(decimalDigits),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Currency.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Currency(
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      symbol: serializer.fromJson<String>(json['symbol']),
      separator: serializer.fromJson<String>(json['separator']),
      decimalDigits: serializer.fromJson<int>(json['decimalDigits']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'symbol': serializer.toJson<String>(symbol),
      'separator': serializer.toJson<String>(separator),
      'decimalDigits': serializer.toJson<int>(decimalDigits),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Currency copyWith(
          {String? code,
          String? name,
          String? symbol,
          String? separator,
          int? decimalDigits,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Currency(
        code: code ?? this.code,
        name: name ?? this.name,
        symbol: symbol ?? this.symbol,
        separator: separator ?? this.separator,
        decimalDigits: decimalDigits ?? this.decimalDigits,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Currency copyWithCompanion(CurrenciesCompanion data) {
    return Currency(
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      symbol: data.symbol.present ? data.symbol.value : this.symbol,
      separator: data.separator.present ? data.separator.value : this.separator,
      decimalDigits: data.decimalDigits.present
          ? data.decimalDigits.value
          : this.decimalDigits,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Currency(')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('symbol: $symbol, ')
          ..write('separator: $separator, ')
          ..write('decimalDigits: $decimalDigits, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      code, name, symbol, separator, decimalDigits, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Currency &&
          other.code == this.code &&
          other.name == this.name &&
          other.symbol == this.symbol &&
          other.separator == this.separator &&
          other.decimalDigits == this.decimalDigits &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CurrenciesCompanion extends UpdateCompanion<Currency> {
  final Value<String> code;
  final Value<String> name;
  final Value<String> symbol;
  final Value<String> separator;
  final Value<int> decimalDigits;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CurrenciesCompanion({
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.symbol = const Value.absent(),
    this.separator = const Value.absent(),
    this.decimalDigits = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CurrenciesCompanion.insert({
    required String code,
    required String name,
    required String symbol,
    this.separator = const Value.absent(),
    this.decimalDigits = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : code = Value(code),
        name = Value(name),
        symbol = Value(symbol);
  static Insertable<Currency> custom({
    Expression<String>? code,
    Expression<String>? name,
    Expression<String>? symbol,
    Expression<String>? separator,
    Expression<int>? decimalDigits,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (symbol != null) 'symbol': symbol,
      if (separator != null) 'separator': separator,
      if (decimalDigits != null) 'decimal_digits': decimalDigits,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CurrenciesCompanion copyWith(
      {Value<String>? code,
      Value<String>? name,
      Value<String>? symbol,
      Value<String>? separator,
      Value<int>? decimalDigits,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return CurrenciesCompanion(
      code: code ?? this.code,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      separator: separator ?? this.separator,
      decimalDigits: decimalDigits ?? this.decimalDigits,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (symbol.present) {
      map['symbol'] = Variable<String>(symbol.value);
    }
    if (separator.present) {
      map['separator'] = Variable<String>(separator.value);
    }
    if (decimalDigits.present) {
      map['decimal_digits'] = Variable<int>(decimalDigits.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CurrenciesCompanion(')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('symbol: $symbol, ')
          ..write('separator: $separator, ')
          ..write('decimalDigits: $decimalDigits, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CurrencyRatesTable extends CurrencyRates
    with TableInfo<$CurrencyRatesTable, ExchangeRate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CurrencyRatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _currencyCodeMeta =
      const VerificationMeta('currencyCode');
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
      'currency_code', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES currencies (code)'));
  static const VerificationMeta _rateMeta = const VerificationMeta('rate');
  @override
  late final GeneratedColumn<double> rate = GeneratedColumn<double>(
      'rate', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, currencyCode, rate, date, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'currency_rates';
  @override
  VerificationContext validateIntegrity(Insertable<ExchangeRate> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('currency_code')) {
      context.handle(
          _currencyCodeMeta,
          currencyCode.isAcceptableOrUnknown(
              data['currency_code']!, _currencyCodeMeta));
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('rate')) {
      context.handle(
          _rateMeta, rate.isAcceptableOrUnknown(data['rate']!, _rateMeta));
    } else if (isInserting) {
      context.missing(_rateMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExchangeRate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExchangeRate(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      currencyCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency_code'])!,
      rate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}rate'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CurrencyRatesTable createAlias(String alias) {
    return $CurrencyRatesTable(attachedDatabase, alias);
  }
}

class ExchangeRate extends DataClass implements Insertable<ExchangeRate> {
  final int id;
  final String currencyCode;
  final double rate;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ExchangeRate(
      {required this.id,
      required this.currencyCode,
      required this.rate,
      required this.date,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['currency_code'] = Variable<String>(currencyCode);
    map['rate'] = Variable<double>(rate);
    map['date'] = Variable<DateTime>(date);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CurrencyRatesCompanion toCompanion(bool nullToAbsent) {
    return CurrencyRatesCompanion(
      id: Value(id),
      currencyCode: Value(currencyCode),
      rate: Value(rate),
      date: Value(date),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ExchangeRate.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExchangeRate(
      id: serializer.fromJson<int>(json['id']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      rate: serializer.fromJson<double>(json['rate']),
      date: serializer.fromJson<DateTime>(json['date']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'rate': serializer.toJson<double>(rate),
      'date': serializer.toJson<DateTime>(date),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ExchangeRate copyWith(
          {int? id,
          String? currencyCode,
          double? rate,
          DateTime? date,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      ExchangeRate(
        id: id ?? this.id,
        currencyCode: currencyCode ?? this.currencyCode,
        rate: rate ?? this.rate,
        date: date ?? this.date,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ExchangeRate copyWithCompanion(CurrencyRatesCompanion data) {
    return ExchangeRate(
      id: data.id.present ? data.id.value : this.id,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      rate: data.rate.present ? data.rate.value : this.rate,
      date: data.date.present ? data.date.value : this.date,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExchangeRate(')
          ..write('id: $id, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('rate: $rate, ')
          ..write('date: $date, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, currencyCode, rate, date, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExchangeRate &&
          other.id == this.id &&
          other.currencyCode == this.currencyCode &&
          other.rate == this.rate &&
          other.date == this.date &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CurrencyRatesCompanion extends UpdateCompanion<ExchangeRate> {
  final Value<int> id;
  final Value<String> currencyCode;
  final Value<double> rate;
  final Value<DateTime> date;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CurrencyRatesCompanion({
    this.id = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.rate = const Value.absent(),
    this.date = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CurrencyRatesCompanion.insert({
    this.id = const Value.absent(),
    required String currencyCode,
    required double rate,
    required DateTime date,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : currencyCode = Value(currencyCode),
        rate = Value(rate),
        date = Value(date);
  static Insertable<ExchangeRate> custom({
    Expression<int>? id,
    Expression<String>? currencyCode,
    Expression<double>? rate,
    Expression<DateTime>? date,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (rate != null) 'rate': rate,
      if (date != null) 'date': date,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CurrencyRatesCompanion copyWith(
      {Value<int>? id,
      Value<String>? currencyCode,
      Value<double>? rate,
      Value<DateTime>? date,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return CurrencyRatesCompanion(
      id: id ?? this.id,
      currencyCode: currencyCode ?? this.currencyCode,
      rate: rate ?? this.rate,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (rate.present) {
      map['rate'] = Variable<double>(rate.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CurrencyRatesCompanion(')
          ..write('id: $id, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('rate: $rate, ')
          ..write('date: $date, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subtitleMeta =
      const VerificationMeta('subtitle');
  @override
  late final GeneratedColumn<String> subtitle = GeneratedColumn<String>(
      'subtitle', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _currencyCodeMeta =
      const VerificationMeta('currencyCode');
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
      'currency_code', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES currencies (code)'));
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _iconColorMeta =
      const VerificationMeta('iconColor');
  @override
  late final GeneratedColumn<int> iconColor = GeneratedColumn<int>(
      'icon_color', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _includeInRevaluationMeta =
      const VerificationMeta('includeInRevaluation');
  @override
  late final GeneratedColumn<bool> includeInRevaluation = GeneratedColumn<bool>(
      'include_in_revaluation', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("include_in_revaluation" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        subtitle,
        currencyCode,
        icon,
        iconColor,
        includeInRevaluation,
        updatedAt,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(Insertable<Account> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('subtitle')) {
      context.handle(_subtitleMeta,
          subtitle.isAcceptableOrUnknown(data['subtitle']!, _subtitleMeta));
    }
    if (data.containsKey('currency_code')) {
      context.handle(
          _currencyCodeMeta,
          currencyCode.isAcceptableOrUnknown(
              data['currency_code']!, _currencyCodeMeta));
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    } else if (isInserting) {
      context.missing(_iconMeta);
    }
    if (data.containsKey('icon_color')) {
      context.handle(_iconColorMeta,
          iconColor.isAcceptableOrUnknown(data['icon_color']!, _iconColorMeta));
    } else if (isInserting) {
      context.missing(_iconColorMeta);
    }
    if (data.containsKey('include_in_revaluation')) {
      context.handle(
          _includeInRevaluationMeta,
          includeInRevaluation.isAcceptableOrUnknown(
              data['include_in_revaluation']!, _includeInRevaluationMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      subtitle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subtitle']),
      currencyCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency_code'])!,
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon'])!,
      iconColor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}icon_color'])!,
      includeInRevaluation: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}include_in_revaluation'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class Account extends DataClass implements Insertable<Account> {
  final int id;
  final String name;
  final String? subtitle;
  final String currencyCode;
  final String icon;
  final int iconColor;
  final bool includeInRevaluation;
  final DateTime updatedAt;
  final DateTime createdAt;
  const Account(
      {required this.id,
      required this.name,
      this.subtitle,
      required this.currencyCode,
      required this.icon,
      required this.iconColor,
      required this.includeInRevaluation,
      required this.updatedAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || subtitle != null) {
      map['subtitle'] = Variable<String>(subtitle);
    }
    map['currency_code'] = Variable<String>(currencyCode);
    map['icon'] = Variable<String>(icon);
    map['icon_color'] = Variable<int>(iconColor);
    map['include_in_revaluation'] = Variable<bool>(includeInRevaluation);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      name: Value(name),
      subtitle: subtitle == null && nullToAbsent
          ? const Value.absent()
          : Value(subtitle),
      currencyCode: Value(currencyCode),
      icon: Value(icon),
      iconColor: Value(iconColor),
      includeInRevaluation: Value(includeInRevaluation),
      updatedAt: Value(updatedAt),
      createdAt: Value(createdAt),
    );
  }

  factory Account.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      subtitle: serializer.fromJson<String?>(json['subtitle']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      icon: serializer.fromJson<String>(json['icon']),
      iconColor: serializer.fromJson<int>(json['iconColor']),
      includeInRevaluation:
          serializer.fromJson<bool>(json['includeInRevaluation']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'subtitle': serializer.toJson<String?>(subtitle),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'icon': serializer.toJson<String>(icon),
      'iconColor': serializer.toJson<int>(iconColor),
      'includeInRevaluation': serializer.toJson<bool>(includeInRevaluation),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Account copyWith(
          {int? id,
          String? name,
          Value<String?> subtitle = const Value.absent(),
          String? currencyCode,
          String? icon,
          int? iconColor,
          bool? includeInRevaluation,
          DateTime? updatedAt,
          DateTime? createdAt}) =>
      Account(
        id: id ?? this.id,
        name: name ?? this.name,
        subtitle: subtitle.present ? subtitle.value : this.subtitle,
        currencyCode: currencyCode ?? this.currencyCode,
        icon: icon ?? this.icon,
        iconColor: iconColor ?? this.iconColor,
        includeInRevaluation: includeInRevaluation ?? this.includeInRevaluation,
        updatedAt: updatedAt ?? this.updatedAt,
        createdAt: createdAt ?? this.createdAt,
      );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      subtitle: data.subtitle.present ? data.subtitle.value : this.subtitle,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      icon: data.icon.present ? data.icon.value : this.icon,
      iconColor: data.iconColor.present ? data.iconColor.value : this.iconColor,
      includeInRevaluation: data.includeInRevaluation.present
          ? data.includeInRevaluation.value
          : this.includeInRevaluation,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('subtitle: $subtitle, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('icon: $icon, ')
          ..write('iconColor: $iconColor, ')
          ..write('includeInRevaluation: $includeInRevaluation, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, subtitle, currencyCode, icon,
      iconColor, includeInRevaluation, updatedAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.id == this.id &&
          other.name == this.name &&
          other.subtitle == this.subtitle &&
          other.currencyCode == this.currencyCode &&
          other.icon == this.icon &&
          other.iconColor == this.iconColor &&
          other.includeInRevaluation == this.includeInRevaluation &&
          other.updatedAt == this.updatedAt &&
          other.createdAt == this.createdAt);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> subtitle;
  final Value<String> currencyCode;
  final Value<String> icon;
  final Value<int> iconColor;
  final Value<bool> includeInRevaluation;
  final Value<DateTime> updatedAt;
  final Value<DateTime> createdAt;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.subtitle = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.icon = const Value.absent(),
    this.iconColor = const Value.absent(),
    this.includeInRevaluation = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AccountsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.subtitle = const Value.absent(),
    required String currencyCode,
    required String icon,
    required int iconColor,
    this.includeInRevaluation = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : name = Value(name),
        currencyCode = Value(currencyCode),
        icon = Value(icon),
        iconColor = Value(iconColor);
  static Insertable<Account> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? subtitle,
    Expression<String>? currencyCode,
    Expression<String>? icon,
    Expression<int>? iconColor,
    Expression<bool>? includeInRevaluation,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (subtitle != null) 'subtitle': subtitle,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (icon != null) 'icon': icon,
      if (iconColor != null) 'icon_color': iconColor,
      if (includeInRevaluation != null)
        'include_in_revaluation': includeInRevaluation,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AccountsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String?>? subtitle,
      Value<String>? currencyCode,
      Value<String>? icon,
      Value<int>? iconColor,
      Value<bool>? includeInRevaluation,
      Value<DateTime>? updatedAt,
      Value<DateTime>? createdAt}) {
    return AccountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      currencyCode: currencyCode ?? this.currencyCode,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      includeInRevaluation: includeInRevaluation ?? this.includeInRevaluation,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (subtitle.present) {
      map['subtitle'] = Variable<String>(subtitle.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (iconColor.present) {
      map['icon_color'] = Variable<int>(iconColor.value);
    }
    if (includeInRevaluation.present) {
      map['include_in_revaluation'] =
          Variable<bool>(includeInRevaluation.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('subtitle: $subtitle, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('icon: $icon, ')
          ..write('iconColor: $iconColor, ')
          ..write('includeInRevaluation: $includeInRevaluation, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
      'color', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, icon, color, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(Insertable<Category> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    } else if (isInserting) {
      context.missing(_iconMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}color'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final int id;
  final String name;
  final String icon;
  final int color;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Category(
      {required this.id,
      required this.name,
      required this.icon,
      required this.color,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['icon'] = Variable<String>(icon);
    map['color'] = Variable<int>(color);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      icon: Value(icon),
      color: Value(color),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Category.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String>(json['icon']),
      color: serializer.fromJson<int>(json['color']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String>(icon),
      'color': serializer.toJson<int>(color),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Category copyWith(
          {int? id,
          String? name,
          String? icon,
          int? color,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Category(
        id: id ?? this.id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      color: data.color.present ? data.color.value : this.color,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, icon, color, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.color == this.color &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> icon;
  final Value<int> color;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String icon,
    required int color,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : name = Value(name),
        icon = Value(icon),
        color = Value(color);
  static Insertable<Category> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<int>? color,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CategoriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? icon,
      Value<int>? color,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
      'category_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES categories (id)'));
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
      'account_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'));
  static const VerificationMeta _currencyCodeMeta =
      const VerificationMeta('currencyCode');
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
      'currency_code', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES currencies (code)'));
  static const VerificationMeta _referenceMeta =
      const VerificationMeta('reference');
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
      'reference', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _contactMeta =
      const VerificationMeta('contact');
  @override
  late final GeneratedColumn<String> contact = GeneratedColumn<String>(
      'contact', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isRecurrenceEnabledMeta =
      const VerificationMeta('isRecurrenceEnabled');
  @override
  late final GeneratedColumn<bool> isRecurrenceEnabled = GeneratedColumn<bool>(
      'is_recurrence_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_recurrence_enabled" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _recurrenceTypeMeta =
      const VerificationMeta('recurrenceType');
  @override
  late final GeneratedColumn<String> recurrenceType = GeneratedColumn<String>(
      'recurrence_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _recurrenceEndsMeta =
      const VerificationMeta('recurrenceEnds');
  @override
  late final GeneratedColumn<String> recurrenceEnds = GeneratedColumn<String>(
      'recurrence_ends', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _exchangeRateAtCreationMeta =
      const VerificationMeta('exchangeRateAtCreation');
  @override
  late final GeneratedColumn<double> exchangeRateAtCreation =
      GeneratedColumn<double>('exchange_rate_at_creation', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _baseCurrencyAmountMeta =
      const VerificationMeta('baseCurrencyAmount');
  @override
  late final GeneratedColumn<double> baseCurrencyAmount =
      GeneratedColumn<double>('base_currency_amount', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        amount,
        categoryId,
        accountId,
        currencyCode,
        reference,
        contact,
        isRecurrenceEnabled,
        recurrenceType,
        recurrenceEnds,
        date,
        updatedAt,
        exchangeRateAtCreation,
        baseCurrencyAmount
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(Insertable<Transaction> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
          _currencyCodeMeta,
          currencyCode.isAcceptableOrUnknown(
              data['currency_code']!, _currencyCodeMeta));
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('reference')) {
      context.handle(_referenceMeta,
          reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta));
    }
    if (data.containsKey('contact')) {
      context.handle(_contactMeta,
          contact.isAcceptableOrUnknown(data['contact']!, _contactMeta));
    }
    if (data.containsKey('is_recurrence_enabled')) {
      context.handle(
          _isRecurrenceEnabledMeta,
          isRecurrenceEnabled.isAcceptableOrUnknown(
              data['is_recurrence_enabled']!, _isRecurrenceEnabledMeta));
    }
    if (data.containsKey('recurrence_type')) {
      context.handle(
          _recurrenceTypeMeta,
          recurrenceType.isAcceptableOrUnknown(
              data['recurrence_type']!, _recurrenceTypeMeta));
    }
    if (data.containsKey('recurrence_ends')) {
      context.handle(
          _recurrenceEndsMeta,
          recurrenceEnds.isAcceptableOrUnknown(
              data['recurrence_ends']!, _recurrenceEndsMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('exchange_rate_at_creation')) {
      context.handle(
          _exchangeRateAtCreationMeta,
          exchangeRateAtCreation.isAcceptableOrUnknown(
              data['exchange_rate_at_creation']!, _exchangeRateAtCreationMeta));
    }
    if (data.containsKey('base_currency_amount')) {
      context.handle(
          _baseCurrencyAmountMeta,
          baseCurrencyAmount.isAcceptableOrUnknown(
              data['base_currency_amount']!, _baseCurrencyAmountMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category_id']),
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}account_id'])!,
      currencyCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency_code'])!,
      reference: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reference']),
      contact: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}contact']),
      isRecurrenceEnabled: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}is_recurrence_enabled'])!,
      recurrenceType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recurrence_type']),
      recurrenceEnds: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recurrence_ends']),
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      exchangeRateAtCreation: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}exchange_rate_at_creation']),
      baseCurrencyAmount: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}base_currency_amount']),
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final int id;
  final double amount;
  final int? categoryId;
  final int accountId;
  final String currencyCode;
  final String? reference;
  final String? contact;
  final bool isRecurrenceEnabled;
  final String? recurrenceType;
  final String? recurrenceEnds;
  final DateTime date;
  final DateTime updatedAt;
  final double? exchangeRateAtCreation;
  final double? baseCurrencyAmount;
  const Transaction(
      {required this.id,
      required this.amount,
      this.categoryId,
      required this.accountId,
      required this.currencyCode,
      this.reference,
      this.contact,
      required this.isRecurrenceEnabled,
      this.recurrenceType,
      this.recurrenceEnds,
      required this.date,
      required this.updatedAt,
      this.exchangeRateAtCreation,
      this.baseCurrencyAmount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['amount'] = Variable<double>(amount);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    map['account_id'] = Variable<int>(accountId);
    map['currency_code'] = Variable<String>(currencyCode);
    if (!nullToAbsent || reference != null) {
      map['reference'] = Variable<String>(reference);
    }
    if (!nullToAbsent || contact != null) {
      map['contact'] = Variable<String>(contact);
    }
    map['is_recurrence_enabled'] = Variable<bool>(isRecurrenceEnabled);
    if (!nullToAbsent || recurrenceType != null) {
      map['recurrence_type'] = Variable<String>(recurrenceType);
    }
    if (!nullToAbsent || recurrenceEnds != null) {
      map['recurrence_ends'] = Variable<String>(recurrenceEnds);
    }
    map['date'] = Variable<DateTime>(date);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || exchangeRateAtCreation != null) {
      map['exchange_rate_at_creation'] =
          Variable<double>(exchangeRateAtCreation);
    }
    if (!nullToAbsent || baseCurrencyAmount != null) {
      map['base_currency_amount'] = Variable<double>(baseCurrencyAmount);
    }
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      amount: Value(amount),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      accountId: Value(accountId),
      currencyCode: Value(currencyCode),
      reference: reference == null && nullToAbsent
          ? const Value.absent()
          : Value(reference),
      contact: contact == null && nullToAbsent
          ? const Value.absent()
          : Value(contact),
      isRecurrenceEnabled: Value(isRecurrenceEnabled),
      recurrenceType: recurrenceType == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceType),
      recurrenceEnds: recurrenceEnds == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceEnds),
      date: Value(date),
      updatedAt: Value(updatedAt),
      exchangeRateAtCreation: exchangeRateAtCreation == null && nullToAbsent
          ? const Value.absent()
          : Value(exchangeRateAtCreation),
      baseCurrencyAmount: baseCurrencyAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(baseCurrencyAmount),
    );
  }

  factory Transaction.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      id: serializer.fromJson<int>(json['id']),
      amount: serializer.fromJson<double>(json['amount']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      accountId: serializer.fromJson<int>(json['accountId']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      reference: serializer.fromJson<String?>(json['reference']),
      contact: serializer.fromJson<String?>(json['contact']),
      isRecurrenceEnabled:
          serializer.fromJson<bool>(json['isRecurrenceEnabled']),
      recurrenceType: serializer.fromJson<String?>(json['recurrenceType']),
      recurrenceEnds: serializer.fromJson<String?>(json['recurrenceEnds']),
      date: serializer.fromJson<DateTime>(json['date']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      exchangeRateAtCreation:
          serializer.fromJson<double?>(json['exchangeRateAtCreation']),
      baseCurrencyAmount:
          serializer.fromJson<double?>(json['baseCurrencyAmount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'amount': serializer.toJson<double>(amount),
      'categoryId': serializer.toJson<int?>(categoryId),
      'accountId': serializer.toJson<int>(accountId),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'reference': serializer.toJson<String?>(reference),
      'contact': serializer.toJson<String?>(contact),
      'isRecurrenceEnabled': serializer.toJson<bool>(isRecurrenceEnabled),
      'recurrenceType': serializer.toJson<String?>(recurrenceType),
      'recurrenceEnds': serializer.toJson<String?>(recurrenceEnds),
      'date': serializer.toJson<DateTime>(date),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'exchangeRateAtCreation':
          serializer.toJson<double?>(exchangeRateAtCreation),
      'baseCurrencyAmount': serializer.toJson<double?>(baseCurrencyAmount),
    };
  }

  Transaction copyWith(
          {int? id,
          double? amount,
          Value<int?> categoryId = const Value.absent(),
          int? accountId,
          String? currencyCode,
          Value<String?> reference = const Value.absent(),
          Value<String?> contact = const Value.absent(),
          bool? isRecurrenceEnabled,
          Value<String?> recurrenceType = const Value.absent(),
          Value<String?> recurrenceEnds = const Value.absent(),
          DateTime? date,
          DateTime? updatedAt,
          Value<double?> exchangeRateAtCreation = const Value.absent(),
          Value<double?> baseCurrencyAmount = const Value.absent()}) =>
      Transaction(
        id: id ?? this.id,
        amount: amount ?? this.amount,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        accountId: accountId ?? this.accountId,
        currencyCode: currencyCode ?? this.currencyCode,
        reference: reference.present ? reference.value : this.reference,
        contact: contact.present ? contact.value : this.contact,
        isRecurrenceEnabled: isRecurrenceEnabled ?? this.isRecurrenceEnabled,
        recurrenceType:
            recurrenceType.present ? recurrenceType.value : this.recurrenceType,
        recurrenceEnds:
            recurrenceEnds.present ? recurrenceEnds.value : this.recurrenceEnds,
        date: date ?? this.date,
        updatedAt: updatedAt ?? this.updatedAt,
        exchangeRateAtCreation: exchangeRateAtCreation.present
            ? exchangeRateAtCreation.value
            : this.exchangeRateAtCreation,
        baseCurrencyAmount: baseCurrencyAmount.present
            ? baseCurrencyAmount.value
            : this.baseCurrencyAmount,
      );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      id: data.id.present ? data.id.value : this.id,
      amount: data.amount.present ? data.amount.value : this.amount,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      reference: data.reference.present ? data.reference.value : this.reference,
      contact: data.contact.present ? data.contact.value : this.contact,
      isRecurrenceEnabled: data.isRecurrenceEnabled.present
          ? data.isRecurrenceEnabled.value
          : this.isRecurrenceEnabled,
      recurrenceType: data.recurrenceType.present
          ? data.recurrenceType.value
          : this.recurrenceType,
      recurrenceEnds: data.recurrenceEnds.present
          ? data.recurrenceEnds.value
          : this.recurrenceEnds,
      date: data.date.present ? data.date.value : this.date,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      exchangeRateAtCreation: data.exchangeRateAtCreation.present
          ? data.exchangeRateAtCreation.value
          : this.exchangeRateAtCreation,
      baseCurrencyAmount: data.baseCurrencyAmount.present
          ? data.baseCurrencyAmount.value
          : this.baseCurrencyAmount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('id: $id, ')
          ..write('amount: $amount, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('reference: $reference, ')
          ..write('contact: $contact, ')
          ..write('isRecurrenceEnabled: $isRecurrenceEnabled, ')
          ..write('recurrenceType: $recurrenceType, ')
          ..write('recurrenceEnds: $recurrenceEnds, ')
          ..write('date: $date, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('exchangeRateAtCreation: $exchangeRateAtCreation, ')
          ..write('baseCurrencyAmount: $baseCurrencyAmount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      amount,
      categoryId,
      accountId,
      currencyCode,
      reference,
      contact,
      isRecurrenceEnabled,
      recurrenceType,
      recurrenceEnds,
      date,
      updatedAt,
      exchangeRateAtCreation,
      baseCurrencyAmount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.amount == this.amount &&
          other.categoryId == this.categoryId &&
          other.accountId == this.accountId &&
          other.currencyCode == this.currencyCode &&
          other.reference == this.reference &&
          other.contact == this.contact &&
          other.isRecurrenceEnabled == this.isRecurrenceEnabled &&
          other.recurrenceType == this.recurrenceType &&
          other.recurrenceEnds == this.recurrenceEnds &&
          other.date == this.date &&
          other.updatedAt == this.updatedAt &&
          other.exchangeRateAtCreation == this.exchangeRateAtCreation &&
          other.baseCurrencyAmount == this.baseCurrencyAmount);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<int> id;
  final Value<double> amount;
  final Value<int?> categoryId;
  final Value<int> accountId;
  final Value<String> currencyCode;
  final Value<String?> reference;
  final Value<String?> contact;
  final Value<bool> isRecurrenceEnabled;
  final Value<String?> recurrenceType;
  final Value<String?> recurrenceEnds;
  final Value<DateTime> date;
  final Value<DateTime> updatedAt;
  final Value<double?> exchangeRateAtCreation;
  final Value<double?> baseCurrencyAmount;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.amount = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.reference = const Value.absent(),
    this.contact = const Value.absent(),
    this.isRecurrenceEnabled = const Value.absent(),
    this.recurrenceType = const Value.absent(),
    this.recurrenceEnds = const Value.absent(),
    this.date = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.exchangeRateAtCreation = const Value.absent(),
    this.baseCurrencyAmount = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.id = const Value.absent(),
    required double amount,
    this.categoryId = const Value.absent(),
    required int accountId,
    required String currencyCode,
    this.reference = const Value.absent(),
    this.contact = const Value.absent(),
    this.isRecurrenceEnabled = const Value.absent(),
    this.recurrenceType = const Value.absent(),
    this.recurrenceEnds = const Value.absent(),
    required DateTime date,
    this.updatedAt = const Value.absent(),
    this.exchangeRateAtCreation = const Value.absent(),
    this.baseCurrencyAmount = const Value.absent(),
  })  : amount = Value(amount),
        accountId = Value(accountId),
        currencyCode = Value(currencyCode),
        date = Value(date);
  static Insertable<Transaction> custom({
    Expression<int>? id,
    Expression<double>? amount,
    Expression<int>? categoryId,
    Expression<int>? accountId,
    Expression<String>? currencyCode,
    Expression<String>? reference,
    Expression<String>? contact,
    Expression<bool>? isRecurrenceEnabled,
    Expression<String>? recurrenceType,
    Expression<String>? recurrenceEnds,
    Expression<DateTime>? date,
    Expression<DateTime>? updatedAt,
    Expression<double>? exchangeRateAtCreation,
    Expression<double>? baseCurrencyAmount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (amount != null) 'amount': amount,
      if (categoryId != null) 'category_id': categoryId,
      if (accountId != null) 'account_id': accountId,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (reference != null) 'reference': reference,
      if (contact != null) 'contact': contact,
      if (isRecurrenceEnabled != null)
        'is_recurrence_enabled': isRecurrenceEnabled,
      if (recurrenceType != null) 'recurrence_type': recurrenceType,
      if (recurrenceEnds != null) 'recurrence_ends': recurrenceEnds,
      if (date != null) 'date': date,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (exchangeRateAtCreation != null)
        'exchange_rate_at_creation': exchangeRateAtCreation,
      if (baseCurrencyAmount != null)
        'base_currency_amount': baseCurrencyAmount,
    });
  }

  TransactionsCompanion copyWith(
      {Value<int>? id,
      Value<double>? amount,
      Value<int?>? categoryId,
      Value<int>? accountId,
      Value<String>? currencyCode,
      Value<String?>? reference,
      Value<String?>? contact,
      Value<bool>? isRecurrenceEnabled,
      Value<String?>? recurrenceType,
      Value<String?>? recurrenceEnds,
      Value<DateTime>? date,
      Value<DateTime>? updatedAt,
      Value<double?>? exchangeRateAtCreation,
      Value<double?>? baseCurrencyAmount}) {
    return TransactionsCompanion(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      currencyCode: currencyCode ?? this.currencyCode,
      reference: reference ?? this.reference,
      contact: contact ?? this.contact,
      isRecurrenceEnabled: isRecurrenceEnabled ?? this.isRecurrenceEnabled,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceEnds: recurrenceEnds ?? this.recurrenceEnds,
      date: date ?? this.date,
      updatedAt: updatedAt ?? this.updatedAt,
      exchangeRateAtCreation:
          exchangeRateAtCreation ?? this.exchangeRateAtCreation,
      baseCurrencyAmount: baseCurrencyAmount ?? this.baseCurrencyAmount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (contact.present) {
      map['contact'] = Variable<String>(contact.value);
    }
    if (isRecurrenceEnabled.present) {
      map['is_recurrence_enabled'] = Variable<bool>(isRecurrenceEnabled.value);
    }
    if (recurrenceType.present) {
      map['recurrence_type'] = Variable<String>(recurrenceType.value);
    }
    if (recurrenceEnds.present) {
      map['recurrence_ends'] = Variable<String>(recurrenceEnds.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (exchangeRateAtCreation.present) {
      map['exchange_rate_at_creation'] =
          Variable<double>(exchangeRateAtCreation.value);
    }
    if (baseCurrencyAmount.present) {
      map['base_currency_amount'] = Variable<double>(baseCurrencyAmount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('amount: $amount, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('reference: $reference, ')
          ..write('contact: $contact, ')
          ..write('isRecurrenceEnabled: $isRecurrenceEnabled, ')
          ..write('recurrenceType: $recurrenceType, ')
          ..write('recurrenceEnds: $recurrenceEnds, ')
          ..write('date: $date, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('exchangeRateAtCreation: $exchangeRateAtCreation, ')
          ..write('baseCurrencyAmount: $baseCurrencyAmount')
          ..write(')'))
        .toString();
  }
}

class $UserSettingsTable extends UserSettings
    with TableInfo<$UserSettingsTable, UserSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _baseCurrencyCodeMeta =
      const VerificationMeta('baseCurrencyCode');
  @override
  late final GeneratedColumn<String> baseCurrencyCode = GeneratedColumn<String>(
      'base_currency_code', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES currencies (code)'));
  static const VerificationMeta _usernameMeta =
      const VerificationMeta('username');
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
      'username', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('User'));
  static const VerificationMeta _profilePicturePathMeta =
      const VerificationMeta('profilePicturePath');
  @override
  late final GeneratedColumn<String> profilePicturePath =
      GeneratedColumn<String>('profile_picture_path', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _currencySelectionModeMeta =
      const VerificationMeta('currencySelectionMode');
  @override
  late final GeneratedColumn<String> currencySelectionMode =
      GeneratedColumn<String>('currency_selection_mode', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('auto'));
  static const VerificationMeta _lastAutoFetchDateMeta =
      const VerificationMeta('lastAutoFetchDate');
  @override
  late final GeneratedColumn<DateTime> lastAutoFetchDate =
      GeneratedColumn<DateTime>('last_auto_fetch_date', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        baseCurrencyCode,
        username,
        profilePicturePath,
        currencySelectionMode,
        lastAutoFetchDate
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_settings';
  @override
  VerificationContext validateIntegrity(Insertable<UserSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('base_currency_code')) {
      context.handle(
          _baseCurrencyCodeMeta,
          baseCurrencyCode.isAcceptableOrUnknown(
              data['base_currency_code']!, _baseCurrencyCodeMeta));
    } else if (isInserting) {
      context.missing(_baseCurrencyCodeMeta);
    }
    if (data.containsKey('username')) {
      context.handle(_usernameMeta,
          username.isAcceptableOrUnknown(data['username']!, _usernameMeta));
    }
    if (data.containsKey('profile_picture_path')) {
      context.handle(
          _profilePicturePathMeta,
          profilePicturePath.isAcceptableOrUnknown(
              data['profile_picture_path']!, _profilePicturePathMeta));
    }
    if (data.containsKey('currency_selection_mode')) {
      context.handle(
          _currencySelectionModeMeta,
          currencySelectionMode.isAcceptableOrUnknown(
              data['currency_selection_mode']!, _currencySelectionModeMeta));
    }
    if (data.containsKey('last_auto_fetch_date')) {
      context.handle(
          _lastAutoFetchDateMeta,
          lastAutoFetchDate.isAcceptableOrUnknown(
              data['last_auto_fetch_date']!, _lastAutoFetchDateMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserSetting(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      baseCurrencyCode: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}base_currency_code'])!,
      username: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}username'])!,
      profilePicturePath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}profile_picture_path']),
      currencySelectionMode: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}currency_selection_mode'])!,
      lastAutoFetchDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}last_auto_fetch_date']),
    );
  }

  @override
  $UserSettingsTable createAlias(String alias) {
    return $UserSettingsTable(attachedDatabase, alias);
  }
}

class UserSetting extends DataClass implements Insertable<UserSetting> {
  final int id;
  final String baseCurrencyCode;
  final String username;
  final String? profilePicturePath;
  final String currencySelectionMode;
  final DateTime? lastAutoFetchDate;
  const UserSetting(
      {required this.id,
      required this.baseCurrencyCode,
      required this.username,
      this.profilePicturePath,
      required this.currencySelectionMode,
      this.lastAutoFetchDate});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['base_currency_code'] = Variable<String>(baseCurrencyCode);
    map['username'] = Variable<String>(username);
    if (!nullToAbsent || profilePicturePath != null) {
      map['profile_picture_path'] = Variable<String>(profilePicturePath);
    }
    map['currency_selection_mode'] = Variable<String>(currencySelectionMode);
    if (!nullToAbsent || lastAutoFetchDate != null) {
      map['last_auto_fetch_date'] = Variable<DateTime>(lastAutoFetchDate);
    }
    return map;
  }

  UserSettingsCompanion toCompanion(bool nullToAbsent) {
    return UserSettingsCompanion(
      id: Value(id),
      baseCurrencyCode: Value(baseCurrencyCode),
      username: Value(username),
      profilePicturePath: profilePicturePath == null && nullToAbsent
          ? const Value.absent()
          : Value(profilePicturePath),
      currencySelectionMode: Value(currencySelectionMode),
      lastAutoFetchDate: lastAutoFetchDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAutoFetchDate),
    );
  }

  factory UserSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserSetting(
      id: serializer.fromJson<int>(json['id']),
      baseCurrencyCode: serializer.fromJson<String>(json['baseCurrencyCode']),
      username: serializer.fromJson<String>(json['username']),
      profilePicturePath:
          serializer.fromJson<String?>(json['profilePicturePath']),
      currencySelectionMode:
          serializer.fromJson<String>(json['currencySelectionMode']),
      lastAutoFetchDate:
          serializer.fromJson<DateTime?>(json['lastAutoFetchDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'baseCurrencyCode': serializer.toJson<String>(baseCurrencyCode),
      'username': serializer.toJson<String>(username),
      'profilePicturePath': serializer.toJson<String?>(profilePicturePath),
      'currencySelectionMode': serializer.toJson<String>(currencySelectionMode),
      'lastAutoFetchDate': serializer.toJson<DateTime?>(lastAutoFetchDate),
    };
  }

  UserSetting copyWith(
          {int? id,
          String? baseCurrencyCode,
          String? username,
          Value<String?> profilePicturePath = const Value.absent(),
          String? currencySelectionMode,
          Value<DateTime?> lastAutoFetchDate = const Value.absent()}) =>
      UserSetting(
        id: id ?? this.id,
        baseCurrencyCode: baseCurrencyCode ?? this.baseCurrencyCode,
        username: username ?? this.username,
        profilePicturePath: profilePicturePath.present
            ? profilePicturePath.value
            : this.profilePicturePath,
        currencySelectionMode:
            currencySelectionMode ?? this.currencySelectionMode,
        lastAutoFetchDate: lastAutoFetchDate.present
            ? lastAutoFetchDate.value
            : this.lastAutoFetchDate,
      );
  UserSetting copyWithCompanion(UserSettingsCompanion data) {
    return UserSetting(
      id: data.id.present ? data.id.value : this.id,
      baseCurrencyCode: data.baseCurrencyCode.present
          ? data.baseCurrencyCode.value
          : this.baseCurrencyCode,
      username: data.username.present ? data.username.value : this.username,
      profilePicturePath: data.profilePicturePath.present
          ? data.profilePicturePath.value
          : this.profilePicturePath,
      currencySelectionMode: data.currencySelectionMode.present
          ? data.currencySelectionMode.value
          : this.currencySelectionMode,
      lastAutoFetchDate: data.lastAutoFetchDate.present
          ? data.lastAutoFetchDate.value
          : this.lastAutoFetchDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserSetting(')
          ..write('id: $id, ')
          ..write('baseCurrencyCode: $baseCurrencyCode, ')
          ..write('username: $username, ')
          ..write('profilePicturePath: $profilePicturePath, ')
          ..write('currencySelectionMode: $currencySelectionMode, ')
          ..write('lastAutoFetchDate: $lastAutoFetchDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, baseCurrencyCode, username,
      profilePicturePath, currencySelectionMode, lastAutoFetchDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserSetting &&
          other.id == this.id &&
          other.baseCurrencyCode == this.baseCurrencyCode &&
          other.username == this.username &&
          other.profilePicturePath == this.profilePicturePath &&
          other.currencySelectionMode == this.currencySelectionMode &&
          other.lastAutoFetchDate == this.lastAutoFetchDate);
}

class UserSettingsCompanion extends UpdateCompanion<UserSetting> {
  final Value<int> id;
  final Value<String> baseCurrencyCode;
  final Value<String> username;
  final Value<String?> profilePicturePath;
  final Value<String> currencySelectionMode;
  final Value<DateTime?> lastAutoFetchDate;
  const UserSettingsCompanion({
    this.id = const Value.absent(),
    this.baseCurrencyCode = const Value.absent(),
    this.username = const Value.absent(),
    this.profilePicturePath = const Value.absent(),
    this.currencySelectionMode = const Value.absent(),
    this.lastAutoFetchDate = const Value.absent(),
  });
  UserSettingsCompanion.insert({
    this.id = const Value.absent(),
    required String baseCurrencyCode,
    this.username = const Value.absent(),
    this.profilePicturePath = const Value.absent(),
    this.currencySelectionMode = const Value.absent(),
    this.lastAutoFetchDate = const Value.absent(),
  }) : baseCurrencyCode = Value(baseCurrencyCode);
  static Insertable<UserSetting> custom({
    Expression<int>? id,
    Expression<String>? baseCurrencyCode,
    Expression<String>? username,
    Expression<String>? profilePicturePath,
    Expression<String>? currencySelectionMode,
    Expression<DateTime>? lastAutoFetchDate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (baseCurrencyCode != null) 'base_currency_code': baseCurrencyCode,
      if (username != null) 'username': username,
      if (profilePicturePath != null)
        'profile_picture_path': profilePicturePath,
      if (currencySelectionMode != null)
        'currency_selection_mode': currencySelectionMode,
      if (lastAutoFetchDate != null) 'last_auto_fetch_date': lastAutoFetchDate,
    });
  }

  UserSettingsCompanion copyWith(
      {Value<int>? id,
      Value<String>? baseCurrencyCode,
      Value<String>? username,
      Value<String?>? profilePicturePath,
      Value<String>? currencySelectionMode,
      Value<DateTime?>? lastAutoFetchDate}) {
    return UserSettingsCompanion(
      id: id ?? this.id,
      baseCurrencyCode: baseCurrencyCode ?? this.baseCurrencyCode,
      username: username ?? this.username,
      profilePicturePath: profilePicturePath ?? this.profilePicturePath,
      currencySelectionMode:
          currencySelectionMode ?? this.currencySelectionMode,
      lastAutoFetchDate: lastAutoFetchDate ?? this.lastAutoFetchDate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (baseCurrencyCode.present) {
      map['base_currency_code'] = Variable<String>(baseCurrencyCode.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (profilePicturePath.present) {
      map['profile_picture_path'] = Variable<String>(profilePicturePath.value);
    }
    if (currencySelectionMode.present) {
      map['currency_selection_mode'] =
          Variable<String>(currencySelectionMode.value);
    }
    if (lastAutoFetchDate.present) {
      map['last_auto_fetch_date'] = Variable<DateTime>(lastAutoFetchDate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserSettingsCompanion(')
          ..write('id: $id, ')
          ..write('baseCurrencyCode: $baseCurrencyCode, ')
          ..write('username: $username, ')
          ..write('profilePicturePath: $profilePicturePath, ')
          ..write('currencySelectionMode: $currencySelectionMode, ')
          ..write('lastAutoFetchDate: $lastAutoFetchDate')
          ..write(')'))
        .toString();
  }
}

class $ExchangeRateSnapshotsTable extends ExchangeRateSnapshots
    with TableInfo<$ExchangeRateSnapshotsTable, ExchangeRateSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExchangeRateSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _ratesJsonMeta =
      const VerificationMeta('ratesJson');
  @override
  late final GeneratedColumn<String> ratesJson = GeneratedColumn<String>(
      'rates_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, date, ratesJson, source, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exchange_rate_snapshots';
  @override
  VerificationContext validateIntegrity(
      Insertable<ExchangeRateSnapshot> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('rates_json')) {
      context.handle(_ratesJsonMeta,
          ratesJson.isAcceptableOrUnknown(data['rates_json']!, _ratesJsonMeta));
    } else if (isInserting) {
      context.missing(_ratesJsonMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExchangeRateSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExchangeRateSnapshot(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      ratesJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rates_json'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ExchangeRateSnapshotsTable createAlias(String alias) {
    return $ExchangeRateSnapshotsTable(attachedDatabase, alias);
  }
}

class ExchangeRateSnapshot extends DataClass
    implements Insertable<ExchangeRateSnapshot> {
  final int id;
  final DateTime date;
  final String ratesJson;
  final String source;
  final DateTime createdAt;
  const ExchangeRateSnapshot(
      {required this.id,
      required this.date,
      required this.ratesJson,
      required this.source,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['rates_json'] = Variable<String>(ratesJson);
    map['source'] = Variable<String>(source);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ExchangeRateSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return ExchangeRateSnapshotsCompanion(
      id: Value(id),
      date: Value(date),
      ratesJson: Value(ratesJson),
      source: Value(source),
      createdAt: Value(createdAt),
    );
  }

  factory ExchangeRateSnapshot.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExchangeRateSnapshot(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      ratesJson: serializer.fromJson<String>(json['ratesJson']),
      source: serializer.fromJson<String>(json['source']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'ratesJson': serializer.toJson<String>(ratesJson),
      'source': serializer.toJson<String>(source),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ExchangeRateSnapshot copyWith(
          {int? id,
          DateTime? date,
          String? ratesJson,
          String? source,
          DateTime? createdAt}) =>
      ExchangeRateSnapshot(
        id: id ?? this.id,
        date: date ?? this.date,
        ratesJson: ratesJson ?? this.ratesJson,
        source: source ?? this.source,
        createdAt: createdAt ?? this.createdAt,
      );
  ExchangeRateSnapshot copyWithCompanion(ExchangeRateSnapshotsCompanion data) {
    return ExchangeRateSnapshot(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      ratesJson: data.ratesJson.present ? data.ratesJson.value : this.ratesJson,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExchangeRateSnapshot(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('ratesJson: $ratesJson, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, ratesJson, source, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExchangeRateSnapshot &&
          other.id == this.id &&
          other.date == this.date &&
          other.ratesJson == this.ratesJson &&
          other.source == this.source &&
          other.createdAt == this.createdAt);
}

class ExchangeRateSnapshotsCompanion
    extends UpdateCompanion<ExchangeRateSnapshot> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<String> ratesJson;
  final Value<String> source;
  final Value<DateTime> createdAt;
  const ExchangeRateSnapshotsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.ratesJson = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ExchangeRateSnapshotsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required String ratesJson,
    required String source,
    this.createdAt = const Value.absent(),
  })  : date = Value(date),
        ratesJson = Value(ratesJson),
        source = Value(source);
  static Insertable<ExchangeRateSnapshot> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<String>? ratesJson,
    Expression<String>? source,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (ratesJson != null) 'rates_json': ratesJson,
      if (source != null) 'source': source,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ExchangeRateSnapshotsCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? date,
      Value<String>? ratesJson,
      Value<String>? source,
      Value<DateTime>? createdAt}) {
    return ExchangeRateSnapshotsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      ratesJson: ratesJson ?? this.ratesJson,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (ratesJson.present) {
      map['rates_json'] = Variable<String>(ratesJson.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExchangeRateSnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('ratesJson: $ratesJson, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $NetWorthHistoryTable extends NetWorthHistory
    with TableInfo<$NetWorthHistoryTable, NetWorthHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NetWorthHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _totalInBaseCurrencyMeta =
      const VerificationMeta('totalInBaseCurrency');
  @override
  late final GeneratedColumn<double> totalInBaseCurrency =
      GeneratedColumn<double>('total_in_base_currency', aliasedName, false,
          type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _totalInNationalCurrencyMeta =
      const VerificationMeta('totalInNationalCurrency');
  @override
  late final GeneratedColumn<double> totalInNationalCurrency =
      GeneratedColumn<double>('total_in_national_currency', aliasedName, false,
          type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, date, totalInBaseCurrency, totalInNationalCurrency, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'net_worth_history';
  @override
  VerificationContext validateIntegrity(
      Insertable<NetWorthHistoryData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('total_in_base_currency')) {
      context.handle(
          _totalInBaseCurrencyMeta,
          totalInBaseCurrency.isAcceptableOrUnknown(
              data['total_in_base_currency']!, _totalInBaseCurrencyMeta));
    } else if (isInserting) {
      context.missing(_totalInBaseCurrencyMeta);
    }
    if (data.containsKey('total_in_national_currency')) {
      context.handle(
          _totalInNationalCurrencyMeta,
          totalInNationalCurrency.isAcceptableOrUnknown(
              data['total_in_national_currency']!,
              _totalInNationalCurrencyMeta));
    } else if (isInserting) {
      context.missing(_totalInNationalCurrencyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NetWorthHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NetWorthHistoryData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      totalInBaseCurrency: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}total_in_base_currency'])!,
      totalInNationalCurrency: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}total_in_national_currency'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $NetWorthHistoryTable createAlias(String alias) {
    return $NetWorthHistoryTable(attachedDatabase, alias);
  }
}

class NetWorthHistoryData extends DataClass
    implements Insertable<NetWorthHistoryData> {
  final int id;
  final DateTime date;
  final double totalInBaseCurrency;
  final double totalInNationalCurrency;
  final DateTime createdAt;
  const NetWorthHistoryData(
      {required this.id,
      required this.date,
      required this.totalInBaseCurrency,
      required this.totalInNationalCurrency,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['total_in_base_currency'] = Variable<double>(totalInBaseCurrency);
    map['total_in_national_currency'] =
        Variable<double>(totalInNationalCurrency);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  NetWorthHistoryCompanion toCompanion(bool nullToAbsent) {
    return NetWorthHistoryCompanion(
      id: Value(id),
      date: Value(date),
      totalInBaseCurrency: Value(totalInBaseCurrency),
      totalInNationalCurrency: Value(totalInNationalCurrency),
      createdAt: Value(createdAt),
    );
  }

  factory NetWorthHistoryData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NetWorthHistoryData(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      totalInBaseCurrency:
          serializer.fromJson<double>(json['totalInBaseCurrency']),
      totalInNationalCurrency:
          serializer.fromJson<double>(json['totalInNationalCurrency']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'totalInBaseCurrency': serializer.toJson<double>(totalInBaseCurrency),
      'totalInNationalCurrency':
          serializer.toJson<double>(totalInNationalCurrency),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  NetWorthHistoryData copyWith(
          {int? id,
          DateTime? date,
          double? totalInBaseCurrency,
          double? totalInNationalCurrency,
          DateTime? createdAt}) =>
      NetWorthHistoryData(
        id: id ?? this.id,
        date: date ?? this.date,
        totalInBaseCurrency: totalInBaseCurrency ?? this.totalInBaseCurrency,
        totalInNationalCurrency:
            totalInNationalCurrency ?? this.totalInNationalCurrency,
        createdAt: createdAt ?? this.createdAt,
      );
  NetWorthHistoryData copyWithCompanion(NetWorthHistoryCompanion data) {
    return NetWorthHistoryData(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      totalInBaseCurrency: data.totalInBaseCurrency.present
          ? data.totalInBaseCurrency.value
          : this.totalInBaseCurrency,
      totalInNationalCurrency: data.totalInNationalCurrency.present
          ? data.totalInNationalCurrency.value
          : this.totalInNationalCurrency,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NetWorthHistoryData(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('totalInBaseCurrency: $totalInBaseCurrency, ')
          ..write('totalInNationalCurrency: $totalInNationalCurrency, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, date, totalInBaseCurrency, totalInNationalCurrency, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NetWorthHistoryData &&
          other.id == this.id &&
          other.date == this.date &&
          other.totalInBaseCurrency == this.totalInBaseCurrency &&
          other.totalInNationalCurrency == this.totalInNationalCurrency &&
          other.createdAt == this.createdAt);
}

class NetWorthHistoryCompanion extends UpdateCompanion<NetWorthHistoryData> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<double> totalInBaseCurrency;
  final Value<double> totalInNationalCurrency;
  final Value<DateTime> createdAt;
  const NetWorthHistoryCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.totalInBaseCurrency = const Value.absent(),
    this.totalInNationalCurrency = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  NetWorthHistoryCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required double totalInBaseCurrency,
    required double totalInNationalCurrency,
    this.createdAt = const Value.absent(),
  })  : date = Value(date),
        totalInBaseCurrency = Value(totalInBaseCurrency),
        totalInNationalCurrency = Value(totalInNationalCurrency);
  static Insertable<NetWorthHistoryData> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<double>? totalInBaseCurrency,
    Expression<double>? totalInNationalCurrency,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (totalInBaseCurrency != null)
        'total_in_base_currency': totalInBaseCurrency,
      if (totalInNationalCurrency != null)
        'total_in_national_currency': totalInNationalCurrency,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  NetWorthHistoryCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? date,
      Value<double>? totalInBaseCurrency,
      Value<double>? totalInNationalCurrency,
      Value<DateTime>? createdAt}) {
    return NetWorthHistoryCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      totalInBaseCurrency: totalInBaseCurrency ?? this.totalInBaseCurrency,
      totalInNationalCurrency:
          totalInNationalCurrency ?? this.totalInNationalCurrency,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (totalInBaseCurrency.present) {
      map['total_in_base_currency'] =
          Variable<double>(totalInBaseCurrency.value);
    }
    if (totalInNationalCurrency.present) {
      map['total_in_national_currency'] =
          Variable<double>(totalInNationalCurrency.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NetWorthHistoryCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('totalInBaseCurrency: $totalInBaseCurrency, ')
          ..write('totalInNationalCurrency: $totalInNationalCurrency, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CurrenciesTable currencies = $CurrenciesTable(this);
  late final $CurrencyRatesTable currencyRates = $CurrencyRatesTable(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $UserSettingsTable userSettings = $UserSettingsTable(this);
  late final $ExchangeRateSnapshotsTable exchangeRateSnapshots =
      $ExchangeRateSnapshotsTable(this);
  late final $NetWorthHistoryTable netWorthHistory =
      $NetWorthHistoryTable(this);
  late final AccountDao accountDao = AccountDao(this as AppDatabase);
  late final TransactionDao transactionDao =
      TransactionDao(this as AppDatabase);
  late final CurrencyDao currencyDao = CurrencyDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        currencies,
        currencyRates,
        accounts,
        categories,
        transactions,
        userSettings,
        exchangeRateSnapshots,
        netWorthHistory
      ];
}

typedef $$CurrenciesTableCreateCompanionBuilder = CurrenciesCompanion Function({
  required String code,
  required String name,
  required String symbol,
  Value<String> separator,
  Value<int> decimalDigits,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$CurrenciesTableUpdateCompanionBuilder = CurrenciesCompanion Function({
  Value<String> code,
  Value<String> name,
  Value<String> symbol,
  Value<String> separator,
  Value<int> decimalDigits,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$CurrenciesTableReferences
    extends BaseReferences<_$AppDatabase, $CurrenciesTable, Currency> {
  $$CurrenciesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CurrencyRatesTable, List<ExchangeRate>>
      _currencyRatesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.currencyRates,
              aliasName: $_aliasNameGenerator(
                  db.currencies.code, db.currencyRates.currencyCode));

  $$CurrencyRatesTableProcessedTableManager get currencyRatesRefs {
    final manager = $$CurrencyRatesTableTableManager($_db, $_db.currencyRates)
        .filter((f) =>
            f.currencyCode.code.sqlEquals($_itemColumn<String>('code')!));

    final cache = $_typedResult.readTableOrNull(_currencyRatesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$AccountsTable, List<Account>> _accountsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.accounts,
          aliasName: $_aliasNameGenerator(
              db.currencies.code, db.accounts.currencyCode));

  $$AccountsTableProcessedTableManager get accountsRefs {
    final manager = $$AccountsTableTableManager($_db, $_db.accounts).filter(
        (f) => f.currencyCode.code.sqlEquals($_itemColumn<String>('code')!));

    final cache = $_typedResult.readTableOrNull(_accountsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
      _transactionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.transactions,
              aliasName: $_aliasNameGenerator(
                  db.currencies.code, db.transactions.currencyCode));

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter((f) =>
            f.currencyCode.code.sqlEquals($_itemColumn<String>('code')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$UserSettingsTable, List<UserSetting>>
      _userSettingsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.userSettings,
              aliasName: $_aliasNameGenerator(
                  db.currencies.code, db.userSettings.baseCurrencyCode));

  $$UserSettingsTableProcessedTableManager get userSettingsRefs {
    final manager = $$UserSettingsTableTableManager($_db, $_db.userSettings)
        .filter((f) =>
            f.baseCurrencyCode.code.sqlEquals($_itemColumn<String>('code')!));

    final cache = $_typedResult.readTableOrNull(_userSettingsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CurrenciesTableFilterComposer
    extends Composer<_$AppDatabase, $CurrenciesTable> {
  $$CurrenciesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get symbol => $composableBuilder(
      column: $table.symbol, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get separator => $composableBuilder(
      column: $table.separator, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get decimalDigits => $composableBuilder(
      column: $table.decimalDigits, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> currencyRatesRefs(
      Expression<bool> Function($$CurrencyRatesTableFilterComposer f) f) {
    final $$CurrencyRatesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.code,
        referencedTable: $db.currencyRates,
        getReferencedColumn: (t) => t.currencyCode,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CurrencyRatesTableFilterComposer(
              $db: $db,
              $table: $db.currencyRates,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> accountsRefs(
      Expression<bool> Function($$AccountsTableFilterComposer f) f) {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.code,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.currencyCode,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> transactionsRefs(
      Expression<bool> Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.code,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.currencyCode,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableFilterComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> userSettingsRefs(
      Expression<bool> Function($$UserSettingsTableFilterComposer f) f) {
    final $$UserSettingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.code,
        referencedTable: $db.userSettings,
        getReferencedColumn: (t) => t.baseCurrencyCode,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UserSettingsTableFilterComposer(
              $db: $db,
              $table: $db.userSettings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CurrenciesTableOrderingComposer
    extends Composer<_$AppDatabase, $CurrenciesTable> {
  $$CurrenciesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get symbol => $composableBuilder(
      column: $table.symbol, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get separator => $composableBuilder(
      column: $table.separator, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get decimalDigits => $composableBuilder(
      column: $table.decimalDigits,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$CurrenciesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CurrenciesTable> {
  $$CurrenciesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get symbol =>
      $composableBuilder(column: $table.symbol, builder: (column) => column);

  GeneratedColumn<String> get separator =>
      $composableBuilder(column: $table.separator, builder: (column) => column);

  GeneratedColumn<int> get decimalDigits => $composableBuilder(
      column: $table.decimalDigits, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> currencyRatesRefs<T extends Object>(
      Expression<T> Function($$CurrencyRatesTableAnnotationComposer a) f) {
    final $$CurrencyRatesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.code,
        referencedTable: $db.currencyRates,
        getReferencedColumn: (t) => t.currencyCode,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CurrencyRatesTableAnnotationComposer(
              $db: $db,
              $table: $db.currencyRates,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> accountsRefs<T extends Object>(
      Expression<T> Function($$AccountsTableAnnotationComposer a) f) {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.code,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.currencyCode,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> transactionsRefs<T extends Object>(
      Expression<T> Function($$TransactionsTableAnnotationComposer a) f) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.code,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.currencyCode,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableAnnotationComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> userSettingsRefs<T extends Object>(
      Expression<T> Function($$UserSettingsTableAnnotationComposer a) f) {
    final $$UserSettingsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.code,
        referencedTable: $db.userSettings,
        getReferencedColumn: (t) => t.baseCurrencyCode,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UserSettingsTableAnnotationComposer(
              $db: $db,
              $table: $db.userSettings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CurrenciesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CurrenciesTable,
    Currency,
    $$CurrenciesTableFilterComposer,
    $$CurrenciesTableOrderingComposer,
    $$CurrenciesTableAnnotationComposer,
    $$CurrenciesTableCreateCompanionBuilder,
    $$CurrenciesTableUpdateCompanionBuilder,
    (Currency, $$CurrenciesTableReferences),
    Currency,
    PrefetchHooks Function(
        {bool currencyRatesRefs,
        bool accountsRefs,
        bool transactionsRefs,
        bool userSettingsRefs})> {
  $$CurrenciesTableTableManager(_$AppDatabase db, $CurrenciesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CurrenciesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CurrenciesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CurrenciesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> code = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> symbol = const Value.absent(),
            Value<String> separator = const Value.absent(),
            Value<int> decimalDigits = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CurrenciesCompanion(
            code: code,
            name: name,
            symbol: symbol,
            separator: separator,
            decimalDigits: decimalDigits,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String code,
            required String name,
            required String symbol,
            Value<String> separator = const Value.absent(),
            Value<int> decimalDigits = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CurrenciesCompanion.insert(
            code: code,
            name: name,
            symbol: symbol,
            separator: separator,
            decimalDigits: decimalDigits,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CurrenciesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {currencyRatesRefs = false,
              accountsRefs = false,
              transactionsRefs = false,
              userSettingsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (currencyRatesRefs) db.currencyRates,
                if (accountsRefs) db.accounts,
                if (transactionsRefs) db.transactions,
                if (userSettingsRefs) db.userSettings
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (currencyRatesRefs)
                    await $_getPrefetchedData<Currency, $CurrenciesTable,
                            ExchangeRate>(
                        currentTable: table,
                        referencedTable: $$CurrenciesTableReferences
                            ._currencyRatesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CurrenciesTableReferences(db, table, p0)
                                .currencyRatesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.currencyCode == item.code),
                        typedResults: items),
                  if (accountsRefs)
                    await $_getPrefetchedData<Currency, $CurrenciesTable,
                            Account>(
                        currentTable: table,
                        referencedTable:
                            $$CurrenciesTableReferences._accountsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CurrenciesTableReferences(db, table, p0)
                                .accountsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.currencyCode == item.code),
                        typedResults: items),
                  if (transactionsRefs)
                    await $_getPrefetchedData<Currency, $CurrenciesTable,
                            Transaction>(
                        currentTable: table,
                        referencedTable: $$CurrenciesTableReferences
                            ._transactionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CurrenciesTableReferences(db, table, p0)
                                .transactionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.currencyCode == item.code),
                        typedResults: items),
                  if (userSettingsRefs)
                    await $_getPrefetchedData<Currency, $CurrenciesTable,
                            UserSetting>(
                        currentTable: table,
                        referencedTable: $$CurrenciesTableReferences
                            ._userSettingsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CurrenciesTableReferences(db, table, p0)
                                .userSettingsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.baseCurrencyCode == item.code),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CurrenciesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CurrenciesTable,
    Currency,
    $$CurrenciesTableFilterComposer,
    $$CurrenciesTableOrderingComposer,
    $$CurrenciesTableAnnotationComposer,
    $$CurrenciesTableCreateCompanionBuilder,
    $$CurrenciesTableUpdateCompanionBuilder,
    (Currency, $$CurrenciesTableReferences),
    Currency,
    PrefetchHooks Function(
        {bool currencyRatesRefs,
        bool accountsRefs,
        bool transactionsRefs,
        bool userSettingsRefs})>;
typedef $$CurrencyRatesTableCreateCompanionBuilder = CurrencyRatesCompanion
    Function({
  Value<int> id,
  required String currencyCode,
  required double rate,
  required DateTime date,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$CurrencyRatesTableUpdateCompanionBuilder = CurrencyRatesCompanion
    Function({
  Value<int> id,
  Value<String> currencyCode,
  Value<double> rate,
  Value<DateTime> date,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$CurrencyRatesTableReferences
    extends BaseReferences<_$AppDatabase, $CurrencyRatesTable, ExchangeRate> {
  $$CurrencyRatesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $CurrenciesTable _currencyCodeTable(_$AppDatabase db) =>
      db.currencies.createAlias($_aliasNameGenerator(
          db.currencyRates.currencyCode, db.currencies.code));

  $$CurrenciesTableProcessedTableManager get currencyCode {
    final $_column = $_itemColumn<String>('currency_code')!;

    final manager = $$CurrenciesTableTableManager($_db, $_db.currencies)
        .filter((f) => f.code.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_currencyCodeTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$CurrencyRatesTableFilterComposer
    extends Composer<_$AppDatabase, $CurrencyRatesTable> {
  $$CurrencyRatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get rate => $composableBuilder(
      column: $table.rate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$CurrenciesTableFilterComposer get currencyCode {
    final $$CurrenciesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.currencyCode,
        referencedTable: $db.currencies,
        getReferencedColumn: (t) => t.code,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CurrenciesTableFilterComposer(
              $db: $db,
              $table: $db.currencies,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CurrencyRatesTableOrderingComposer
    extends Composer<_$AppDatabase, $CurrencyRatesTable> {
  $$CurrencyRatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get rate => $composableBuilder(
      column: $table.rate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$CurrenciesTableOrderingComposer get currencyCode {
    final $$CurrenciesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.currencyCode,
        referencedTable: $db.currencies,
        getReferencedColumn: (t) => t.code,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CurrenciesTableOrderingComposer(
              $db: $db,
              $table: $db.currencies,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CurrencyRatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CurrencyRatesTable> {
  $$CurrencyRatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get rate =>
      $composableBuilder(column: $table.rate, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CurrenciesTableAnnotationComposer get currencyCode {
    final $$CurrenciesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.currencyCode,
        referencedTable: $db.currencies,
        getReferencedColumn: (t) => t.code,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CurrenciesTableAnnotationComposer(
              $db: $db,
              $table: $db.currencies,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CurrencyRatesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CurrencyRatesTable,
    ExchangeRate,
    $$CurrencyRatesTableFilterComposer,
    $$CurrencyRatesTableOrderingComposer,
    $$CurrencyRatesTableAnnotationComposer,
    $$CurrencyRatesTableCreateCompanionBuilder,
    $$CurrencyRatesTableUpdateCompanionBuilder,
    (ExchangeRate, $$CurrencyRatesTableReferences),
    ExchangeRate,
    PrefetchHooks Function({bool currencyCode})> {
  $$CurrencyRatesTableTableManager(_$AppDatabase db, $CurrencyRatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CurrencyRatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CurrencyRatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CurrencyRatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> currencyCode = const Value.absent(),
            Value<double> rate = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              CurrencyRatesCompanion(
            id: id,
            currencyCode: currencyCode,
            rate: rate,
            date: date,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String currencyCode,
            required double rate,
            required DateTime date,
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              CurrencyRatesCompanion.insert(
            id: id,
            currencyCode: currencyCode,
            rate: rate,
            date: date,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CurrencyRatesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({currencyCode = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (currencyCode) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.currencyCode,
                    referencedTable:
                        $$CurrencyRatesTableReferences._currencyCodeTable(db),
                    referencedColumn: $$CurrencyRatesTableReferences
                        ._currencyCodeTable(db)
                        .code,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$CurrencyRatesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CurrencyRatesTable,
    ExchangeRate,
    $$CurrencyRatesTableFilterComposer,
    $$CurrencyRatesTableOrderingComposer,
    $$CurrencyRatesTableAnnotationComposer,
    $$CurrencyRatesTableCreateCompanionBuilder,
    $$CurrencyRatesTableUpdateCompanionBuilder,
    (ExchangeRate, $$CurrencyRatesTableReferences),
    ExchangeRate,
    PrefetchHooks Function({bool currencyCode})>;
typedef $$AccountsTableCreateCompanionBuilder = AccountsCompanion Function({
  Value<int> id,
  required String name,
  Value<String?> subtitle,
  required String currencyCode,
  required String icon,
  required int iconColor,
  Value<bool> includeInRevaluation,
  Value<DateTime> updatedAt,
  Value<DateTime> createdAt,
});
typedef $$AccountsTableUpdateCompanionBuilder = AccountsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String?> subtitle,
  Value<String> currencyCode,
  Value<String> icon,
  Value<int> iconColor,
  Value<bool> includeInRevaluation,
  Value<DateTime> updatedAt,
  Value<DateTime> createdAt,
});

final class $$AccountsTableReferences
    extends BaseReferences<_$AppDatabase, $AccountsTable, Account> {
  $$AccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CurrenciesTable _currencyCodeTable(_$AppDatabase db) =>
      db.currencies.createAlias(
          $_aliasNameGenerator(db.accounts.currencyCode, db.currencies.code));

  $$CurrenciesTableProcessedTableManager get currencyCode {
    final $_column = $_itemColumn<String>('currency_code')!;

    final manager = $$CurrenciesTableTableManager($_db, $_db.currencies)
        .filter((f) => f.code.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_currencyCodeTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
      _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.transactions,
          aliasName:
              $_aliasNameGenerator(db.accounts.id, db.transactions.accountId));

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter((f) => f.accountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subtitle => $composableBuilder(
      column: $table.subtitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get iconColor => $composableBuilder(
      column: $table.iconColor, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get includeInRevaluation => $composableBuilder(
      column: $table.includeInRevaluation,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$CurrenciesTableFilterComposer get currencyCode {
    final $$CurrenciesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.currencyCode,
        referencedTable: $db.currencies,
        getReferencedColumn: (t) => t.code,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CurrenciesTableFilterComposer(
              $db: $db,
              $table: $db.currencies,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> transactionsRefs(
      Expression<bool> Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableFilterComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subtitle => $composableBuilder(
      column: $table.subtitle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get iconColor => $composableBuilder(
      column: $table.iconColor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get includeInRevaluation => $composableBuilder(
      column: $table.includeInRevaluation,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$CurrenciesTableOrderingComposer get currencyCode {
    final $$CurrenciesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.currencyCode,
        referencedTable: $db.currencies,
        getReferencedColumn: (t) => t.code,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CurrenciesTableOrderingComposer(
              $db: $db,
              $table: $db.currencies,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get subtitle =>
      $composableBuilder(column: $table.subtitle, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get iconColor =>
      $composableBuilder(column: $table.iconColor, builder: (column) => column);

  GeneratedColumn<bool> get includeInRevaluation => $composableBuilder(
      column: $table.includeInRevaluation, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CurrenciesTableAnnotationComposer get currencyCode {
    final $$CurrenciesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.currencyCode,
        referencedTable: $db.currencies,
        getReferencedColumn: (t) => t.code,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CurrenciesTableAnnotationComposer(
              $db: $db,
              $table: $db.currencies,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> transactionsRefs<T extends Object>(
      Expression<T> Function($$TransactionsTableAnnotationComposer a) f) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableAnnotationComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AccountsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AccountsTable,
    Account,
    $$AccountsTableFilterComposer,
    $$AccountsTableOrderingComposer,
    $$AccountsTableAnnotationComposer,
    $$AccountsTableCreateCompanionBuilder,
    $$AccountsTableUpdateCompanionBuilder,
    (Account, $$AccountsTableReferences),
    Account,
    PrefetchHooks Function({bool currencyCode, bool transactionsRefs})> {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> subtitle = const Value.absent(),
            Value<String> currencyCode = const Value.absent(),
            Value<String> icon = const Value.absent(),
            Value<int> iconColor = const Value.absent(),
            Value<bool> includeInRevaluation = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              AccountsCompanion(
            id: id,
            name: name,
            subtitle: subtitle,
            currencyCode: currencyCode,
            icon: icon,
            iconColor: iconColor,
            includeInRevaluation: includeInRevaluation,
            updatedAt: updatedAt,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String?> subtitle = const Value.absent(),
            required String currencyCode,
            required String icon,
            required int iconColor,
            Value<bool> includeInRevaluation = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              AccountsCompanion.insert(
            id: id,
            name: name,
            subtitle: subtitle,
            currencyCode: currencyCode,
            icon: icon,
            iconColor: iconColor,
            includeInRevaluation: includeInRevaluation,
            updatedAt: updatedAt,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$AccountsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {currencyCode = false, transactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (transactionsRefs) db.transactions],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (currencyCode) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.currencyCode,
                    referencedTable:
                        $$AccountsTableReferences._currencyCodeTable(db),
                    referencedColumn:
                        $$AccountsTableReferences._currencyCodeTable(db).code,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionsRefs)
                    await $_getPrefetchedData<Account, $AccountsTable,
                            Transaction>(
                        currentTable: table,
                        referencedTable: $$AccountsTableReferences
                            ._transactionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AccountsTableReferences(db, table, p0)
                                .transactionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.accountId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$AccountsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AccountsTable,
    Account,
    $$AccountsTableFilterComposer,
    $$AccountsTableOrderingComposer,
    $$AccountsTableAnnotationComposer,
    $$AccountsTableCreateCompanionBuilder,
    $$AccountsTableUpdateCompanionBuilder,
    (Account, $$AccountsTableReferences),
    Account,
    PrefetchHooks Function({bool currencyCode, bool transactionsRefs})>;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  required String name,
  required String icon,
  required int color,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> icon,
  Value<int> color,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, Category> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
      _transactionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.transactions,
              aliasName: $_aliasNameGenerator(
                  db.categories.id, db.transactions.categoryId));

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> transactionsRefs(
      Expression<bool> Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableFilterComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> transactionsRefs<T extends Object>(
      Expression<T> Function($$TransactionsTableAnnotationComposer a) f) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableAnnotationComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoriesTable,
    Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (Category, $$CategoriesTableReferences),
    Category,
    PrefetchHooks Function({bool transactionsRefs})> {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> icon = const Value.absent(),
            Value<int> color = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              CategoriesCompanion(
            id: id,
            name: name,
            icon: icon,
            color: color,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String icon,
            required int color,
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              CategoriesCompanion.insert(
            id: id,
            name: name,
            icon: icon,
            color: color,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CategoriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({transactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (transactionsRefs) db.transactions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionsRefs)
                    await $_getPrefetchedData<Category, $CategoriesTable,
                            Transaction>(
                        currentTable: table,
                        referencedTable: $$CategoriesTableReferences
                            ._transactionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CategoriesTableReferences(db, table, p0)
                                .transactionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CategoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CategoriesTable,
    Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (Category, $$CategoriesTableReferences),
    Category,
    PrefetchHooks Function({bool transactionsRefs})>;
typedef $$TransactionsTableCreateCompanionBuilder = TransactionsCompanion
    Function({
  Value<int> id,
  required double amount,
  Value<int?> categoryId,
  required int accountId,
  required String currencyCode,
  Value<String?> reference,
  Value<String?> contact,
  Value<bool> isRecurrenceEnabled,
  Value<String?> recurrenceType,
  Value<String?> recurrenceEnds,
  required DateTime date,
  Value<DateTime> updatedAt,
  Value<double?> exchangeRateAtCreation,
  Value<double?> baseCurrencyAmount,
});
typedef $$TransactionsTableUpdateCompanionBuilder = TransactionsCompanion
    Function({
  Value<int> id,
  Value<double> amount,
  Value<int?> categoryId,
  Value<int> accountId,
  Value<String> currencyCode,
  Value<String?> reference,
  Value<String?> contact,
  Value<bool> isRecurrenceEnabled,
  Value<String?> recurrenceType,
  Value<String?> recurrenceEnds,
  Value<DateTime> date,
  Value<DateTime> updatedAt,
  Value<double?> exchangeRateAtCreation,
  Value<double?> baseCurrencyAmount,
});

final class $$TransactionsTableReferences
    extends BaseReferences<_$AppDatabase, $TransactionsTable, Transaction> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias(
          $_aliasNameGenerator(db.transactions.categoryId, db.categories.id));

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<int>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias(
          $_aliasNameGenerator(db.transactions.accountId, db.accounts.id));

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<int>('account_id')!;

    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $CurrenciesTable _currencyCodeTable(_$AppDatabase db) =>
      db.currencies.createAlias($_aliasNameGenerator(
          db.transactions.currencyCode, db.currencies.code));

  $$CurrenciesTableProcessedTableManager get currencyCode {
    final $_column = $_itemColumn<String>('currency_code')!;

    final manager = $$CurrenciesTableTableManager($_db, $_db.currencies)
        .filter((f) => f.code.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_currencyCodeTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reference => $composableBuilder(
      column: $table.reference, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contact => $composableBuilder(
      column: $table.contact, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isRecurrenceEnabled => $composableBuilder(
      column: $table.isRecurrenceEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recurrenceType => $composableBuilder(
      column: $table.recurrenceType,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recurrenceEnds => $composableBuilder(
      column: $table.recurrenceEnds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get exchangeRateAtCreation => $composableBuilder(
      column: $table.exchangeRateAtCreation,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get baseCurrencyAmount => $composableBuilder(
      column: $table.baseCurrencyAmount,
      builder: (column) => ColumnFilters(column));

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CurrenciesTableFilterComposer get currencyCode {
    final $$CurrenciesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.currencyCode,
        referencedTable: $db.currencies,
        getReferencedColumn: (t) => t.code,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CurrenciesTableFilterComposer(
              $db: $db,
              $table: $db.currencies,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reference => $composableBuilder(
      column: $table.reference, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contact => $composableBuilder(
      column: $table.contact, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isRecurrenceEnabled => $composableBuilder(
      column: $table.isRecurrenceEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recurrenceType => $composableBuilder(
      column: $table.recurrenceType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recurrenceEnds => $composableBuilder(
      column: $table.recurrenceEnds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get exchangeRateAtCreation => $composableBuilder(
      column: $table.exchangeRateAtCreation,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get baseCurrencyAmount => $composableBuilder(
      column: $table.baseCurrencyAmount,
      builder: (column) => ColumnOrderings(column));

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableOrderingComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableOrderingComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CurrenciesTableOrderingComposer get currencyCode {
    final $$CurrenciesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.currencyCode,
        referencedTable: $db.currencies,
        getReferencedColumn: (t) => t.code,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CurrenciesTableOrderingComposer(
              $db: $db,
              $table: $db.currencies,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => column);

  GeneratedColumn<String> get contact =>
      $composableBuilder(column: $table.contact, builder: (column) => column);

  GeneratedColumn<bool> get isRecurrenceEnabled => $composableBuilder(
      column: $table.isRecurrenceEnabled, builder: (column) => column);

  GeneratedColumn<String> get recurrenceType => $composableBuilder(
      column: $table.recurrenceType, builder: (column) => column);

  GeneratedColumn<String> get recurrenceEnds => $composableBuilder(
      column: $table.recurrenceEnds, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<double> get exchangeRateAtCreation => $composableBuilder(
      column: $table.exchangeRateAtCreation, builder: (column) => column);

  GeneratedColumn<double> get baseCurrencyAmount => $composableBuilder(
      column: $table.baseCurrencyAmount, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CurrenciesTableAnnotationComposer get currencyCode {
    final $$CurrenciesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.currencyCode,
        referencedTable: $db.currencies,
        getReferencedColumn: (t) => t.code,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CurrenciesTableAnnotationComposer(
              $db: $db,
              $table: $db.currencies,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransactionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TransactionsTable,
    Transaction,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableAnnotationComposer,
    $$TransactionsTableCreateCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder,
    (Transaction, $$TransactionsTableReferences),
    Transaction,
    PrefetchHooks Function(
        {bool categoryId, bool accountId, bool currencyCode})> {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            Value<int> accountId = const Value.absent(),
            Value<String> currencyCode = const Value.absent(),
            Value<String?> reference = const Value.absent(),
            Value<String?> contact = const Value.absent(),
            Value<bool> isRecurrenceEnabled = const Value.absent(),
            Value<String?> recurrenceType = const Value.absent(),
            Value<String?> recurrenceEnds = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<double?> exchangeRateAtCreation = const Value.absent(),
            Value<double?> baseCurrencyAmount = const Value.absent(),
          }) =>
              TransactionsCompanion(
            id: id,
            amount: amount,
            categoryId: categoryId,
            accountId: accountId,
            currencyCode: currencyCode,
            reference: reference,
            contact: contact,
            isRecurrenceEnabled: isRecurrenceEnabled,
            recurrenceType: recurrenceType,
            recurrenceEnds: recurrenceEnds,
            date: date,
            updatedAt: updatedAt,
            exchangeRateAtCreation: exchangeRateAtCreation,
            baseCurrencyAmount: baseCurrencyAmount,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required double amount,
            Value<int?> categoryId = const Value.absent(),
            required int accountId,
            required String currencyCode,
            Value<String?> reference = const Value.absent(),
            Value<String?> contact = const Value.absent(),
            Value<bool> isRecurrenceEnabled = const Value.absent(),
            Value<String?> recurrenceType = const Value.absent(),
            Value<String?> recurrenceEnds = const Value.absent(),
            required DateTime date,
            Value<DateTime> updatedAt = const Value.absent(),
            Value<double?> exchangeRateAtCreation = const Value.absent(),
            Value<double?> baseCurrencyAmount = const Value.absent(),
          }) =>
              TransactionsCompanion.insert(
            id: id,
            amount: amount,
            categoryId: categoryId,
            accountId: accountId,
            currencyCode: currencyCode,
            reference: reference,
            contact: contact,
            isRecurrenceEnabled: isRecurrenceEnabled,
            recurrenceType: recurrenceType,
            recurrenceEnds: recurrenceEnds,
            date: date,
            updatedAt: updatedAt,
            exchangeRateAtCreation: exchangeRateAtCreation,
            baseCurrencyAmount: baseCurrencyAmount,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TransactionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {categoryId = false, accountId = false, currencyCode = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable:
                        $$TransactionsTableReferences._categoryIdTable(db),
                    referencedColumn:
                        $$TransactionsTableReferences._categoryIdTable(db).id,
                  ) as T;
                }
                if (accountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.accountId,
                    referencedTable:
                        $$TransactionsTableReferences._accountIdTable(db),
                    referencedColumn:
                        $$TransactionsTableReferences._accountIdTable(db).id,
                  ) as T;
                }
                if (currencyCode) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.currencyCode,
                    referencedTable:
                        $$TransactionsTableReferences._currencyCodeTable(db),
                    referencedColumn: $$TransactionsTableReferences
                        ._currencyCodeTable(db)
                        .code,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$TransactionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TransactionsTable,
    Transaction,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableAnnotationComposer,
    $$TransactionsTableCreateCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder,
    (Transaction, $$TransactionsTableReferences),
    Transaction,
    PrefetchHooks Function(
        {bool categoryId, bool accountId, bool currencyCode})>;
typedef $$UserSettingsTableCreateCompanionBuilder = UserSettingsCompanion
    Function({
  Value<int> id,
  required String baseCurrencyCode,
  Value<String> username,
  Value<String?> profilePicturePath,
  Value<String> currencySelectionMode,
  Value<DateTime?> lastAutoFetchDate,
});
typedef $$UserSettingsTableUpdateCompanionBuilder = UserSettingsCompanion
    Function({
  Value<int> id,
  Value<String> baseCurrencyCode,
  Value<String> username,
  Value<String?> profilePicturePath,
  Value<String> currencySelectionMode,
  Value<DateTime?> lastAutoFetchDate,
});

final class $$UserSettingsTableReferences
    extends BaseReferences<_$AppDatabase, $UserSettingsTable, UserSetting> {
  $$UserSettingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CurrenciesTable _baseCurrencyCodeTable(_$AppDatabase db) =>
      db.currencies.createAlias($_aliasNameGenerator(
          db.userSettings.baseCurrencyCode, db.currencies.code));

  $$CurrenciesTableProcessedTableManager get baseCurrencyCode {
    final $_column = $_itemColumn<String>('base_currency_code')!;

    final manager = $$CurrenciesTableTableManager($_db, $_db.currencies)
        .filter((f) => f.code.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_baseCurrencyCodeTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$UserSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $UserSettingsTable> {
  $$UserSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get profilePicturePath => $composableBuilder(
      column: $table.profilePicturePath,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currencySelectionMode => $composableBuilder(
      column: $table.currencySelectionMode,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastAutoFetchDate => $composableBuilder(
      column: $table.lastAutoFetchDate,
      builder: (column) => ColumnFilters(column));

  $$CurrenciesTableFilterComposer get baseCurrencyCode {
    final $$CurrenciesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.baseCurrencyCode,
        referencedTable: $db.currencies,
        getReferencedColumn: (t) => t.code,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CurrenciesTableFilterComposer(
              $db: $db,
              $table: $db.currencies,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UserSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserSettingsTable> {
  $$UserSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get profilePicturePath => $composableBuilder(
      column: $table.profilePicturePath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currencySelectionMode => $composableBuilder(
      column: $table.currencySelectionMode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastAutoFetchDate => $composableBuilder(
      column: $table.lastAutoFetchDate,
      builder: (column) => ColumnOrderings(column));

  $$CurrenciesTableOrderingComposer get baseCurrencyCode {
    final $$CurrenciesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.baseCurrencyCode,
        referencedTable: $db.currencies,
        getReferencedColumn: (t) => t.code,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CurrenciesTableOrderingComposer(
              $db: $db,
              $table: $db.currencies,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UserSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserSettingsTable> {
  $$UserSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get profilePicturePath => $composableBuilder(
      column: $table.profilePicturePath, builder: (column) => column);

  GeneratedColumn<String> get currencySelectionMode => $composableBuilder(
      column: $table.currencySelectionMode, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAutoFetchDate => $composableBuilder(
      column: $table.lastAutoFetchDate, builder: (column) => column);

  $$CurrenciesTableAnnotationComposer get baseCurrencyCode {
    final $$CurrenciesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.baseCurrencyCode,
        referencedTable: $db.currencies,
        getReferencedColumn: (t) => t.code,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CurrenciesTableAnnotationComposer(
              $db: $db,
              $table: $db.currencies,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UserSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserSettingsTable,
    UserSetting,
    $$UserSettingsTableFilterComposer,
    $$UserSettingsTableOrderingComposer,
    $$UserSettingsTableAnnotationComposer,
    $$UserSettingsTableCreateCompanionBuilder,
    $$UserSettingsTableUpdateCompanionBuilder,
    (UserSetting, $$UserSettingsTableReferences),
    UserSetting,
    PrefetchHooks Function({bool baseCurrencyCode})> {
  $$UserSettingsTableTableManager(_$AppDatabase db, $UserSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> baseCurrencyCode = const Value.absent(),
            Value<String> username = const Value.absent(),
            Value<String?> profilePicturePath = const Value.absent(),
            Value<String> currencySelectionMode = const Value.absent(),
            Value<DateTime?> lastAutoFetchDate = const Value.absent(),
          }) =>
              UserSettingsCompanion(
            id: id,
            baseCurrencyCode: baseCurrencyCode,
            username: username,
            profilePicturePath: profilePicturePath,
            currencySelectionMode: currencySelectionMode,
            lastAutoFetchDate: lastAutoFetchDate,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String baseCurrencyCode,
            Value<String> username = const Value.absent(),
            Value<String?> profilePicturePath = const Value.absent(),
            Value<String> currencySelectionMode = const Value.absent(),
            Value<DateTime?> lastAutoFetchDate = const Value.absent(),
          }) =>
              UserSettingsCompanion.insert(
            id: id,
            baseCurrencyCode: baseCurrencyCode,
            username: username,
            profilePicturePath: profilePicturePath,
            currencySelectionMode: currencySelectionMode,
            lastAutoFetchDate: lastAutoFetchDate,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$UserSettingsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({baseCurrencyCode = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (baseCurrencyCode) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.baseCurrencyCode,
                    referencedTable: $$UserSettingsTableReferences
                        ._baseCurrencyCodeTable(db),
                    referencedColumn: $$UserSettingsTableReferences
                        ._baseCurrencyCodeTable(db)
                        .code,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$UserSettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UserSettingsTable,
    UserSetting,
    $$UserSettingsTableFilterComposer,
    $$UserSettingsTableOrderingComposer,
    $$UserSettingsTableAnnotationComposer,
    $$UserSettingsTableCreateCompanionBuilder,
    $$UserSettingsTableUpdateCompanionBuilder,
    (UserSetting, $$UserSettingsTableReferences),
    UserSetting,
    PrefetchHooks Function({bool baseCurrencyCode})>;
typedef $$ExchangeRateSnapshotsTableCreateCompanionBuilder
    = ExchangeRateSnapshotsCompanion Function({
  Value<int> id,
  required DateTime date,
  required String ratesJson,
  required String source,
  Value<DateTime> createdAt,
});
typedef $$ExchangeRateSnapshotsTableUpdateCompanionBuilder
    = ExchangeRateSnapshotsCompanion Function({
  Value<int> id,
  Value<DateTime> date,
  Value<String> ratesJson,
  Value<String> source,
  Value<DateTime> createdAt,
});

class $$ExchangeRateSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $ExchangeRateSnapshotsTable> {
  $$ExchangeRateSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ratesJson => $composableBuilder(
      column: $table.ratesJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$ExchangeRateSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExchangeRateSnapshotsTable> {
  $$ExchangeRateSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ratesJson => $composableBuilder(
      column: $table.ratesJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$ExchangeRateSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExchangeRateSnapshotsTable> {
  $$ExchangeRateSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get ratesJson =>
      $composableBuilder(column: $table.ratesJson, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ExchangeRateSnapshotsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExchangeRateSnapshotsTable,
    ExchangeRateSnapshot,
    $$ExchangeRateSnapshotsTableFilterComposer,
    $$ExchangeRateSnapshotsTableOrderingComposer,
    $$ExchangeRateSnapshotsTableAnnotationComposer,
    $$ExchangeRateSnapshotsTableCreateCompanionBuilder,
    $$ExchangeRateSnapshotsTableUpdateCompanionBuilder,
    (
      ExchangeRateSnapshot,
      BaseReferences<_$AppDatabase, $ExchangeRateSnapshotsTable,
          ExchangeRateSnapshot>
    ),
    ExchangeRateSnapshot,
    PrefetchHooks Function()> {
  $$ExchangeRateSnapshotsTableTableManager(
      _$AppDatabase db, $ExchangeRateSnapshotsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExchangeRateSnapshotsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$ExchangeRateSnapshotsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExchangeRateSnapshotsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String> ratesJson = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ExchangeRateSnapshotsCompanion(
            id: id,
            date: date,
            ratesJson: ratesJson,
            source: source,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime date,
            required String ratesJson,
            required String source,
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ExchangeRateSnapshotsCompanion.insert(
            id: id,
            date: date,
            ratesJson: ratesJson,
            source: source,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ExchangeRateSnapshotsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $ExchangeRateSnapshotsTable,
        ExchangeRateSnapshot,
        $$ExchangeRateSnapshotsTableFilterComposer,
        $$ExchangeRateSnapshotsTableOrderingComposer,
        $$ExchangeRateSnapshotsTableAnnotationComposer,
        $$ExchangeRateSnapshotsTableCreateCompanionBuilder,
        $$ExchangeRateSnapshotsTableUpdateCompanionBuilder,
        (
          ExchangeRateSnapshot,
          BaseReferences<_$AppDatabase, $ExchangeRateSnapshotsTable,
              ExchangeRateSnapshot>
        ),
        ExchangeRateSnapshot,
        PrefetchHooks Function()>;
typedef $$NetWorthHistoryTableCreateCompanionBuilder = NetWorthHistoryCompanion
    Function({
  Value<int> id,
  required DateTime date,
  required double totalInBaseCurrency,
  required double totalInNationalCurrency,
  Value<DateTime> createdAt,
});
typedef $$NetWorthHistoryTableUpdateCompanionBuilder = NetWorthHistoryCompanion
    Function({
  Value<int> id,
  Value<DateTime> date,
  Value<double> totalInBaseCurrency,
  Value<double> totalInNationalCurrency,
  Value<DateTime> createdAt,
});

class $$NetWorthHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $NetWorthHistoryTable> {
  $$NetWorthHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalInBaseCurrency => $composableBuilder(
      column: $table.totalInBaseCurrency,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalInNationalCurrency => $composableBuilder(
      column: $table.totalInNationalCurrency,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$NetWorthHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $NetWorthHistoryTable> {
  $$NetWorthHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalInBaseCurrency => $composableBuilder(
      column: $table.totalInBaseCurrency,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalInNationalCurrency => $composableBuilder(
      column: $table.totalInNationalCurrency,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$NetWorthHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $NetWorthHistoryTable> {
  $$NetWorthHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get totalInBaseCurrency => $composableBuilder(
      column: $table.totalInBaseCurrency, builder: (column) => column);

  GeneratedColumn<double> get totalInNationalCurrency => $composableBuilder(
      column: $table.totalInNationalCurrency, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$NetWorthHistoryTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NetWorthHistoryTable,
    NetWorthHistoryData,
    $$NetWorthHistoryTableFilterComposer,
    $$NetWorthHistoryTableOrderingComposer,
    $$NetWorthHistoryTableAnnotationComposer,
    $$NetWorthHistoryTableCreateCompanionBuilder,
    $$NetWorthHistoryTableUpdateCompanionBuilder,
    (
      NetWorthHistoryData,
      BaseReferences<_$AppDatabase, $NetWorthHistoryTable, NetWorthHistoryData>
    ),
    NetWorthHistoryData,
    PrefetchHooks Function()> {
  $$NetWorthHistoryTableTableManager(
      _$AppDatabase db, $NetWorthHistoryTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NetWorthHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NetWorthHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NetWorthHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<double> totalInBaseCurrency = const Value.absent(),
            Value<double> totalInNationalCurrency = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              NetWorthHistoryCompanion(
            id: id,
            date: date,
            totalInBaseCurrency: totalInBaseCurrency,
            totalInNationalCurrency: totalInNationalCurrency,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime date,
            required double totalInBaseCurrency,
            required double totalInNationalCurrency,
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              NetWorthHistoryCompanion.insert(
            id: id,
            date: date,
            totalInBaseCurrency: totalInBaseCurrency,
            totalInNationalCurrency: totalInNationalCurrency,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$NetWorthHistoryTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $NetWorthHistoryTable,
    NetWorthHistoryData,
    $$NetWorthHistoryTableFilterComposer,
    $$NetWorthHistoryTableOrderingComposer,
    $$NetWorthHistoryTableAnnotationComposer,
    $$NetWorthHistoryTableCreateCompanionBuilder,
    $$NetWorthHistoryTableUpdateCompanionBuilder,
    (
      NetWorthHistoryData,
      BaseReferences<_$AppDatabase, $NetWorthHistoryTable, NetWorthHistoryData>
    ),
    NetWorthHistoryData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CurrenciesTableTableManager get currencies =>
      $$CurrenciesTableTableManager(_db, _db.currencies);
  $$CurrencyRatesTableTableManager get currencyRates =>
      $$CurrencyRatesTableTableManager(_db, _db.currencyRates);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$UserSettingsTableTableManager get userSettings =>
      $$UserSettingsTableTableManager(_db, _db.userSettings);
  $$ExchangeRateSnapshotsTableTableManager get exchangeRateSnapshots =>
      $$ExchangeRateSnapshotsTableTableManager(_db, _db.exchangeRateSnapshots);
  $$NetWorthHistoryTableTableManager get netWorthHistory =>
      $$NetWorthHistoryTableTableManager(_db, _db.netWorthHistory);
}
