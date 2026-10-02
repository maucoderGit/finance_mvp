import 'package:fl_chart/fl_chart.dart';
import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/services/finance/currency_converter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Money in or out over time, in the base currency.
///
/// The series is [data] as bucketed by [FinanceRepository.watchCashFlow], which
/// always returns one point per bucket — so a period with no spending draws a
/// point at zero instead of being left out of the line.
class CashFlowChart extends StatelessWidget {
  final List<CashFlowPoint> data;

  /// Plots [CashFlowPoint.income] when true, [CashFlowPoint.expenses] when not.
  final bool showIncome;

  final CashFlowBucket bucket;
  final String currencyCode;

  const CashFlowChart({
    super.key,
    required this.data,
    required this.showIncome,
    required this.bucket,
    required this.currencyCode,
  });

  static const _incomeColor = Color(0xFF1E8E3E);
  static const _spendingColor = Color(0xFFB3261E);

  @override
  Widget build(BuildContext context) {
    final color = showIncome ? _incomeColor : _spendingColor;
    final values = [
      for (final p in data) showIncome ? p.income : p.expenses,
    ];
    final total = values.fold<double>(0, (sum, v) => sum + v);
    final maxValue = values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
    final labelFormat = _labelFormat(bucket);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Icon(showIncome ? Icons.trending_up : Icons.trending_down,
                color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                formatMoney(total, currencyCode: currencyCode),
                style: TextStyle(
                  color: context.colors.textDark,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${showIncome ? 'Income' : 'Spending'} · ${bucket.windowLabel.toLowerCase()}',
          style: TextStyle(color: context.colors.textLight, fontSize: 13),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: LineChart(
            LineChartData(
              // Anchored at zero: a cash-flow axis that doesn't include zero
              // overstates every swing on it. 1 is the ceiling for an
              // all-zero series, which is what a ledger with no transactions in
              // the window produces.
              minY: 0,
              maxY: maxValue == 0 ? 1 : maxValue * 1.15,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: context.colors.textLight.withValues(alpha: 0.15),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: _labelInterval(data.length),
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= data.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          labelFormat.format(data[index].date),
                          style: TextStyle(
                              color: context.colors.textLight, fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < values.length; i++)
                      FlSpot(i.toDouble(), values[i]),
                  ],
                  isCurved: true,
                  color: color,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: color.withValues(alpha: 0.12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Only as many axis labels as fit without touching.
  static double _labelInterval(int count) {
    if (count <= 6) return 1;
    if (count <= 12) return 2;
    return (count / 6).ceilToDouble();
  }

  /// Weeks span month boundaries, so they need the month too; a year only needs
  /// the year.
  static DateFormat _labelFormat(CashFlowBucket bucket) => switch (bucket) {
        CashFlowBucket.day => DateFormat('d'),
        CashFlowBucket.week => DateFormat('MMM d'),
        CashFlowBucket.month => DateFormat('MMM'),
        CashFlowBucket.year => DateFormat('yyyy'),
      };
}