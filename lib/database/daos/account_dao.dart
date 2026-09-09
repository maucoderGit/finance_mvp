import 'package:drift/drift.dart';
import '../app_database.dart';

part 'account_dao.g.dart';

@DriftAccessor(tables: [Accounts, Transactions, Currencies])
class AccountDao extends DatabaseAccessor<AppDatabase>
    with _$AccountDaoMixin {
  AccountDao(super.db);

  Future<List<Account>> getAllAccounts() => select(accounts).get();

  Stream<List<Account>> watchAllAccounts() => select(accounts).watch();

  Future<Account?> getAccountById(int id) =>
      (select(accounts)..where((a) => a.id.equals(id))).getSingleOrNull();

  Stream<double> watchAccountBalance(int accountId) {
    final query = selectOnly(transactions).join([
      innerJoin(accounts, accounts.id.equalsExp(transactions.accountId)),
    ])
      ..where(transactions.accountId.equals(accountId))
      ..addColumns([transactions.amount.sum()]);

    return query.watchSingle().map((row) {
      return row.read(transactions.amount.sum()) ?? 0.0;
    });
  }

  Future<double> getAccountBalance(int accountId) async {
    final query = selectOnly(transactions).join([
      innerJoin(accounts, accounts.id.equalsExp(transactions.accountId)),
    ])
      ..where(transactions.accountId.equals(accountId))
      ..addColumns([transactions.amount.sum()]);

    final result = await query.getSingleOrNull();
    return result?.read(transactions.amount.sum()) ?? 0.0;
  }

  Stream<Map<int, double>> watchAllAccountBalances() async* {
    final accountsList = await select(accounts).get();
    final balances = <int, double>{};

    for (final account in accountsList) {
      final balance = await getAccountBalance(account.id);
      balances[account.id] = balance;
    }
    yield balances;
  }

  Future<int> insertAccount(AccountsCompanion account) =>
      into(accounts).insert(account);

  Future<bool> updateAccount(AccountsCompanion account) =>
      update(accounts).replace(account);

  Future<int> deleteAccount(int id) =>
      (delete(accounts)..where((a) => a.id.equals(id))).go();

  Future<List<Account>> getAccountsByCurrency(String currencyCode) =>
      (select(accounts)..where((a) => a.currencyCode.equals(currencyCode)))
          .get();
}
