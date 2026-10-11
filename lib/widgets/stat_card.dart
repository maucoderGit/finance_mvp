import 'package:finance_mvp/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// A labelled money figure, e.g. this month's Income or Expenses. Shared by the
/// home summary and the dashboard so the two can't drift apart.
class StatCard extends StatelessWidget {
  final String label;
  final String amount;
  final Color amountColor;
  final VoidCallback onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.amount,
    required this.amountColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.stackCardBackground[0],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.cardBorder),
        ),
        child: Column(
          children: [
            Text(label.toUpperCase(),
                style: TextStyle(
                    fontSize: 12,
                    color: context.colors.textLight,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(amount,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: amountColor)),
          ],
        ),
      ),
    );
  }
}
