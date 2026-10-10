import 'package:flutter/foundation.dart';
import 'package:finance_mvp/models/gain_loss.dart';
import 'package:finance_mvp/models/net_worth_data_point.dart';
import 'package:finance_mvp/services/finance/revaluation_service.dart';

/// Provides revaluation data (FX gain/loss, purchasing power, net worth) to UI.
class RevaluationProvider extends ChangeNotifier {
  final RevaluationService _service;

  bool _loading = false;
  String? _error;

  RevaluationSummary? _summary;
  List<GainLossResult> _gainLossByAccount = [];
  List<CurrencyGainLoss> _gainLossByCurrency = [];
  List<NetWorthDataPoint> _netWorthHistory = [];
  List<PowerDataPoint> _purchasingPowerHistory = [];

  bool _refreshing = false;
  bool _disposed = false;

  RevaluationProvider(this._service);

  bool get loading => _loading;
  String? get error => _error;
  RevaluationSummary? get summary => _summary;
  List<GainLossResult> get gainLossByAccount => _gainLossByAccount;
  List<CurrencyGainLoss> get gainLossByCurrency => _gainLossByCurrency;
  List<NetWorthDataPoint> get netWorthHistory => _netWorthHistory;
  List<PowerDataPoint> get purchasingPowerHistory => _purchasingPowerHistory;

  /// Refresh all revaluation data.
  ///
  /// Re-entrancy guarded: overlapping refreshes (home + revaluation screens
  /// both fire on open) would otherwise interleave and let a stale run
  /// overwrite newer results. The per-account scan is computed once and shared
  /// with the currency/summary aggregates instead of scanned three times.
  Future<void> refresh() async {
    if (_refreshing || _disposed) return;
    _refreshing = true;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final byAccount = await _service.getUnrealizedGainLossByAccount();
      _gainLossByAccount = byAccount;
      _summary = await _service.getRevaluationSummary(byAccount: byAccount);
      _gainLossByCurrency =
          await _service.getUnrealizedGainLossByCurrency(byAccount: byAccount);
      _netWorthHistory = await _service.getNetWorthHistory();
      _purchasingPowerHistory = await _service.getPurchasingPowerHistory(
          _summary?.nationalCurrencyCode ?? 'VES');
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      _refreshing = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> recordDailySnapshot() async {
    if (_summary != null) {
      await _service.recordDailyNetWorth(
          nationalCurrencyCode: _summary!.nationalCurrencyCode);
    } else {
      await _service.recordDailyNetWorth();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}