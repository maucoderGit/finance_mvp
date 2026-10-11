import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finance_mvp/l10n/l10n.dart';
import 'package:finance_mvp/models/net_worth_data_point.dart';

/// Line chart of net worth over time in the base currency.
class NetWorthLineChart extends StatelessWidget {
  final List<NetWorthDataPoint> data;
  final String baseCurrencyCode;

  const NetWorthLineChart({
    super.key,
    required this.data,
    required this.baseCurrencyCode,
  });

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: [
            const Icon(Icons.show_chart, color: Colors.grey, size: 40),
            const SizedBox(height: 12),
            Text(
              context.l10n.netWorthEmpty,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final spots = <FlSpot>[
      for (var i = 0; i < data.length; i++)
        FlSpot(i.toDouble(), data[i].baseAmount),
    ];

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final range = (maxY - minY).abs();
    final paddingY = range == 0 ? 1.0 : range * 0.1;

    final minYForChart = minY - paddingY;
    final maxYForChart = maxY + paddingY;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: minYForChart,
                maxY: maxYForChart,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.15),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: _labelInterval(data.length),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= data.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('MMM d').format(data[index].date),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF1E8E3E),
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF1E8E3E).withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _labelInterval(int count) {
    if (count <= 6) return 1;
    if (count <= 12) return 2;
    return (count / 6).ceilToDouble();
  }
}