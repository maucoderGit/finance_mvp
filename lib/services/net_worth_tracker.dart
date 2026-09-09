import 'dart:async';
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/services/revaluation_service.dart';

/// Records daily net worth snapshots and periodically syncs rates.
class NetWorthTracker {
  final FinanceRepository _repository;
  final RevaluationService _revaluationService;

  Timer? _dailyTimer;

  NetWorthTracker(this._repository, this._revaluationService);

  /// Ensures today's net worth snapshot exists. Safe to call repeatedly.
  Future<void> ensureTodaySnapshot({
    String? nationalCurrencyCode,
    bool overwrite = false,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (!overwrite) {
      final existing = await _repository.watchNetWorthHistory(limit: 1).first;
      final newest = existing.isNotEmpty ? existing.first : null;
      if (newest != null &&
          newest.date.year == today.year &&
          newest.date.month == today.month &&
          newest.date.day == today.day) {
        return;
      }
    }

    await _revaluationService.recordDailyNetWorth(
        nationalCurrencyCode: nationalCurrencyCode);
  }

  /// Schedule a daily net worth snapshot shortly after midnight.
  void startDailyScheduler({String? nationalCurrencyCode}) {
    _dailyTimer?.cancel();

    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final untilMidnight = nextMidnight.difference(now);

    _dailyTimer = Timer(untilMidnight, () async {
      await ensureTodaySnapshot(nationalCurrencyCode: nationalCurrencyCode);
      startDailyScheduler(nationalCurrencyCode: nationalCurrencyCode);
    });
  }

  void cancel() {
    _dailyTimer?.cancel();
    _dailyTimer = null;
  }
}