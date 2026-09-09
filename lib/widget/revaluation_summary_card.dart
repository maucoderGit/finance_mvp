import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finance_mvp/constants/app_colors.dart';

/// Summary card showing total value, cost basis, and unrealized gain/loss.
class RevaluationSummaryCard extends StatelessWidget {
  final double totalValueInBase;
  final double totalCostBasisInBase;
  final double totalUnrealizedGainLoss;
  final String baseCurrencyCode;
  final double? inflationPercent;
  final String nationalCurrencyCode;

  const RevaluationSummaryCard({
    super.key,
    required this.totalValueInBase,
    required this.totalCostBasisInBase,
    required this.totalUnrealizedGainLoss,
    required this.baseCurrencyCode,
    this.inflationPercent,
    this.nationalCurrencyCode = 'VES',
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '', decimalDigits: 2)
        .format(totalUnrealizedGainLoss);
    final isGain = totalUnrealizedGainLoss >= 0;
    final percent = totalCostBasisInBase != 0
        ? (totalUnrealizedGainLoss / totalCostBasisInBase) * 100
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF1E6B34)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL UNREALIZED',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${isGain ? '+' : ''}$currency $baseCurrencyCode',
            style: TextStyle(
              color: isGain ? const Color(0xFFB9F6CA) : const Color(0xFFFFCDD2),
              fontSize: 34,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isGain ? Icons.trending_up : Icons.trending_down,
                color: isGain ? const Color(0xFFB9F6CA) : const Color(0xFFFFCDD2),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                '${percent.toStringAsFixed(1)}% vs cost basis (${totalCostBasisInBase.toStringAsFixed(2)} $baseCurrencyCode)',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          if (inflationPercent != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department,
                      color: Color(0xFFFF8A80), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'In 12 months, $nationalCurrencyCode devalued '
                      '${inflationPercent!.toStringAsFixed(1)}% vs ${baseCurrencyCode == 'USD' ? 'USD' : baseCurrencyCode}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}