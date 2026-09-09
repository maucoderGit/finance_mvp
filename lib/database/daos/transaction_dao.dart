import 'package:drift/drift.dart';
import '../app_database.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [Transactions, Accounts, Currencies, Categories])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  Stream<List<Transaction>> watchAllTransactions() =>
      select(transactions).watch();

  Future<List<Transaction>> getAllTransactions() =>
      select(transactions).get();

  Future<Transaction?> getTransactionById(int id) =>
      (select(transactions)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<List<Transaction>> watchTransactionsByAccount(int accountId) =>
      (select(transactions)..where((t) => t.accountId.equals(accountId)))
          .watch();

  Stream<List<Transaction>> watchTransactionsByDateRange(
      DateTime start, DateTime end) {
    return (select(transactions)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerOrEqualValue(end))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  Stream<List<Transaction>> watchTransactionsByMonth(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    return watchTransactionsByDateRange(start, end);
  }

  Future<double> getAccountBalance(int accountId) async {
    final query = select(transactions)
      ..where((t) => t.accountId.equals(accountId));
    final txs = await query.get();
    return txs.fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  Future<double> getAccountBalanceAtDate(
      int accountId, DateTime date) async {
    final query = select(transactions)
      ..where((t) =>
          t.accountId.equals(accountId) &
          t.date.isSmallerOrEqualValue(date));
    final txs = await query.get();
    return txs.fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  Future<List<Transaction>> getTransactionsByAccountAndCurrency(
      int accountId, String currencyCode) {
    return (select(transactions)
          ..where((t) =>
              t.accountId.equals(accountId) &
              t.currencyCode.equals(currencyCode)))
        .get();
  }

  Stream<List<Transaction>> watchTransactionsByCurrency(
      String currencyCode) {
    return (select(transactions)
          ..where((t) => t.currencyCode.equals(currencyCode))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  Future<int> insertTransaction(TransactionsCompanion transaction) =>
      into(transactions).insert(transaction);

  Future<int> insertTransactionReturning(TransactionsCompanion transaction) =>
      into(transactions).insert(transaction);

  Future<bool> updateTransaction(TransactionsCompanion transaction) =>
      update(transactions).replace(transaction);

  Future<int> deleteTransaction(int id) =>
      (delete(transactions)..where((t) => t.id.equals(id))).go();

  Future<Map<String, double>> getTotalBalanceByCurrency() async {
    final allAccounts = await (select(db.accounts)).get();
    final balances = <String, double>{};

    for (final account in allAccounts) {
      final balance = await getAccountBalance(account.id);
      balances[account.currencyCode] =
          (balances[account.currencyCode] ?? 0.0) + balance;
    }

    return balances;
  }
}
