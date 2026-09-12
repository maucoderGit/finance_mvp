import 'package:flutter/material.dart';
import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/services/currency_converter.dart';

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
    final currency = formatMoney(totalUnrealizedGainLoss);
    final isGain = totalUnrealizedGainLoss >= 0;
    final percent = totalCostBasisInBase != 0
        ? (totalUnrealizedGainLoss / totalCostBasisInBase) * 100
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.primaryLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC3C8C1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL UNREALIZED',
            style: TextStyle(
              color: context.colors.textLight,
              fontSize: 12,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${isGain ? '+' : ''}$currency $baseCurrencyCode',
            style: TextStyle(
              color: isGain ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
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
                color: isGain ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                '${percent.toStringAsFixed(1)}% vs cost basis (${formatMoney(totalCostBasisInBase, currencyCode: baseCurrencyCode)})',
                style: TextStyle(color: context.colors.textLight, fontSize: 13),
              ),
            ],
          ),
          if (inflationPercent != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.colors.primaryLight.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department,
                      color: Color(0xFFE57373), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'In 12 months, $nationalCurrencyCode devalued '
                      '${inflationPercent!.toStringAsFixed(1)}% vs ${baseCurrencyCode == 'USD' ? 'USD' : baseCurrencyCode}',
                      style: TextStyle(
                          color: context.colors.textDark, fontSize: 13, height: 1.3),
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