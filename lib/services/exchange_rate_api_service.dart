import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'rate_source.dart';

class ExchangeRateApiException implements Exception {
  final String message;
  ExchangeRateApiException(this.message);

  @override
  String toString() => message;
}

/// Client for the free Frankfurter exchange rates API.
/// No API key required. Supports 201 currencies with history back to 1948.
///
/// Docs: https://www.frankfurter.dev/docs/
class ExchangeRateApiService implements RateSource {
  final http.Client _client;
  final Duration timeout;

  static const String _baseUrl = 'https://api.frankfurter.dev/v2';

  /// Currencies the API is known not to cover reliably (Venezuelan bolivar).
  static const Set<String> _unsupportedCodes = {
    'VES', // Venezuelan bolivar — API coverage is unreliable
    'VEF', // Old Venezuelan bolivar (pre-2021 redenomination)
  };

  ExchangeRateApiService({http.Client? client, this.timeout = const Duration(seconds: 15)})
      : _client = client ?? http.Client();

  @override
  bool isSupported(String currencyCode) =>
      !_unsupportedCodes.contains(currencyCode.toUpperCase());

  @override
  int get historyDays => 365;

  /// Fetch the latest exchange rate between [base] and [quote].
  /// Returns how many units of [quote] buy 1 unit of [base].
  Future<double> fetchLatestRate({
    required String base,
    required String quote,
  }) async {
    final uri = Uri.parse('$_baseUrl/rates')
        .replace(queryParameters: {'base': base, 'quotes': quote});

    final response = await _get(uri);
    return _extractRate(response, quote);
  }

  /// Fetch the exchange rate between [base] and [quote] on a specific [date].
  Future<double> fetchHistoricalRate({
    required String base,
    required String quote,
    required DateTime date,
  }) async {
    final dateStr = _formatDate(date);
    final uri = Uri.parse('$_baseUrl/rates')
        .replace(queryParameters: {'date': dateStr, 'base': base, 'quotes': quote});

    final response = await _get(uri);
    return _extractRate(response, quote);
  }

  /// Fetch a time series of rates between [base] and each quote in [quotes]
  /// over the range [from]–[to].
  ///
  /// Returns a map of date → (quoteCode → rate).
  Future<Map<String, Map<String, double>>> fetchTimeSeries({
    required String base,
    required List<String> quotes,
    required DateTime from,
    required DateTime to,
  }) async {
    final uri = Uri.parse('$_baseUrl/rates').replace(queryParameters: {
      'base': base,
      'quotes': quotes.join(','),
      'from': _formatDate(from),
      'to': _formatDate(to),
    });

    final response = await _get(uri);
    return _parseTimeSeries(response, quotes);
  }

  /// Fetch the latest rate as a map of quote → rate for a list of quotes.
  @override
  Future<Map<String, double>> fetchLatestRates({
    required String base,
    required List<String> quotes,
  }) async {
    final uri = Uri.parse('$_baseUrl/rates')
        .replace(queryParameters: {'base': base, 'quotes': quotes.join(',')});

    final response = await _get(uri);
    return _parseRates(response, quotes);
  }

  /// Check whether the API currently lists [currencyCode].
  Future<bool> isCurrencyAvailable(String currencyCode) async {
    if (!isSupported(currencyCode)) return false;
    try {
      final uri = Uri.parse('$_baseUrl/currencies?scope=all');
      final response = await _get(uri);
      final data = jsonDecode(response) as Map<String, dynamic>;
      return data.containsKey(currencyCode.toUpperCase());
    } on ExchangeRateApiException {
      return false;
    }
  }

  /// Fetch historical daily rates for [quotes] vs [base] back to [daysBack].
  Future<Map<String, Map<String, double>>> fetchHistoryForLastNDays({
    required String base,
    required List<String> quotes,
    required int daysBack,
    DateTime? upTo,
  }) async {
    final end = upTo ?? DateTime.now();
    final start = end.subtract(Duration(days: daysBack));
    return fetchTimeSeries(base: base, quotes: quotes, from: start, to: end);
  }

  // ── Internals ──

  Future<String> _get(Uri uri) async {
    try {
      final response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw ExchangeRateApiException(
            'API error ${response.statusCode}: ${response.body}');
      }
      return response.body;
    } on TimeoutException {
      throw ExchangeRateApiException('Request timed out');
    } on http.ClientException catch (e) {
      throw ExchangeRateApiException('Network error: ${e.message}');
    }
  }

  double _extractRate(String body, String quote) {
    final data = jsonDecode(body) as Map<String, dynamic>;
    final rates = data['rates'];
    if (rates is! Map) {
      throw ExchangeRateApiException('Malformed API response');
    }
    final rate = rates[quote.toUpperCase()];
    if (rate is! num) {
      throw ExchangeRateApiException('Rate not available for $quote');
    }
    return rate.toDouble();
  }

  Map<String, double> _parseRates(String body, List<String> quotes) {
    final data = jsonDecode(body) as Map<String, dynamic>;
    final rates = data['rates'];
    if (rates is! Map) {
      throw ExchangeRateApiException('Malformed API response');
    }
    return {
      for (final quote in quotes)
        quote.toUpperCase(): (rates[quote.toUpperCase()] as num).toDouble(),
    };
  }

  Map<String, Map<String, double>> _parseTimeSeries(
      String body, List<String> quotes) {
    final data = jsonDecode(body) as Map<String, dynamic>;
    final series = data['rates'];
    if (series is! Map) {
      throw ExchangeRateApiException('Malformed time series response');
    }

    final result = <String, Map<String, double>>{};
    series.forEach((date, value) {
      if (value is Map) {
        result[date] = {
          for (final quote in quotes)
            quote.toUpperCase(): (value[quote.toUpperCase()] as num?)?.toDouble() ?? 0,
        };
      }
    });
    return result;
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Fetch available currencies from the API.
  Future<Map<String, String>> fetchCurrencies() async {
    final uri = Uri.parse('$_baseUrl/currencies?scope=all');
    final body = await _get(uri);
    final data = jsonDecode(body) as Map<String, dynamic>;
    return {
      for (final entry in data.entries)
        entry.key: (entry.value as Map?)?['name']?.toString() ?? entry.key,
    };
  }

  @override
  void dispose() {
    _client.close();
  }
}