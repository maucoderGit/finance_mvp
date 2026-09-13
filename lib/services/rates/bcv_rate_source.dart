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
  Future<Map<String, double>> fetchLatestRates({
    required String base,
    required List<String> quotes,
  }) async {
    if (base.toUpperCase() != 'USD' || !quotes.contains(_quoteCode)) {
      return const {};
    }

    final uri = Uri.parse(_baseUrl);
    final body = await fetchJsonText(_client, uri, timeout);

    final data = jsonDecode(body) as Map<String, dynamic>;
    final avg = data['promedio'];
    if (avg is! num || avg <= 0) {
      throw ExchangeRateApiException('Malformed BCV response');
    }
    return {_quoteCode: avg.toDouble()};
  }

  @override
  void dispose() {
    _client.close();
  }
}