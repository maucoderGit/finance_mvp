import 'package:finance_mvp/services/finance/recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final anchor = DateTime(2026, 1, 31);

  group('occurrence stepping', () {
    test('daily and weekly step by interval', () {
      final daily = Recurrence(type: RecurrenceType.daily, anchor: anchor);
      expect(daily.occurrence(0), anchor);
      expect(daily.occurrence(1), DateTime(2026, 2, 1));
      expect(daily.occurrence(5), DateTime(2026, 2, 5));

      final weekly =
          Recurrence(type: RecurrenceType.weekly, anchor: anchor, interval: 2);
      expect(weekly.occurrence(0), anchor);
      expect(weekly.occurrence(1), DateTime(2026, 2, 14));
      expect(weekly.occurrence(2), DateTime(2026, 2, 28));
    });

    test('monthly keeps the anchor day instead of drifting', () {
      final monthly = Recurrence(type: RecurrenceType.monthly, anchor: anchor);
      // Feb has no 31st, so it clamps...
      expect(monthly.occurrence(1), DateTime(2026, 2, 28));
      // ...and the series goes back to the 31st rather than staying on the 28th,
      // which is what stepping one occurrence at a time would do.
      expect(monthly.occurrence(2), DateTime(2026, 3, 31));
      expect(monthly.occurrence(3), DateTime(2026, 4, 30));
      expect(monthly.occurrence(4), DateTime(2026, 5, 31));
    });

    test('monthly clamps to 29 in a leap February', () {
      final leapFeb = Recurrence(
          type: RecurrenceType.monthly, anchor: DateTime(2028, 1, 31));
      expect(leapFeb.occurrence(1), DateTime(2028, 2, 29));
    });

    test('yearly handles 29 February', () {
      final yearly =
          Recurrence(type: RecurrenceType.yearly, anchor: DateTime(2028, 2, 29));
      expect(yearly.occurrence(1), DateTime(2029, 2, 28));
      expect(yearly.occurrence(4), DateTime(2032, 2, 29));
    });

    test('every two months crosses the year boundary', () {
      final everyTwo = Recurrence(
          type: RecurrenceType.monthly, anchor: DateTime(2026, 11, 15),
          interval: 2);
      expect(everyTwo.occurrence(1), DateTime(2027, 1, 15));
      expect(everyTwo.occurrence(2), DateTime(2027, 3, 15));
    });
  });

  group('end conditions', () {
    test('never produces no upper bound', () {
      final r = Recurrence(
          type: RecurrenceType.monthly, anchor: anchor,
          end: RecurrenceEnd.never);
      expect(r.occurrence(600), isNotNull);
    });

    test('after a number of times counts the template itself', () {
      final r = Recurrence(
        type: RecurrenceType.monthly,
        anchor: anchor,
        end: RecurrenceEnd.afterCount,
        totalCount: 3,
      );
      expect(r.occurrence(0), isNotNull, reason: 'the anchor is occurrence 0');
      expect(r.occurrence(2), isNotNull);
      expect(r.occurrence(3), isNull);
    });

    test('on a date includes an occurrence landing on that day', () {
      final r = Recurrence(
        type: RecurrenceType.monthly,
        anchor: anchor,
        end: RecurrenceEnd.onDate,
        endDate: DateTime(2026, 3, 31, 18, 30),
      );
      expect(r.occurrence(2), DateTime(2026, 3, 31));
      expect(r.occurrence(3), isNull);
    });

    test('on a date with a time component still includes that whole day', () {
      final r = Recurrence(
        type: RecurrenceType.monthly,
        anchor: anchor,
        end: RecurrenceEnd.onDate,
        endDate: DateTime(2026, 2, 28, 23, 59, 59),
      );
      expect(r.occurrence(1), DateTime(2026, 2, 28));
      expect(r.occurrence(2), isNull);
    });
  });

  test('interval below 1 is treated as 1', () {
    final r =
        Recurrence(type: RecurrenceType.daily, anchor: anchor, interval: 0);
    expect(r.effectiveInterval, 1);
    expect(r.occurrence(1), DateTime(2026, 2, 1));
  });

  test('nextOccurrenceOnOrAfter finds the next due date, skipping the anchor',
      () {
    final r = Recurrence(type: RecurrenceType.monthly, anchor: anchor);
    expect(r.nextOccurrenceOnOrAfter(anchor), DateTime(2026, 2, 28));
    expect(r.nextOccurrenceOnOrAfter(DateTime(2026, 2, 20)),
        DateTime(2026, 2, 28));
    expect(r.nextOccurrenceOnOrAfter(DateTime(2026, 3, 1)),
        DateTime(2026, 3, 31));
  });

  test('nextOccurrenceOnOrAfter is null once the series is over', () {
    final r = Recurrence(
      type: RecurrenceType.monthly,
      anchor: anchor,
      end: RecurrenceEnd.afterCount,
      totalCount: 2,
    );
    expect(r.nextOccurrenceOnOrAfter(DateTime(2026, 3, 1)), isNull);
  });

  test('id parsing is tolerant of unknown stored values', () {
    expect(RecurrenceType.tryParse('monthly'), RecurrenceType.monthly);
    expect(RecurrenceType.tryParse('fortnightly'), isNull);
    expect(RecurrenceType.tryParse(null), isNull);
    expect(RecurrenceEnd.tryParse('nonsense'), RecurrenceEnd.never);
    expect(RecurrenceEnd.tryParse(null), RecurrenceEnd.never);
  });

  test('describe reads as a sentence', () {
    expect(
      Recurrence(type: RecurrenceType.weekly, anchor: DateTime(2026, 3, 6))
          .describe(),
      'Every week on Fri · until you cancel',
    );
    expect(
      Recurrence(type: RecurrenceType.monthly, anchor: anchor, interval: 2)
          .describe(),
      'Every 2 months on day 31 · until you cancel',
    );
    expect(
      Recurrence(
        type: RecurrenceType.daily,
        anchor: anchor,
        end: RecurrenceEnd.afterCount,
        totalCount: 12,
      ).describe(),
      'Every day · 12 times',
    );
  });
}
