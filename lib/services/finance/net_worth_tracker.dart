import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/services/finance/revaluation_service.dart';

/// Records the daily net worth snapshot.
///
/// The app has no background execution, so this runs once per app open rather
/// than on a timer: [ensureTodaySnapshot] is idempotent and compares calendar
/// days, so a day the app stayed closed is backfilled on the next open.
class NetWorthTracker {
  final FinanceRepository _repository;
  final RevaluationService _revaluationService;

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
}
