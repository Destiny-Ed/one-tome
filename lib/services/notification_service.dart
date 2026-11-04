import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
    _initialized = true;
  }

  static Future<bool> isReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('reminder_enabled') ?? false;
  }

  static Future<TimeOfDay?> getReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final h = prefs.getInt('reminder_hour');
    final m = prefs.getInt('reminder_minute');
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  static Future<void> scheduleDaily(TimeOfDay time) async {
    await init();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_enabled', true);
    await prefs.setInt('reminder_hour', time.hour);
    await prefs.setInt('reminder_minute', time.minute);

    await _plugin.cancelAll();
    await _plugin.zonedSchedule(
      0,
      'OneTome',
      'Time to continue your book',
      _nextInstanceOf(time),
      const NotificationDetails(
        android: AndroidNotificationDetails('daily', 'Daily reminder', importance: Importance.defaultImportance),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancel() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_enabled', false);
    await _plugin.cancelAll();
  }

  static tz.TZDateTime _nextInstanceOf(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
