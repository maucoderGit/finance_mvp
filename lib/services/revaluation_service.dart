import 'package:drift/drift.dart';
import 'package:finance_mvp/database/app_database.dart';
import 'package:finance_mvp/models/gain_loss.dart';
import 'package:finance_mvp/models/net_worth_data_point.dart';
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/services/currency_converter.dart';

/// Core engine for currency de/revaluation calculations.
///
/// Provides:
/// - Unrealized FX gain/loss per account and per currency
/// - Purchasing power erosion of the national currency vs the base currency
/// - Daily net worth snapshots
class RevaluationService {
  final FinanceRepository _repository;
  final CurrencyConverter _converter;

  RevaluationService(this._repository)
      : _converter = CurrencyConverter(_repository);

  /// Compute unrealized FX gain/loss for all accounts.
  ///
  /// Cost basis is computed from each transaction's recorded exchange rate at
  /// creation (`exchangeRateAtCreation`), falling back to the stored rate on
  /// that date when missing. Current value uses the latest stored rate.
  Future<List<GainLossResult>> getUnrealizedGainLossByAccount({
    bool includeExcluded = false,
  }) async {
    final accounts = await _repository.getAllAccounts();
    final allTransactions = await _repository.watchTransactions().first;

    final results = <GainLossResult>[];

    for (final account in accounts) {
      if (!account.includeInRevaluation && !includeExcluded) continue;

      final accountTxs =
          allTransactions.where((t) => t.accountId == account.id).toList();

      final balance = accountTxs.fold<double>(0.0, (s, t) => s + t.amount);

      if (balance == 0) continue;

      // Cost basis in base currency.
      var costBasis = 0.0;
      for (final tx in accountTxs) {
        if (tx.baseCurrencyAmount != null) {
          costBasis += tx.baseCurrencyAmount!;
        } else {
          final rate = tx.exchangeRateAtCreation ??
              (await _repository.getRateAtDate(account.currencyCode, tx.date))
                  ?.rate;
          if (rate != null && rate != 0) {
            costBasis += tx.amount / rate;
          } else {
            // No rate available at creation; fall back to current rate.
            costBasis += await _converter.toBase(tx.amount, account.currencyCode);
          }
        }
      }

      // Current value in base currency.
      final currentValue =
          await _converter.toBase(balance, account.currencyCode);

      final gainLoss = currentValue - costBasis;
      final percent =
          costBasis != 0 ? (gainLoss / costBasis) * 100 : 0.0;

      results.add(GainLossResult(
        accountId: account.id,
        accountName: account.name,
        currencyCode: account.currencyCode,
        balanceInNativeCurrency: balance,
        costBasisInBase: costBasis,
        currentValueInBase: currentValue,
        unrealizedGainLoss: gainLoss,
        percentChange: percent,
      ));
    }

    results.sort((a, b) => b.unrealizedGainLoss.abs().compareTo(a.unrealizedGainLoss.abs()));
    return results;
  }

  /// Compute unrealized FX gain/loss aggregated by currency across accounts.
  Future<List<CurrencyGainLoss>> getUnrealizedGainLossByCurrency() async {
    final byAccount = await getUnrealizedGainLossByAccount();

    final grouped = <String, List<GainLossResult>>{};
    for (final result in byAccount) {
      grouped.putIfAbsent(result.currencyCode, () => []).add(result);
    }

    return grouped.entries.map((entry) {
      final results = entry.value;
      final costBasis = results.fold<double>(0, (s, r) => s + r.costBasisInBase);
      final currentValue =
          results.fold<double>(0, (s, r) => s + r.currentValueInBase);
      final gainLoss = currentValue - costBasis;

      return CurrencyGainLoss(
        currencyCode: entry.key,
        totalBalanceNative:
            results.fold<double>(0, (s, r) => s + r.balanceInNativeCurrency),
        costBasisInBase: costBasis,
        currentValueInBase: currentValue,
        unrealizedGainLoss: gainLoss,
        percentChange: costBasis != 0 ? (gainLoss / costBasis) * 100 : 0.0,
      );
    }).toList()
      ..sort((a, b) => b.unrealizedGainLoss.abs().compareTo(a.unrealizedGainLoss.abs()));
  }

