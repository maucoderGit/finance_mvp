import 'dart:convert';

import 'package:http/http.dart' as http;

import 'exchange_rate_api_service.dart';

/// Unofficial / parallel (P2P) VES→USD market rate via the community
/// dolarapi.com wrapper. No API key required.
///
/// Endpoint: GET https://ve.dolarapi.com/v1/dolares/paralelo
/// Returns the free-market USD→VES rate in `promedio`. Unlike the BCV
/// official source this reflects the true replacement value of bolivares.
class MarketRateSource {
  final http.Client _client;
  final Duration timeout;

  static const String _baseUrl = 'https://ve.dolarapi.com/v1/dolares/paralelo';

  MarketRateSource(
      {http.Client? client, this.timeout = const Duration(seconds: 15)})
      : _client = client ?? http.Client();

  /// Latest parallel/market USD→VES rate, or null if unparseable.
  Future<double?> fetchLatestRate() async {
    final uri = Uri.parse(_baseUrl);
    final body = await fetchJsonText(_client, uri, timeout);

    final data = jsonDecode(body) as Map<String, dynamic>;
    final avg = data['promedio'];
    if (avg is! num || avg <= 0) {
      throw ExchangeRateApiException('Malformed dolarapi paralelo response');
    }
    return avg.toDouble();
  }

  void dispose() {
    _client.close();
  }
}