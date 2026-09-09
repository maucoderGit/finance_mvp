import 'package:finance_mvp/repositories/finance_repository.dart';

/// Currency conversion utilities built on top of stored exchange rates.
///
/// Rules:
/// - Stored rates are expressed as "1 base currency = X units of currency",
///   i.e. the `rate` in the `CurrencyRates` row is how many local units
///   one base currency unit buys.
/// - To convert local → base: divide by the rate.
/// - To convert base → local: multiply by the rate.
class CurrencyConverter {
  final FinanceRepository _repository;

  CurrencyConverter(this._repository);

  /// Convert [amount] from [fromCode] to [toCode] using the latest stored rates.
  Future<double> convert({
    required double amount,
    required String fromCode,
    required String toCode,
  }) async {
    if (fromCode == toCode) return amount;
    return _repository.convertAmount(
      amount: amount,
      fromCode: fromCode,
      toCode: toCode,
    );
  }

  /// Convert [amount] using the stored rate closest to but not after [date].
  Future<double> convertAtDate({
    required double amount,
    required String fromCode,
    required String toCode,
    required DateTime date,
  }) async {
    if (fromCode == toCode) return amount;
    final baseCode = await _repository.getBaseCurrencyCode();

    if (toCode == baseCode) {
      final rate = await _repository.getRateAtDate(fromCode, date);
      return rate != null ? amount / rate.rate : amount;
    }
    if (fromCode == baseCode) {
      final rate = await _repository.getRateAtDate(toCode, date);
      return rate != null ? amount * rate.rate : amount;
    }

    final amountInBase = await convertAtDate(
      amount: amount,
      fromCode: fromCode,
      toCode: baseCode,
      date: date,
    );
    return convertAtDate(
      amount: amountInBase,
      fromCode: baseCode,
      toCode: toCode,
      date: date,
    );
  }

  /// Convert an amount of the [currencyCode] to the base currency.
  Future<double> toBase(double amount, String currencyCode) async =>
      convert(
          amount: amount,
          fromCode: currencyCode,
          toCode: await _repository.getBaseCurrencyCode());

  /// Convert an amount of base currency to [currencyCode].
  Future<double> fromBase(double amount, String currencyCode) async =>
      convert(
          amount: amount,
          fromCode: await _repository.getBaseCurrencyCode(),
          toCode: currencyCode);

  /// Format a number for display in a given currency.
  String formatAmount(double amount, String currencyCode) {
    return '$currencyCode ${amount.toStringAsFixed(2)}';
  }
}