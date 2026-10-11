import 'package:finance_mvp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Canonical, stable account-type slugs. These are what gets persisted, so
/// they must never be localized; display names come from [accountTypeLabel].
const List<String> accountTypeSlugs = [
  'cash',
  'bank',
  'savings',
  'investment',
  'credit_card',
  'crypto_wallet',
];

String accountTypeLabel(AppLocalizations l10n, String slug) => switch (slug) {
      'cash' => l10n.accountTypeCash,
      'bank' => l10n.accountTypeBank,
      'savings' => l10n.accountTypeSavings,
      'investment' => l10n.accountTypeInvestment,
      'credit_card' => l10n.accountTypeCreditCard,
      'crypto_wallet' => l10n.accountTypeCryptoWallet,
      _ => slug,
    };

/// Resolves any stored account "type" (a canonical slug, an icon code point, or
/// a legacy English label) to a canonical slug, so display can be localized
/// without depending on what was persisted.
String accountSlugFromStored(String? stored) {
  if (stored == null || stored.isEmpty) return 'bank';
  if (accountTypeIcons.containsKey(stored)) return stored;
  const legacy = {
    'Cash': 'cash',
    'Bank': 'bank',
    'Savings': 'savings',
    'Investment': 'investment',
    'Credit Card': 'credit_card',
    'Crypto Wallet': 'crypto_wallet',
  };
  final mapped = legacy[stored];
  if (mapped != null) return mapped;
  final parsed = int.tryParse(stored);
  if (parsed != null) {
    for (final entry in accountTypeIcons.entries) {
      if (entry.value.codePoint == parsed) return entry.key;
    }
  }
  return 'bank';
}

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
