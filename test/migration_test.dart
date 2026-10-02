import 'dart:io';

import 'package:drift/native.dart';
import 'package:finance_mvp/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'test_db.dart';

void main() {
  setUpAll(() => useSystemSqlite());

  test('re-run of a partially-applied migration does not crash', () async {
    final dir = await Directory.systemTemp.createTemp('dp_migration');
    final file = File(p.join(dir.path, 'db.sqlite'));

    // Reproduce the reported state: a v1 DB whose `accounts` table was already
    // upgraded (include_in_revaluation present), but PRAGMA user_version is
    // still 1 — so every pre-v2 ALTER re-runs and collides.
    final raw = sqlite.sqlite3.open(file.path);
    raw.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        subtitle TEXT,
        currency_code TEXT NOT NULL,
        icon TEXT NOT NULL,
        icon_color INTEGER NOT NULL,
        include_in_revaluation INTEGER NOT NULL DEFAULT 1
          CHECK (include_in_revaluation IN (0, 1)),
        updated_at TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    raw.execute('''CREATE TABLE transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      amount REAL NOT NULL,
      category_id INTEGER NULL,
      account_id INTEGER NOT NULL,
      currency_code TEXT NOT NULL,
      reference TEXT NULL,
      contact TEXT NULL,
      is_recurrence_enabled INTEGER NOT NULL DEFAULT 0,
      recurrence_type TEXT NULL,
      recurrence_ends TEXT NULL,
      date INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )''');
    raw.execute('''CREATE TABLE user_settings (
      id INTEGER NOT NULL DEFAULT 0,
      base_currency_code TEXT NOT NULL,
      username TEXT NOT NULL DEFAULT 'User',
      profile_picture_path TEXT NULL,
      PRIMARY KEY (id)
    )''');
    raw.execute('''CREATE TABLE currency_rates (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      currency_code TEXT NOT NULL,
      rate REAL NOT NULL,
      date INTEGER NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )''');
    raw.execute('CREATE TABLE categories (id INTEGER PRIMARY KEY AUTOINCREMENT, '
        "name TEXT NOT NULL, icon TEXT NOT NULL, color INTEGER NOT NULL, "
        'created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)');
    raw.execute('''CREATE TABLE currencies (code TEXT NOT NULL PRIMARY KEY,
      name TEXT NOT NULL, symbol TEXT NOT NULL, separator TEXT NOT NULL
        DEFAULT ',', decimal_digits INTEGER NOT NULL DEFAULT 2,
      created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)''');
    raw.execute("INSERT INTO accounts (name, currency_code, icon, icon_color, "
        "updated_at, created_at) VALUES ('Checking', 'USD', 'bank', 1, "
        "'2026-01-01', '2026-01-01')");
    raw.execute('PRAGMA user_version = 1');
    raw.dispose();

    final db = AppDatabase(executor: NativeDatabase(file));

    expect(
      () async {
        await db.customSelect('SELECT 1').get();
      },
      returnsNormally,
    );

    final version = await db
        .customSelect('PRAGMA user_version')
        .map((r) => r.read<int>('user_version'))
        .getSingle();
    expect(version, 15);

    final accounts = await db.customSelect('SELECT * FROM accounts').get();
    expect(accounts, hasLength(1));
    expect(accounts.single.read<String>('name'), 'Checking');
    expect(accounts.single.read<int>('include_in_revaluation'), 1);

    await db.close();
    await dir.delete(recursive: true);
  });

  test('upgrade recreates tables missing from a partially-created DB',
      () async {
    final dir = await Directory.systemTemp.createTemp('dp_migration');
    final file = File(p.join(dir.path, 'db.sqlite'));

    // A v1 DB that only ever got `accounts` — user_settings and the rest are
    // absent, so the pre-v2 ALTERs reference a table that doesn't exist.
    final raw = sqlite.sqlite3.open(file.path);
    raw.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        subtitle TEXT,
        currency_code TEXT NOT NULL,
        icon TEXT NOT NULL,
        icon_color INTEGER NOT NULL,
        include_in_revaluation INTEGER NOT NULL DEFAULT 1
          CHECK (include_in_revaluation IN (0, 1)),
        updated_at TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    raw.execute("INSERT INTO accounts (name, currency_code, icon, icon_color, "
        "updated_at, created_at) VALUES ('Checking', 'USD', 'bank', 1, "
        "'2026-01-01', '2026-01-01')");
    raw.execute('PRAGMA user_version = 1');
    raw.dispose();

    final db = AppDatabase(executor: NativeDatabase(file));

    expect(
      () async {
        await db.customSelect('SELECT 1').get();
      },
      returnsNormally,
    );

    final version = await db
        .customSelect('PRAGMA user_version')
        .map((r) => r.read<int>('user_version'))
        .getSingle();
    expect(version, 15);

    final settings = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name = 'user_settings'")
        .get();
    expect(settings, hasLength(1));

    await db.close();
    await dir.delete(recursive: true);
  });

  test('stale currency_rates table is rebuilt, not ALTERed', () async {
    final dir = await Directory.systemTemp.createTemp('dp_migration');
    final file = File(p.join(dir.path, 'db.sqlite'));

    // A pre-v5-era `currency_rates` that exists but predates its
    // currency_code/date columns — the v5 dedupe SQL used to crash on it.
    final raw = sqlite.sqlite3.open(file.path);
    raw.execute('CREATE TABLE currency_rates (id INTEGER PRIMARY KEY '
        'AUTOINCREMENT, code TEXT NOT NULL, rate REAL NOT NULL)');
    raw.execute("INSERT INTO currency_rates (code, rate) VALUES ('USD', 1.0)");
    raw.execute('PRAGMA user_version = 1');
    raw.dispose();

    final db = AppDatabase(executor: NativeDatabase(file));

    expect(
      () async {
        await db.customSelect('SELECT 1').get();
      },
      returnsNormally,
    );

    final version = await db
        .customSelect('PRAGMA user_version')
        .map((r) => r.read<int>('user_version'))
        .getSingle();
    expect(version, 15);

    // Rebuilt from the current schema: now has currency_code + the UNIQUE index.
    final cols = await db
        .customSelect('PRAGMA table_info("currency_rates")')
        .map((r) => r.read<String>('name'))
        .get();
    expect(cols, containsAll(['currency_code', 'date', 'rate', 'created_at']));

    await db.close();
    await dir.delete(recursive: true);
  });

  test('a v14 DB gains the goals table with its foreign keys intact', () async {
    final dir = await Directory.systemTemp.createTemp('dp_migration');
    final file = File(p.join(dir.path, 'db.sqlite'));

    // v14 is the version that shipped before goals existed, so this is what an
    // upgrading install actually holds: full data, no goals table. Building it
    // from a real v15 file and rewinding is the only way to get genuine v14
    // contents without hand-writing every pre-v15 migration's output.
    final seed = AppDatabase(executor: NativeDatabase(file));
    final base = (await seed.select(seed.currencies).get()).first;
    await seed.into(seed.accounts).insert(AccountsCompanion.insert(
          name: 'Checking',
          currencyCode: base.code,
          icon: 'bank',
          iconColor: 1,
        ));
    await seed.close();

    final raw = sqlite.sqlite3.open(file.path);
    raw.execute('DROP TABLE goals');
    raw.execute('PRAGMA user_version = 14');
    raw.dispose();

    final db = AppDatabase(executor: NativeDatabase(file));

    expect(
      () async {
        await db.customSelect('SELECT 1').get();
      },
      returnsNormally,
    );

    // The pre-existing account survived the upgrade.
    expect(await db.select(db.accounts).get(), hasLength(1));

    // And the goals table is usable, foreign keys and all.
    final goal = await db.into(db.goals).insertReturning(GoalsCompanion.insert(
          accountId: 1,
          name: 'Emergency fund',
          targetAmount: 1000,
          currencyCode: 'USD',
        ));
    expect(goal.id, isNotNull);
    expect(await db.select(db.goals).get(), hasLength(1));

    await db.close();
    await dir.delete(recursive: true);
  });

  test('ancient DB that no migration can repair is rebuilt from scratch',
      () async {
    final dir = await Directory.systemTemp.createTemp('dp_migration');
    final file = File(p.join(dir.path, 'db.sqlite'));

    // Copied from the real failing DB: current user_version (7) but the tables
    // come from a much older app version — accounts/currencies missing their
    // timestamps, `transactions` carrying a legacy NOT NULL `type` column that
    // drift never writes. No upgrade step knows about these.
    final raw = sqlite.sqlite3.open(file.path);
    raw.execute('''CREATE TABLE accounts (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL, subtitle TEXT NULL,
      balance REAL NOT NULL DEFAULT 0.0,
      currency_code TEXT NOT NULL,
      icon TEXT NOT NULL, icon_color INTEGER NOT NULL,
      is_base INTEGER NOT NULL DEFAULT 0
        CHECK ("is_base" IN (0, 1)),
      include_in_revaluation INTEGER NOT NULL DEFAULT 1
        CHECK ("include_in_revaluation" IN (0, 1))
    )''');
    raw.execute('CREATE TABLE currencies (code TEXT NOT NULL PRIMARY KEY, '
        'name TEXT NOT NULL, symbol TEXT NOT NULL, separator TEXT NOT NULL '
        "DEFAULT ',', decimal_digits INTEGER NOT NULL DEFAULT 2)");
    raw.execute('CREATE TABLE transactions (id INTEGER NOT NULL PRIMARY KEY '
        'AUTOINCREMENT, amount REAL NOT NULL, type INTEGER NOT NULL, '
        'category_id INTEGER NULL, account_id INTEGER NOT NULL, '
        'currency_code TEXT NOT NULL)');
    raw.execute('CREATE TABLE categories (id INTEGER NOT NULL PRIMARY KEY '
        'AUTOINCREMENT, name TEXT NOT NULL, icon TEXT NOT NULL, '
        'color INTEGER NOT NULL)');
    raw.execute('CREATE TABLE user_settings (id INTEGER NOT NULL DEFAULT 0, '
        'base_currency_code TEXT NOT NULL, username TEXT NOT NULL DEFAULT '
        "'User', PRIMARY KEY (id))");
    raw.execute('PRAGMA user_version = 7');
    raw.dispose();

    final db = AppDatabase(executor: NativeDatabase(file));

    expect(
      () async {
        await db.customSelect('SELECT 1').get();
      },
      returnsNormally,
    );

    final version = await db
        .customSelect('PRAGMA user_version')
        .map((r) => r.read<int>('user_version'))
        .getSingle();
    expect(version, 15);

    // The rebuilt DB matches drift: timestamps present, no legacy `type`.
    final accountsCols = await db
        .customSelect('PRAGMA table_info("accounts")')
        .map((r) => r.read<String>('name'))
        .get();
    expect(accountsCols, containsAll(['updated_at', 'created_at']));

    final txCols = await db
        .customSelect('PRAGMA table_info("transactions")')
        .map((r) => r.read<String>('name'))
        .get();
    expect(txCols, isNot(contains('type')));

    // Reader can now map the currencies table (missing timestamps crashed it).
    final currencies = await db.select(db.currencies).get();
    expect(currencies, isNotEmpty);

    await db.close();
    await dir.delete(recursive: true);
  });
}