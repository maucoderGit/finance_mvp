import 'package:flutter/material.dart';
import 'package:finance_mvp/models/gain_loss.dart';
import 'package:finance_mvp/services/finance/currency_converter.dart';

/// Card displaying the gain/loss for a single account or currency.
class GainLossCard extends StatelessWidget {
  final String currencyCode;
  final String title;
  final double balanceNative;
  final double currentValueInBase;
  final double gainLoss;
  final double percentChange;

  const GainLossCard({
    super.key,
    required this.currencyCode,
    required this.title,
    required this.balanceNative,
    required this.currentValueInBase,
    required this.gainLoss,
    required this.percentChange,
  });

  factory GainLossCard.fromCurrency(CurrencyGainLoss data) => GainLossCard(
        currencyCode: data.currencyCode,
        title: data.currencyCode,
        balanceNative: data.totalBalanceNative,
        currentValueInBase: data.currentValueInBase,
        gainLoss: data.unrealizedGainLoss,
        percentChange: data.percentChange,
      );

  factory GainLossCard.fromAccount(GainLossResult data) => GainLossCard(
        currencyCode: data.currencyCode,
        title: data.accountName,
        balanceNative: data.balanceInNativeCurrency,
        currentValueInBase: data.currentValueInBase,
        gainLoss: data.unrealizedGainLoss,
        percentChange: data.percentChange,
      );

  bool get isGain => gainLoss >= 0;

  @override
  Widget build(BuildContext context) {
    final color = isGain ? const Color(0xFF1E8E3E) : const Color(0xFFD93025);
    final bg = color.withValues(alpha: 0.08);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  currencyCode,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatMoney(balanceNative, currencyCode: currencyCode),
            style: TextStyle(
                fontSize: 14, color: Colors.grey.shade600, height: 1.2),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Value now',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          letterSpacing: 0.4),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatMoney(currentValueInBase),
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isGain ? 'Gain' : 'Loss',
                    style: TextStyle(
                        fontSize: 12,
                        color: color,
                        letterSpacing: 0.4,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${isGain ? '+' : '-'}${formatMoney(gainLoss.abs())} '
                    '(${percentChange.toStringAsFixed(1)}%)',
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}