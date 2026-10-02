import 'dart:ui' show PlatformDispatcher;

import 'package:intl/intl.dart';

/// Snaps [amount] to [digits] decimal places — the minor unit of the currency
/// it is denominated in. Money is carried as `double` and every division by an
/// exchange rate leaves residue (100 VES at 36.5 is 2.7397260273972603), which
/// accumulates in sums and makes "is this debt paid?" comparisons unreliable.
/// Round at the boundaries instead of trusting the float.
///
/// This is arithmetic precision, not display: [formatMoney] deliberately keeps
/// the phone locale's separators and its own digit count.
double quantizeTo(double amount, int digits) {
  if (!amount.isFinite || digits < 0) return amount;
  final factor = _pow10[digits.clamp(0, _pow10.length - 1)];
  return (amount * factor).round() / factor;
}

/// 10^0 … 10^15, so the common scales (0, 2, 3, 8) are exact and the clamp
/// above never has to compute a power at runtime.
const _pow10 = <double>[
  1e0, 1e1, 1e2, 1e3, 1e4, 1e5, 1e6, 1e7, //
  1e8, 1e9, 1e10, 1e11, 1e12, 1e13, 1e14, 1e15,
];

/// Formats [amount] with the phone locale's group/decimal separators, so
/// 1234.50 reads "1.234,50" in es-VE but "1,234.50" in en-US. Prepend
/// [currencyCode] (e.g. "VES") and/or override the [symbol] to customize.
String formatMoney(
  double amount, {
  String? currencyCode,
  String? symbol,
  String? locale,
  int decimalDigits = 2,
}) {
  final activeLocale = locale ?? PlatformDispatcher.instance.locale.toString();
  final formatted = NumberFormat.currency(
    locale: activeLocale,
    symbol: symbol ?? '',
    decimalDigits: decimalDigits,
  ).format(amount);
  return currencyCode == null ? formatted : '$formatted $currencyCode';
}
