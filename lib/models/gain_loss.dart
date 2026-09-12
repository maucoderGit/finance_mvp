import 'package:flutter/foundation.dart';

/// Result of unrealized FX gain/loss calculation for a single account.
@immutable
class GainLossResult {
  final int accountId;
  final String accountName;
  final String currencyCode;

  /// Balance in the account's own currency.
  final double balanceInNativeCurrency;

  /// Balance converted to the base currency at acquisition rates.
  final double costBasisInBase;

  /// Balance converted to base currency at current rates.
  final double currentValueInBase;

  /// Unrealized gain/loss = currentValueInBase - costBasisInBase.
  final double unrealizedGainLoss;

  /// Percentage change relative to cost basis (0 if cost basis is 0).
  final double percentChange;

  const GainLossResult({
    required this.accountId,
    required this.accountName,
    required this.currencyCode,
    required this.balanceInNativeCurrency,
    required this.costBasisInBase,
    required this.currentValueInBase,
    required this.unrealizedGainLoss,
    required this.percentChange,
  });

  bool get isGain => unrealizedGainLoss >= 0;
}

/// Gain/loss aggregated across all accounts holding a specific currency.
@immutable
class CurrencyGainLoss {
  final String currencyCode;
  final double totalBalanceNative;
  final double costBasisInBase;
  final double currentValueInBase;
  final double unrealizedGainLoss;
  final double percentChange;

  const CurrencyGainLoss({
    required this.currencyCode,
    required this.totalBalanceNative,
    required this.costBasisInBase,
    required this.currentValueInBase,
    required this.unrealizedGainLoss,
    required this.percentChange,
  });
}

/// Summary of total revaluation across all accounts.
@immutable
class RevaluationSummary {
  /// Total current value of all holdings in base currency.
  final double totalValueInBase;

  /// Total cost basis (what was paid) in base currency.
  final double totalCostBasisInBase;

  /// Sum of unrealized gains/losses across all holdings.
  final double totalUnrealizedGainLoss;

  /// National currency code (e.g. VES).
  final String nationalCurrencyCode;

  /// Latest rate of national currency vs base (units of national per 1 base).
  final double? nationalCurrencyRate;

  /// Rate one year ago, if available.
  final double? nationalCurrencyRateOneYearAgo;

  /// Purchasing power erosion of the national currency over the past year, in %.
  /// Positive value = national currency lost purchasing power vs base.
  final double? purchasingPowerChangePercent;

  const RevaluationSummary({
    required this.totalValueInBase,
    required this.totalCostBasisInBase,
    required this.totalUnrealizedGainLoss,
    required this.nationalCurrencyCode,
    this.nationalCurrencyRate,
    this.nationalCurrencyRateOneYearAgo,
    this.purchasingPowerChangePercent,
  });
}