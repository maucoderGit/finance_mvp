import 'package:flutter/foundation.dart';

/// A single point on the net worth or purchasing power chart.
@immutable
class NetWorthDataPoint {
  final DateTime date;

  /// Net worth in the base currency.
  final double baseAmount;

  /// Net worth in the national currency.
  final double nationalAmount;

  const NetWorthDataPoint({
    required this.date,
    required this.baseAmount,
    required this.nationalAmount,
  });
}

/// A single point of purchasing power evolution for a currency.
@immutable
class PowerDataPoint {
  final DateTime date;

  /// Exchange rate: how many units of the national currency buy 1 base unit.
  final double rate;

  /// Value of 1 unit of national currency expressed in base currency.
  final double valueInBase;

  /// Cumulative change in purchasing power vs the first point, as a fraction.
  /// e.g. -0.5 means the national currency has lost 50% of its value
  /// relative to base currency since the start of the series.
  final double cumulativeChange;

  const PowerDataPoint({
    required this.date,
    required this.rate,
    required this.valueInBase,
    required this.cumulativeChange,
  });
}

/// Aggregated chart data for the revaluation dashboard.
@immutable
class RevaluationChartData {
  final List<NetWorthDataPoint> netWorthHistory;
  final List<PowerDataPoint> purchasingPowerHistory;

  const RevaluationChartData({
    this.netWorthHistory = const [],
    this.purchasingPowerHistory = const [],
  });
}