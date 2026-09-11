import 'package:flutter/material.dart';

const List<String> accountTypeLabels = [
  'Cash',
  'Bank',
  'Savings',
  'Investment',
  'Credit Card',
];

const Map<String, IconData> accountTypeIcons = {
  'cash': Icons.wallet,
  'bank': Icons.account_balance,
  'savings': Icons.savings,
  'investment': Icons.show_chart,
  'credit_card': Icons.credit_card,
};

String accountIconSlug(String label) => label.toLowerCase().replaceAll(' ', '_');

IconData accountIconFor(String stored) {
  if (stored.isEmpty) return Icons.account_balance;
  final icon = accountTypeIcons[stored];
  if (icon != null) return icon;
  final parsed = int.tryParse(stored);
  if (parsed != null) {
    for (final value in accountTypeIcons.values) {
      if (value.codePoint == parsed) return value;
    }
  }
  return Icons.account_balance;
}