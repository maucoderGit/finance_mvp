import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Persists the "register my transactions" reminder and schedules one daily
/// notification at a fixed time. A single repeating notification under a
/// constant id, so re-scheduling on every boot is idempotent.
class NotificationProvider extends ChangeNotifier {
  static const _reminderId = 1;
  static const _enabledKey = 'notif_reminder_enabled';
  static const _hourKey = 'notif_reminder_hour';
  static const _minuteKey = 'notif_reminder_minute';

  final SharedPreferences _prefs;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _enabled = false;
  int _hour = 20;
  int _minute = 0;

  bool get enabled => _enabled;
  int get hour => _hour;
  int get minute => _minute;

  NotificationProvider(this._prefs) {
    _enabled = _prefs.getBool(_enabledKey) ?? false;
    _hour = _prefs.getInt(_hourKey) ?? 20;
    _minute = _prefs.getInt(_minuteKey) ?? 0;
  }

  Future<void> init() async {
    try {
      tz_data.initializeTimeZones();
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: IOSInitializationSettings(),
      ),
    );
  }

  /// Persists the reminder preferences and (re)schedules or cancels the
  /// notification accordingly.
  Future<void> configure({
    required bool enabled,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    _enabled = enabled;
    _hour = hour;
    _minute = minute;
    notifyListeners();
    await _prefs.setBool(_enabledKey, enabled);
    await _prefs.setInt(_hourKey, hour);
    await _prefs.setInt(_minuteKey, minute);

    if (!enabled) {
      await _plugin.cancel(id: _reminderId);
      return;
    }
    await _requestPermissions();
    await _schedule(title, body);
  }

  Future<void> _requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  Future<void> _schedule(String title, String body) async {
    await _plugin.zonedSchedule(
      id: _reminderId,
      title: title,
      body: body,
      scheduledDate: _nextInstance(),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'transaction_reminders',
          'Transaction reminders',
          channelDescription: 'Reminders to register transactions',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'transaction_reminder',
    );
  }

  tz.TZDateTime _nextInstance() {
    final now = tz.TZDateTime.now(tz.local);
    var next =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, _hour, _minute);
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }
}