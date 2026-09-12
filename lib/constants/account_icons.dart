import 'package:flutter/material.dart';

const List<String> accountTypeLabels = [
  'Cash',
  'Bank',
  'Savings',
  'Investment',
  'Credit Card',
  'Crypto Wallet',
];

const Map<String, IconData> accountTypeIcons = {
  'cash': Icons.wallet,
  'bank': Icons.account_balance,
  'savings': Icons.savings,
  'investment': Icons.show_chart,
  'credit_card': Icons.credit_card,
  'crypto_wallet': Icons.currency_bitcoin,
};

/// Default accent color per account type (matching accountTypeIcons).
const Map<String, int> accountTypeColors = {
  'cash': 0xFF4CAF50,
  'bank': 0xFF2196F3,
  'savings': 0xFFFF9800,
  'investment': 0xFF9C27B0,
  'credit_card': 0xFFE91E63,
  'crypto_wallet': 0xFF673AB7,
};

String accountIconSlug(String label) =>
    label.toLowerCase().replaceAll(' ', '_');

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
