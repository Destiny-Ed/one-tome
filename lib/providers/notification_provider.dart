import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  bool _enabled = false;
  TimeOfDay _time = const TimeOfDay(hour: 20, minute: 0);
  bool _loaded = false;

  bool get enabled => _enabled;
  TimeOfDay get time => _time;
  bool get loaded => _loaded;

  Future<void> load() async {
    _enabled = await NotificationService.isReminderEnabled();
    final t = await NotificationService.getReminderTime();
    if (t != null) _time = t;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    notifyListeners();
    if (value) {
      await NotificationService.requestPermission();
      await NotificationService.scheduleDaily(_time);
    } else {
      await NotificationService.cancel();
    }
  }

  Future<void> setTime(TimeOfDay value) async {
    _time = value;
    notifyListeners();
    if (_enabled) {
      await NotificationService.scheduleDaily(value);
    }
  }
}
