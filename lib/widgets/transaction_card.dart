import 'package:finance_mvp/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Period summary strip: a small label plus the net amount in the base
/// currency. The amount uses the theme's main text color, so it stays legible
/// on both palettes.
class TransactionCard extends StatelessWidget {
  final String title;
  final String displayAmount;

  const TransactionCard({
    super.key,
    required this.title,
    required this.displayAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: context.colors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.colors.textLight,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            displayAmount,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.colors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
