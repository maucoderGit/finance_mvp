import 'package:flutter/material.dart';
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/services/finance/currency_converter.dart';
import 'package:intl/intl.dart';

/// One savings goal with live progress.
///
/// Every number here is derived from the goal's backing account, so the card
/// cannot disagree with the ledger. [projectedOn] is passed in rather than
/// fetched because the projection is a per-goal async query and a list of
/// cards shouldn't fire one each.
///
/// A null [projectedOn] is ambiguous — it could mean "nothing backs a date" or
/// "nobody asked" — so [showProjection] decides whether the line appears at
/// all. Guessing wrong there would state something false.
class GoalProgressCard extends StatelessWidget {
  final GoalProgress goal;

  /// Month the goal looks likely to be reached, or null when nothing backs one.
  final DateTime? projectedOn;

  final bool showProjection;

  /// Shown under the title so the pot is findable: this is where the money
  /// lives, and the app has no separate "add to goal" flow — a transfer into
  /// this account is how a goal gets funded.
  final bool showAccountName;

  const GoalProgressCard({
    super.key,
    required this.goal,
    this.projectedOn,
    this.showProjection = true,
    this.showAccountName = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(goal.goal.iconColor);
    final currency = goal.goal.currencyCode;
    final percent = (goal.progress * 100).round();

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
            children: [
              Icon(goalIconDataFor(goal.goal.icon), color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  goal.goal.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${formatMoney(goal.current, currencyCode: currency)}'
            ' of ${formatMoney(goal.goal.targetAmount, currencyCode: currency)}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 12),
          // Clamped: the bar stops at full, but the text above still reports a
          // real over-funded percentage.
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: goal.progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 10),
          if (showAccountName) _footnote('Held in ${goal.account.name}'),
          if (showProjection && projectedOn != null)
            _footnote('On track for ${DateFormat.yMMM().format(projectedOn!)}'),
          if (showProjection && projectedOn == null && !goal.isReached)
            _footnote('Not saving enough yet to project a date'),
        ],
      ),
    );
  }

  Widget _footnote(String text) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          text,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      );
}

/// The goals a user can pick an icon from. One list, so the form's picker and
/// the card's renderer can't drift apart — a stored icon nothing can render is
/// how the dormant `contact` column happened in the first place.
const List<({String icon, int color})> goalIconOptions = [
  (icon: 'flag', color: 0xFF1E8E3E),
  (icon: 'flight', color: 0xFF2196F3),
  (icon: 'home', color: 0xFFFF9800),
  (icon: 'school', color: 0xFF9C27B0),
  (icon: 'directions_car', color: 0xFFE91E63),
  (icon: 'card_giftcard', color: 0xFF673AB7),
];

/// Unknown slugs fall back to a flag rather than crashing — a goal saved by a
/// future version must still render in this one.
IconData goalIconDataFor(String icon) => switch (icon) {
      'flight' => Icons.flight,
      'home' => Icons.home,
      'school' => Icons.school,
      'directions_car' => Icons.directions_car,
      'card_giftcard' => Icons.card_giftcard,
      _ => Icons.flag,
    };