  /// Build a full summary of the revaluation situation.
  Future<RevaluationSummary> getRevaluationSummary(
      {String? nationalCurrencyCode}) async {
    final baseCode = await _repository.getBaseCurrencyCode();
    final nationalCode = nationalCurrencyCode ?? 'VES';

    final byAccount = await getUnrealizedGainLossByAccount();

    final totalValue = byAccount.fold<double>(0, (s, r) => s + r.currentValueInBase);
    final totalCostBasis = byAccount.fold<double>(0, (s, r) => s + r.costBasisInBase);
    final totalGainLoss = totalValue - totalCostBasis;

    final currentRate = nationalCode == baseCode
        ? 1.0
        : (await _repository.getLatestRate(nationalCode))?.rate;

    double? rateOneYearAgo;
    final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
    if (nationalCode != baseCode) {
      rateOneYearAgo = (await _repository.getRateAtDate(nationalCode, oneYearAgo))?.rate;
    }

    double? erosionPercent;
    if (currentRate != null && rateOneYearAgo != null && rateOneYearAgo != 0 && nationalCode != baseCode) {
      // A larger rate means the national currency is weaker.
      erosionPercent = ((currentRate / rateOneYearAgo) - 1) * 100;
    }

    return RevaluationSummary(
      totalValueInBase: totalValue,
      totalCostBasisInBase: totalCostBasis,
      totalUnrealizedGainLoss: totalGainLoss,
      nationalCurrencyCode: nationalCode,
      nationalCurrencyRate: currentRate,
      nationalCurrencyRateOneYearAgo: rateOneYearAgo,
      purchasingPowerChangePercent: erosionPercent,
    );
  }

  /// Purchasing power evolution of [currencyCode] vs base currency over
  /// the last [months]. Each point shows how much 1 unit of the monitored
  /// currency is worth in base currency and the cumulative change.
  Future<List<PowerDataPoint>> getPurchasingPowerHistory(
      String currencyCode, {int months = 12}) async {
    final baseCode = await _repository.getBaseCurrencyCode();
    if (currencyCode == baseCode) return [];

    final end = DateTime.now();
    final start = DateTime(end.year, end.month - months, end.day);

    final rates = await _repository.getRatesForCurrency(currencyCode);
    final filtered =
        rates.where((r) => !r.date.isBefore(start)).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    if (filtered.isEmpty) return [];

    final initialValue = 1 / filtered.first.rate;
    return filtered.map((rate) {
      final valueInBase = 1 / rate.rate;
      return PowerDataPoint(
        date: rate.date,
        rate: rate.rate,
        valueInBase: valueInBase,
        cumulativeChange: initialValue != 0 ? (valueInBase / initialValue) - 1 : 0,
      );
    }).toList();
  }

  /// Record a daily net worth snapshot in base and national currency.
  Future<void> recordDailyNetWorth({String? nationalCurrencyCode}) async {
    final baseCode = await _repository.getBaseCurrencyCode();
    final nationalCode = nationalCurrencyCode ?? 'VES';

    final totalInBase = await _repository.calculateTotalBalance(baseCode);
    final totalInNational =
        nationalCode == baseCode ? totalInBase : await _repository.calculateTotalBalance(nationalCode);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await _repository.addNetWorthSnapshot(NetWorthHistoryCompanion(
      date: Value(today),
      totalInBaseCurrency: Value(totalInBase),
      totalInNationalCurrency: Value(totalInNational),
    ));
  }

  /// Historical net worth for charting (oldest first).
  Future<List<NetWorthDataPoint>> getNetWorthHistory({int limit = 90}) async {
    final history = await _repository.watchNetWorthHistory(limit: limit).first;
    return history
        .map((h) => NetWorthDataPoint(
              date: h.date,
              baseAmount: h.totalInBaseCurrency,
              nationalAmount: h.totalInNationalCurrency,
            ))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Snapshot the current state of all exchange rates vs the base currency
  /// into the `ExchangeRateSnapshots` table for historical reference.
  Future<void> snapshotAllRates(String source) async {
    final baseCode = await _repository.getBaseCurrencyCode();
    final currencies = await _repository.getAllCurrencies();
    final rates = <String, double>{};

    for (final currency in currencies) {
      if (currency.code == baseCode) {
        rates[currency.code] = 1.0;
        continue;
      }
      final latest = await _repository.getLatestRate(currency.code);
      if (latest != null) {
        rates[currency.code] = latest.rate;
      }
    }

    if (rates.isEmpty) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await _repository.addRateSnapshot(ExchangeRateSnapshotsCompanion(
      date: Value(today),
      ratesJson: Value(_jsonEncodeRates(rates)),
      source: Value(source),
    ));
  }

  String _jsonEncodeRates(Map<String, double> rates) {
    if (rates.isEmpty) return '{}';
    return '{${rates.entries.map((e) => '"${e.key}":${e.value}').join(',')}}';
  }
}