/// A pluggable source of exchange rates. Implementations fetch real-time
/// rates ("1 [base] = N [quote]") from a specific provider.
abstract class RateSource {
  /// Whether [currencyCode] can be served as a quote currency.
  bool isSupported(String currencyCode);

  /// Latest rates for [quotes] against [base], keyed by quote code.
  ///
  /// Return an empty map when this source does not cover the pair (e.g. a
  /// national-bank source that only publishes USD-based rates). Throws on
  /// transport/API errors so callers can fall back to another source.
  Future<Map<String, double>> fetchLatestRates({
    required String base,
    required List<String> quotes,
  });

  /// How many business days of history the source provides (0 = latest only).
  int get historyDays;

  void dispose();
}