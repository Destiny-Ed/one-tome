import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ReadingLayout { vertical, horizontal }

class ReaderPreferencesProvider extends ChangeNotifier {
  bool _soundEnabled = true;
  double _brightness = 1.0;
  bool _showControls = true;
  double _margin = 0.0;
  ReadingLayout _layout = ReadingLayout.vertical;

  bool get soundEnabled => _soundEnabled;
  double get brightness => _brightness;
  bool get showControls => _showControls;
  double get margin => _margin;
  ReadingLayout get layout => _layout;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('reader_sound') ?? true;
    _brightness = prefs.getDouble('reader_brightness') ?? 1.0;
    _margin = prefs.getDouble('reader_margin') ?? 0.0;
    final layoutIndex = prefs.getInt('reader_layout') ?? 0;
    _layout = ReadingLayout.values[layoutIndex.clamp(0, ReadingLayout.values.length - 1)];
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reader_sound', value);
    notifyListeners();
  }

  Future<void> setBrightness(double value) async {
    _brightness = value.clamp(0.3, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('reader_brightness', _brightness);
    notifyListeners();
  }

  Future<void> setMargin(double value) async {
    _margin = value.clamp(0.0, 40.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('reader_margin', _margin);
    notifyListeners();
  }

  Future<void> setLayout(ReadingLayout value) async {
    _layout = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reader_layout', value.index);
    notifyListeners();
  }

  void toggleControls() {
    _showControls = !_showControls;
    notifyListeners();
  }
}
