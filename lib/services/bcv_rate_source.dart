import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'exchange_rate_api_service.dart';
import 'rate_source.dart';

/// Official Banco Central de Venezuela (BCV) bolivar rate via the community
/// dolarapi.com wrapper. No API key required.
///
/// Endpoint: GET https://ve.dolarapi.com/v1/dolares/oficial
/// Returns the BCV official USD→VES rate in `promedio`. The BCV only
/// publishes a USD-based price, so this source only serves `VES` quotes for
/// a `USD` base.
class BcvRateSource implements RateSource {
  final http.Client _client;
  final Duration timeout;

  static const String _baseUrl =
      'https://ve.dolarapi.com/v1/dolares/oficial';

  static const String _quoteCode = 'VES';

  BcvRateSource({http.Client? client, this.timeout = const Duration(seconds: 15)})
      : _client = client ?? http.Client();

  @override
  bool isSupported(String currencyCode) =>
      currencyCode.toUpperCase() == _quoteCode;

  @override
  int get historyDays => 0;

  @override
  Future<Map<String, double>> fetchLatestRates({
    required String base,
    required List<String> quotes,
  }) async {
    if (base.toUpperCase() != 'USD' || !quotes.contains(_quoteCode)) {
      return const {};
    }

    final uri = Uri.parse(_baseUrl);
    final body = await _get(uri);

    final data = jsonDecode(body) as Map<String, dynamic>;
    final avg = data['promedio'];
    if (avg is! num || avg <= 0) {
      throw ExchangeRateApiException('Malformed BCV response');
    }
    return {_quoteCode: avg.toDouble()};
  }

  Future<String> _get(Uri uri) async {
    try {
      final response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw ExchangeRateApiException(
            'BCV error ${response.statusCode}: ${response.body}');
      }
      return response.body;
    } on TimeoutException {
      throw ExchangeRateApiException('Request timed out');
    } on http.ClientException catch (e) {
      throw ExchangeRateApiException('Network error: ${e.message}');
    }
  }

  @override
  void dispose() {
    _client.close();
  }
}