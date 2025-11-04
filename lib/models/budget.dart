class Budget {
  final double currentBalance;
  final double netFlow;
  final double budgetRemaining;
  final double budgetSpent;
  final double budgetTotal;

  Budget({
    required this.currentBalance,
    required this.netFlow,
    required this.budgetRemaining,
    required this.budgetSpent,
    required this.budgetTotal,
  });
}

class Transaction {
  final String icon;
  final String title;
  final String date;
  final double amount;
  final bool isExpense;

  Transaction({
    required this.icon,
    required this.title,
    required this.date,
    required this.amount,
    required this.isExpense,
  });
}
