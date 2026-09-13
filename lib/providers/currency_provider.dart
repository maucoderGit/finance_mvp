import 'dart:async';

import 'package:drift/drift.dart';
import 'package:finance_mvp/database/app_database.dart';
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/services/rates/bcv_rate_source.dart';
import 'package:finance_mvp/services/rates/exchange_rate_api_service.dart';
import 'package:finance_mvp/services/rates/rate_source.dart';
import 'package:flutter/foundation.dart';

import 'package:finance_mvp/services/rates/market_rate_source.dart';

/// Manages exchange-rate state: syncing from the available rate sources,
/// manual overrides, the base currency and once-per-day automatic sync.
class CurrencyProvider extends ChangeNotifier {
  final FinanceRepository _repository;
  final List<RateSource> _sources;
  final MarketRateSource _marketRateSource;

  bool _syncing = false;
  String? _syncError;
  DateTime? _lastSyncDate;
  Timer? _dailyTimer;

  CurrencyProvider(this._repository,
      {List<RateSource>? sources, MarketRateSource? marketRateSource})
      : _sources = sources ?? [ExchangeRateApiService(), BcvRateSource()],
        _marketRateSource = marketRateSource ?? MarketRateSource();

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

  /// Sync today's rate for the national currency (VES) plus its market (P2P)
  /// rate. Auto-sync runs at most once per day; pass [force] to refetch (used
  /// by the manual cloud-sync buttons).
  ///
  /// Returns how many rates were stored (0 when already fetched today).
  Future<int> syncRates({bool force = false}) async {
    if (_syncing) return 0;

    final now = DateTime.now();
    final lastFetch = await _repository.getLastAutoFetchDate();
    final alreadyFetchedToday = lastFetch != null &&
        lastFetch.year == now.year &&
        lastFetch.month == now.month &&
        lastFetch.day == now.day;
    if (alreadyFetchedToday && !force) {
      _lastSyncDate = lastFetch;
      return 0;
    }

    _syncing = true;
    _syncError = null;
    notifyListeners();

    try {
      final baseCode = await _repository.getBaseCurrencyCode();
      final nationalCode = await _repository.getNationalCurrencyCode();
      final national = await _repository.getCurrency(nationalCode);
      final toSync = nationalCode == baseCode || national == null
          ? <Currency>[]
          : [national];

      final unsupported = toSync
          .where((c) => !_sources.any((s) => s.isSupported(c.code)))
          .map((c) => c.code)
          .toList();

      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      var updated = 0;
      for (final source in _sources) {
        final quotes = toSync
            .map((c) => c.code)
            .where(source.isSupported)
            .toList();
        if (quotes.isEmpty) continue;

        try {
          final rates = await source.fetchLatestRates(
              base: baseCode, quotes: quotes);
          for (final entry in rates.entries) {
            if (entry.value <= 0) continue;
            updated++;
            await _repository.addExchangeRate(CurrencyRatesCompanion(
              currencyCode: Value(entry.key),
              rate: Value(entry.value),
              date: Value(todayDate),
            ));
          }
        } catch (e) {
          _syncError = e.toString();
        }
      }

      // Persist today's parallel/market VES rate for net-worth valuation and
      // FX deltas. Optional: failures don't block the currency sync.
      try {
        final marketRate = await _marketRateSource.fetchLatestRate();
        if (marketRate != null && marketRate > 0) {
          await _repository.addMarketRate(MarketRatesCompanion(
            rate: Value(marketRate),
            date: Value(todayDate),
          ));
        }
      } catch (e) {
        if (updated == 0) _syncError ??= e.toString();
      }

      if (updated > 0) {
        _syncError = unsupported.isEmpty
            ? null
            : 'Unsupported: ${unsupported.join(', ')}. Add manually.';
        _lastSyncDate = DateTime.now();
        await _repository.updateUserSettings(UserSettingsCompanion(
          lastAutoFetchDate: Value(DateTime.now()),
          currencySelectionMode: const Value('auto'),
        ));
      } else {
        _syncError ??= unsupported.isEmpty
            ? 'No rate source returned data.'
            : 'Unsupported: ${unsupported.join(', ')}. Add manually.';
      }

      return updated;
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  /// Fetch up to [daysBack] of historical rates for [currencyCode] via its
  /// rate source. Sources with no history (e.g. BCV) store today's rate only.
  /// Returns the number of rate rows stored.
  Future<int> syncHistoricalRates(
    String currencyCode, {
    required int daysBack,
  }) async {
    final source = _sources.where((s) => s.isSupported(currencyCode)).firstOrNull;
    if (source == null) {
      _syncError = 'Currency $currencyCode is not supported by any source. Add rates manually.';
      return 0;
    }

    final baseCode = await _repository.getBaseCurrencyCode();
    if (currencyCode == baseCode) return 0;

    if (source is ExchangeRateApiService) {
      final today = DateTime.now();
      final start = today.subtract(Duration(days: daysBack));
      final rates = await source.fetchTimeSeries(
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

    final rates = await source.fetchLatestRates(base: baseCode, quotes: [currencyCode]);
    final rate = rates[currencyCode];
    if (rate == null || rate <= 0) return 0;
    _repository.addExchangeRate(CurrencyRatesCompanion(
      currencyCode: Value(currencyCode),
      rate: Value(rate),
      date: Value(DateTime.now()),
    ));
    return 1;
  }

  /// Kick off automatic daily fetching: sync now if it hasn't happened today
  /// yet, then re-arm a timer for every following midnight (auto mode only).
  void startDailyAutoSync() {
    unawaited(_runDailySchedule());
  }

  Future<void> _runDailySchedule() async {
    final setting = await _repository.watchUserSettings().first;
    if (setting?.currencySelectionMode != 'auto') return;

    final last = await _repository.getLastAutoFetchDate();
    final now = DateTime.now();
    final alreadyFetchedToday = last != null &&
        last.year == now.year &&
        last.month == now.month &&
        last.day == now.day;
    if (!alreadyFetchedToday) {
      await syncRates(force: true);
    }

    _dailyTimer?.cancel();
    _dailyTimer = Timer(_untilNextMidnight(), () {
      _dailyTimer = null;
      unawaited(_runDailySchedule());
    });
  }

  Duration _untilNextMidnight() {
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    return next.difference(now);
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
    _dailyTimer?.cancel();
    for (final source in _sources) {
      source.dispose();
    }
    _marketRateSource.dispose();
    super.dispose();
  }
}