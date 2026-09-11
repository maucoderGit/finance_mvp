import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:finance_mvp/database/app_database.dart';
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/services/exchange_rate_api_service.dart';

/// Manages exchange-rate state: syncing from the API, manual overrides, and
/// the base currency.
class CurrencyProvider extends ChangeNotifier {
  final FinanceRepository _repository;
  final ExchangeRateApiService _apiService;

  bool _syncing = false;
  String? _syncError;
  DateTime? _lastSyncDate;

  CurrencyProvider(this._repository, {ExchangeRateApiService? apiService})
      : _apiService = apiService ?? ExchangeRateApiService();

  bool get isSyncing => _syncing;
  String? get syncError => _syncError;
  DateTime? get lastSyncDate => _lastSyncDate;

  /// Ensure a [code]/[name]/[symbol] currency exists in the database.
  /// No-op if it already exists.
  Future<void> ensureCurrency({
    required String code,
    required String name,
    required String symbol,
  }) async {
    final existing = await _repository.getCurrency(code);
    if (existing != null) return;
    await _repository.addCurrency(CurrenciesCompanion.insert(
      code: code,
      name: name,
      symbol: symbol,
    ));
  }

  /// Complete the onboarding wizard: persist user profile, base/national
  /// currency and rate sync mode, then mark the flow as finished.
  Future<void> completeOnboarding({
    required String username,
    required String baseCode,
    required String baseName,
    required String baseSymbol,
    required String nationalCode,
    required String nationalName,
    required String nationalSymbol,
    required String syncMode,
  }) async {
    await ensureCurrency(
        code: baseCode, name: baseName, symbol: baseSymbol);
    await ensureCurrency(
        code: nationalCode, name: nationalName, symbol: nationalSymbol);

    await _repository.updateUserSettings(UserSettingsCompanion(
      username: Value(username),
      baseCurrencyCode: Value(baseCode),
      nationalCurrencyCode: Value(nationalCode),
      currencySelectionMode: Value(syncMode),
      hasCompletedOnboarding: const Value(true),
    ));
    notifyListeners();
  }

  /// Sync today's rates for all non-base currencies via the API.
  /// Falls back gracefully when a currency is unsupported (e.g. VES).
  /// Returns how many currencies were updated.
  Future<int> syncRates({bool force = false}) async {
    // Don't run concurrently.
    if (_syncing) return 0;
    _syncing = true;
    _syncError = null;
    notifyListeners();

    try {
      final baseCode = await _repository.getBaseCurrencyCode();
      final currencies = await _repository.getAllCurrencies();

      final supported = currencies
          .where((c) => c.code != baseCode && _apiService.isSupported(c.code))
          .toList();

      if (supported.isEmpty) {
        _syncError = 'No supported currencies to sync (VES may require manual entry).';
        return 0;
      }

      final quotes = supported.map((c) => c.code).toList();
      final today = DateTime.now();
      final start = DateTime(today.year, today.month, today.day);

      final rates = await _apiService.fetchTimeSeries(
        base: baseCode,
        quotes: quotes,
        from: start,
        to: today,
      );

      var updated = 0;
      rates.forEach((dateStr, quoteRates) {
        if (dateStr.isEmpty) return;
        final date = DateTime.tryParse(dateStr);
        if (date == null) return;

        for (final quote in quotes) {
          final rate = quoteRates[quote];
          if (rate == null || rate <= 0) continue;
          updated++;
          _repository.addExchangeRate(CurrencyRatesCompanion(
            currencyCode: Value(quote),
            rate: Value(rate),
            date: Value(date),
          ));
        }
      });

      _lastSyncDate = DateTime.now();
      // Persist last fetch time in settings.
      await _repository.updateUserSettings(UserSettingsCompanion(
        lastAutoFetchDate: Value(DateTime.now()),
        currencySelectionMode: const Value('auto'),
      ));

      return updated;
    } catch (e) {
      _syncError = e.toString();
      return 0;
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  /// Fetch a series of historical rates for [currencyCode] from the API.
  /// Returns the number of rate rows stored.
  Future<int> syncHistoricalRates(
    String currencyCode, {
    required int daysBack,
  }) async {
    if (!_apiService.isSupported(currencyCode)) {
      _syncError = 'Currency $currencyCode is not supported by the API. Add rates manually.';
      return 0;
    }

    final baseCode = await _repository.getBaseCurrencyCode();
    if (currencyCode == baseCode) return 0;

    final today = DateTime.now();
    final start = today.subtract(Duration(days: daysBack));

    final rates = await _apiService.fetchTimeSeries(
      base: baseCode,
      quotes: [currencyCode],
      from: start,
      to: today,
    );

    var count = 0;
    rates.forEach((dateStr, quoteRates) {
      final date = DateTime.tryParse(dateStr);
      final rate = quoteRates[currencyCode];
      if (date == null || rate == null || rate <= 0) return;
      count++;
      _repository.addExchangeRate(CurrencyRatesCompanion(
        currencyCode: Value(currencyCode),
        rate: Value(rate),
        date: Value(date),
      ));
    });

    return count;
  }

  /// Set the base currency. Returns the new code.
  Future<String> setBaseCurrency(String code) async {
    await _repository.setBaseCurrency(code);
    notifyListeners();
    return code;
  }

  Future<String> getBaseCurrencyCode() => _repository.getBaseCurrencyCode();

  Future<String> getNationalCurrencyCode() =>
      _repository.getNationalCurrencyCode();

  Future<bool> hasCompletedOnboarding() =>
      _repository.getHasCompletedOnboarding();

  Stream<UserSetting?> watchUserSettings() => _repository.watchUserSettings();

  Stream<List<Currency>> watchCurrencies() => _repository.watchCurrencies();

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}