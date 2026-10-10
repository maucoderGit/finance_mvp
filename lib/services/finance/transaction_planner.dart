import 'package:drift/drift.dart';
import 'package:finance_mvp/database/app_database.dart' as db;
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/services/finance/currency_converter.dart';
import 'package:finance_mvp/services/finance/fx_delta.dart';

/// A debt to create (or re-sync) together with the transaction that sourced it.
class DebtPlan {
  const DebtPlan({
    required this.title,
    required this.amount,
    required this.direction,
    required this.contactId,
    required this.currency,
    required this.firstDueDate,
    required this.debt,
    required this.installments,
  });

  final String title;
  final double amount;
  final String direction;
  final int? contactId;
  final String currency;
  final DateTime firstDueDate;
  final db.DebtsCompanion debt;
  final List<db.DebtInstallmentsCompanion> installments;
}

/// The two linked legs of an internal transfer/menudeo.
class TransferLegs {
  const TransferLegs({required this.fromLeg, required this.toLeg});

  final db.TransactionsCompanion fromLeg;
  final db.TransactionsCompanion toLeg;
}

/// Plans the rows a transaction form saves: the debt/installment schedule for
/// debt mode, and the pair of FX-consistent legs for an internal transfer.
///
/// Kept out of the widget so the money math is unit-testable and the form
/// stays presentation-only.
class TransactionPlanner {
  TransactionPlanner(this._repo);

  final FinanceRepository _repo;

  /// Due date of the [index]-th installment, spaced from [firstDue] (or today)
  /// by [frequency]. Calendar month arithmetic, so a month-end first due date
  /// rolls over safely instead of drifting by DST/length.
  static DateTime intervalDate(
      DateTime? firstDue, String frequency, int index) {
    final d = firstDue ?? DateTime.now();
    switch (frequency) {
      case 'weekly':
        return d.add(Duration(days: 7 * index));
      case 'biweekly':
        return d.add(Duration(days: 14 * index));
      default:
        return DateTime(d.year, d.month + index, d.day);
    }
  }

  /// One debt in [currency] for [total], split into [installmentCount] quotas.
  /// Each quota is snapped to the currency's minor unit; the last absorbs the
  /// remainder so the schedule always sums back to [total].
  Future<DebtPlan> buildDebtPlan({
    required String title,
    required double total,
    required int installmentCount,
    required DateTime firstDueDate,
    required String frequency,
    required String direction,
    required String currency,
    int? contactId,
    DateTime? date,
  }) async {
    final now = date ?? DateTime.now();
    final digits = await _repo.getDecimalDigits(currency);
    final per = quantizeTo(total / installmentCount, digits);

    DateTime due(int i) => intervalDate(firstDueDate, frequency, i);

    final debt = db.DebtsCompanion.insert(
      contactId: Value(contactId),
      direction: Value(direction),
      description: Value(title),
      amount: total,
      currencyCode: currency,
      date: now,
      dueDate: Value(due(0)),
      frequency: Value(frequency),
    );

    return DebtPlan(
      title: title,
      amount: total,
      direction: direction,
      contactId: contactId,
      currency: currency,
      firstDueDate: due(0),
      debt: debt,
      installments: [
        for (var i = 0; i < installmentCount; i++)
          db.DebtInstallmentsCompanion(
            index: Value(i),
            amount: Value(i == installmentCount - 1
                ? total - per * (installmentCount - 1)
                : per),
            dueDate: Value(due(i)),
          ),
      ],
    );
  }

  /// The two legs of a transfer: source negative, destination positive, with
  /// per-account rates so both legs agree on the transferred base value, and
  /// the FX delta logged on whichever leg is in the national currency.
  Future<TransferLegs> buildTransferLegs({
    required db.Account from,
    required db.Account to,
    required double amount,
    required String reference,
    required DateTime date,
    double? manualRate,
  }) async {
    final baseCode = await _repo.getBaseCurrencyCode();
    final nationalCode = await _repo.getNationalCurrencyCode();
    final crossCurrency = from.currencyCode != to.currencyCode;

    // The manual rate field is "1 base = X". When the source is the base
    // currency the dest is the rate target; otherwise it's the source.
    final rateCurrency = crossCurrency && from.currencyCode != baseCode
        ? from.currencyCode
        : to.currencyCode;

    double? executionRate;
    if (crossCurrency) {
      executionRate = await _repo.effectiveRate(rateCurrency, at: date);
      if (manualRate != null && manualRate > 0) executionRate = manualRate;
    }

    // Per-leg rates: the execution rate goes to the rate-target leg, the other
    // non-base leg (if any) converts at its own stored rate.
    double? srcRate;
    double? dstRate;
    if (crossCurrency) {
      srcRate = from.currencyCode == rateCurrency
          ? executionRate
          : await _repo.getRateWithFallback(from.currencyCode, date);
      dstRate = to.currencyCode == rateCurrency
          ? executionRate
          : await _repo.getRateWithFallback(to.currencyCode, date);
      if (from.currencyCode == baseCode) srcRate = null;
      if (to.currencyCode == baseCode) dstRate = null;
    }

    final srcInBase = from.currencyCode == baseCode
        ? amount
        : (srcRate != null && srcRate > 0 ? amount / srcRate : amount);
    final dstAmount = to.currencyCode == from.currencyCode
        ? amount
        : to.currencyCode == baseCode
            ? srcInBase
            : (dstRate != null && dstRate > 0
                ? srcInBase * dstRate
                : srcInBase);
    final dstInBase = to.currencyCode == baseCode
        ? dstAmount
        : (dstRate != null && dstRate > 0 ? dstAmount / dstRate : srcInBase);

    double? fromFx;
    double? toFx;
    if (from.currencyCode == nationalCode && from.currencyCode != baseCode) {
      final bcv = await _repo.getRateWithFallback(nationalCode, date);
      if (bcv != null && bcv > 0 && srcRate != null && srcRate > 0) {
        fromFx =
            fxDeltaUsdt(amountVes: -amount, bcvRate: bcv, marketRate: srcRate);
      }
    }
    if (to.currencyCode == nationalCode && to.currencyCode != baseCode) {
      final bcv = await _repo.getRateWithFallback(nationalCode, date);
      if (bcv != null && bcv > 0 && dstRate != null && dstRate > 0) {
        toFx = fxDeltaUsdt(
            amountVes: dstAmount, bcvRate: bcv, marketRate: dstRate);
      }
    }

    return TransferLegs(
      fromLeg: db.TransactionsCompanion(
        amount: Value(-amount),
        accountId: Value(from.id),
        currencyCode: Value(from.currencyCode),
        reference: Value(reference),
        date: Value(date),
        exchangeRateAtCreation: Value(srcRate),
        // The source leg is negative, so its base value must be negative too —
        // otherwise revaluation cost basis reads the outflow as an inflow.
        baseCurrencyAmount: Value(-srcInBase),
        fxDelta: Value(fromFx),
      ),
      toLeg: db.TransactionsCompanion(
        amount: Value(dstAmount),
        accountId: Value(to.id),
        currencyCode: Value(to.currencyCode),
        reference: Value(reference),
        date: Value(date),
        exchangeRateAtCreation: Value(dstRate),
        baseCurrencyAmount: Value(dstInBase),
        fxDelta: Value(toFx),
      ),
    );
  }
}
