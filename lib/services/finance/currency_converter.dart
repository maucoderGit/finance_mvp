import 'dart:ui' show PlatformDispatcher;

import 'package:intl/intl.dart';

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
