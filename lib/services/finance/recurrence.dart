/// Date arithmetic for recurring transactions.
///
/// A repeating transaction is anchored on the day the user recorded it: that
/// row is occurrence 0 and every later date is derived from the anchor rather
/// than by stepping forward one occurrence at a time. That matters for monthly
/// series — stepping drifts, so a bill due on the 31st would slide to the 28th
/// and stay there forever, while recomputing from the anchor returns to the 31st
/// the moment the month is long enough.
library;

import 'package:intl/intl.dart';

/// How often a series repeats. Every [type] is stepped by [interval] of its own
/// unit, so interval 2 + [monthly] is "every two months".
enum RecurrenceType {
  daily('daily', 'Daily'),
  weekly('weekly', 'Weekly'),
  monthly('monthly', 'Monthly'),
  yearly('yearly', 'Yearly');

  const RecurrenceType(this.id, this.label);

  final String id;
  final String label;

  static RecurrenceType? tryParse(String? value) {
    for (final t in RecurrenceType.values) {
      if (t.id == value) return t;
    }
    return null;
  }
}

/// When a series stops repeating.
enum RecurrenceEnd {
  /// Runs until the user turns recurrence off or deletes it.
  never('never', 'Never'),

  /// Stops once an occurrence would fall after [Recurrence.endDate].
  onDate('date', 'On a date'),

  /// Stops after a fixed number of occurrences, the template's own included.
  afterCount('count', 'After a number of times');

  const RecurrenceEnd(this.id, this.label);

  final String id;
  final String label;

  static RecurrenceEnd tryParse(String? value) => RecurrenceEnd.values
      .firstWhere((e) => e.id == value, orElse: () => RecurrenceEnd.never);
}

/// The full rule of one repeating transaction.
class Recurrence {
  const Recurrence({
    required this.type,
    required this.anchor,
    this.interval = 1,
    this.end = RecurrenceEnd.never,
    this.endDate,
    this.totalCount,
  });

  final RecurrenceType type;

  /// The day the series starts, and occurrence 0 of it. Kept at midnight —
  /// occurrences are calendar days, not instants.
  final DateTime anchor;

  /// How many [type]s between occurrences. Clamped to at least 1.
  final int interval;
  final RecurrenceEnd end;

  /// Only read when [end] is [RecurrenceEnd.onDate]. Compared by calendar day,
  /// so an end date of 3 Mar includes an occurrence that falls on 3 Mar.
  final DateTime? endDate;

  /// Only read when [end] is [RecurrenceEnd.afterCount]. Occurrence 0 counts,
  /// so totalCount 1 means "just this one, no repeats".
  final int? totalCount;

  int get effectiveInterval => interval < 1 ? 1 : interval;

  /// The calendar day of occurrence [index], or `null` when the series has
  /// already ended before reaching it.
  DateTime? occurrence(int index) {
    if (index < 0) return null;
    if (index > 0 &&
        end == RecurrenceEnd.afterCount &&
        (totalCount ?? 0) > 0 &&
        index >= totalCount!) {
      return null;
    }
    final date = _step(index);
    if (end == RecurrenceEnd.onDate && endDate != null && date.isAfter(_dayOf(endDate!))) {
      return null;
    }
    return date;
  }

  /// The first occurrence on or after [from], or `null` if the series is
  /// already over. Used to show the next due date without generating anything.
  DateTime? nextOccurrenceOnOrAfter(DateTime from) {
    final day = _dayOf(from);
    // Occurrence 0 is the anchor itself and is never re-materialised, so start
    // looking from the first repeat.
    for (var i = 1; i <= 5000; i++) {
      final date = occurrence(i);
      if (date == null) return null;
      if (!date.isBefore(day)) return date;
    }
    return null;
    // ponytail: 5000-iteration ceiling, unreachable for any interval >= 1 day
    // within a human lifetime. Return null rather than loop forever.
  }

  DateTime _step(int index) {
    final n = effectiveInterval * index;
    return switch (type) {
      RecurrenceType.daily => anchor.add(Duration(days: n)),
      RecurrenceType.weekly => anchor.add(Duration(days: 7 * n)),
      RecurrenceType.monthly => _addMonths(anchor, n),
      RecurrenceType.yearly => _addMonths(anchor, 12 * n),
    };
  }

  /// One-line summary for the recurrence card, e.g.
  /// "Every 2 weeks on Fri, starting 3 Mar 2025 · 12 times".
  String describe() {
    final every = switch (type) {
      RecurrenceType.daily => effectiveInterval == 1
          ? 'Every day'
          : 'Every $effectiveInterval days',
      RecurrenceType.weekly => _everyUnit(
          effectiveInterval,
          effectiveInterval == 1 ? 'week' : 'weeks',
          DateFormat.E().format(anchor)),
      RecurrenceType.monthly => _everyUnit(
          effectiveInterval,
          effectiveInterval == 1 ? 'month' : 'months',
          'day ${anchor.day}'),
      RecurrenceType.yearly => _everyUnit(
          effectiveInterval,
          effectiveInterval == 1 ? 'year' : 'years',
          DateFormat.yMMMM().format(anchor)),
    };

    final until = switch (end) {
      RecurrenceEnd.never => 'until you cancel',
      RecurrenceEnd.onDate => endDate == null
          ? 'until you cancel'
          : 'until ${DateFormat.yMMMd().format(endDate!)}',
      RecurrenceEnd.afterCount =>
        '${totalCount ?? 0} ${totalCount == 1 ? 'time' : 'times'}',
    };

    return '$every · $until';
  }

  String _everyUnit(int n, String unit, String on) =>
      n == 1 ? 'Every $unit on $on' : 'Every $n $unit on $on';
}

DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

/// Adds [months] calendar months, clamping the day to the target month's
/// length so 31 Jan + 1 month is 28 (or 29) Feb rather than rolling into March.
DateTime _addMonths(DateTime d, int months) {
  final total = d.month - 1 + months;
  final year = d.year + total ~/ 12;
  final month = total % 12 + 1;
  final lastDayOfMonth = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, d.day > lastDayOfMonth ? lastDayOfMonth : d.day);
}
