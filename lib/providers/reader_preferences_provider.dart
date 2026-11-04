import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReaderPreferencesProvider extends ChangeNotifier {
  bool _soundEnabled = true;
  double _brightness = 1.0;
  bool _showControls = true;
  bool _dualPage = false;
  double _margin = 0.0;

  bool get soundEnabled => _soundEnabled;
  double get brightness => _brightness;
  bool get showControls => _showControls;
  bool get dualPage => _dualPage;
  double get margin => _margin;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('reader_sound') ?? true;
    _brightness = prefs.getDouble('reader_brightness') ?? 1.0;
    _dualPage = prefs.getBool('reader_dual_page') ?? false;
    _margin = prefs.getDouble('reader_margin') ?? 0.0;
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

  Future<void> setDualPage(bool value) async {
    _dualPage = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reader_dual_page', value);
    notifyListeners();
  }

  Future<void> setMargin(double value) async {
    _margin = value.clamp(0.0, 40.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('reader_margin', _margin);
    notifyListeners();
  }

  void toggleControls() {
    _showControls = !_showControls;
    notifyListeners();
  }
}
