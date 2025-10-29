class Currency {
  final String name;
  final String code;
  final String symbol;
  final String separator; // e.g., "," for 1,000.00 or "." for 1.000,00
  final int decimalDigits; // e.g., 2 for 0.00

  Currency({
    required this.name,
    required this.code,
    required this.symbol,
    required this.separator,
    required this.decimalDigits,
  });
}
