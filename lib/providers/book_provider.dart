import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/book.dart';

class BookProvider extends ChangeNotifier {
  static const _activeKey = 'active_book';
  static const _historyKey = 'book_history';
  static const _onboardingKey = 'onboarding_done';
  static const _dailyGoalKey = 'daily_goal';
  static const _streakKey = 'reading_streak';
  static const _lastReadDateKey = 'last_read_date';
  static const _pagesTodayKey = 'pages_today';
  static const _pagesTodayDateKey = 'pages_today_date';

  Book? _activeBook;
  List<Book> _history = [];
  bool _loading = true;
  bool _hasCompletedOnboarding = false;
  int _dailyGoalPages = 20;
  int _streak = 0;
  DateTime? _lastReadDate;
  int _pagesReadToday = 0;
  bool _goalDialogShownToday = false;

  Book? get activeBook => _activeBook;
  List<Book> get history => List.unmodifiable(_history);
  bool get loading => _loading;
  bool get hasActiveBook => _activeBook != null && !_activeBook!.isCompleted;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  int get dailyGoalPages => _dailyGoalPages;
  int get streak => _streak;
  int get pagesReadToday => _pagesReadToday;
  bool get hasReachedDailyGoal => _pagesReadToday >= _dailyGoalPages && _dailyGoalPages > 0;
  bool get shouldShowGoalDialog => hasReachedDailyGoal && !_goalDialogShownToday;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _hasCompletedOnboarding = prefs.getBool(_onboardingKey) ?? false;
    _dailyGoalPages = prefs.getInt(_dailyGoalKey) ?? 20;
    _streak = prefs.getInt(_streakKey) ?? 0;
    final last = prefs.getString(_lastReadDateKey);
    if (last != null) _lastReadDate = DateTime.parse(last);

    final todayStr = _todayKey();
    final storedDate = prefs.getString(_pagesTodayDateKey);
    if (storedDate == todayStr) {
      _pagesReadToday = prefs.getInt(_pagesTodayKey) ?? 0;
      _goalDialogShownToday = prefs.getBool('goal_dialog_shown_$todayStr') ?? false;
    } else {
      _pagesReadToday = 0;
      _goalDialogShownToday = false;
    }

    final activeJson = prefs.getString(_activeKey);
    if (activeJson != null) {
      _activeBook = Book.fromJsonString(activeJson);
    }
    final historyJson = prefs.getStringList(_historyKey) ?? [];
    _history = historyJson.map(Book.fromJsonString).toList();
    _loading = false;
    notifyListeners();
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  Future<void> completeOnboarding({required int dailyGoal}) async {
    _dailyGoalPages = dailyGoal;
    _hasCompletedOnboarding = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    await prefs.setInt(_dailyGoalKey, dailyGoal);
    notifyListeners();
  }

  Future<void> updateDailyGoal(int pages) async {
    _dailyGoalPages = pages;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyGoalKey, pages);
    notifyListeners();
  }

  Future<void> _updateStreak() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_lastReadDate == null || !_isSameDay(_lastReadDate!, today)) {
      final yesterday = today.subtract(const Duration(days: 1));
      if (_lastReadDate != null && _isSameDay(_lastReadDate!, yesterday)) {
        _streak++;
      } else {
        _streak = 1;
      }
      _lastReadDate = today;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_streakKey, _streak);
      await prefs.setString(_lastReadDateKey, today.toIso8601String());
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _saveActive() async {
    final prefs = await SharedPreferences.getInstance();
    if (_activeBook == null) {
      await prefs.remove(_activeKey);
    } else {
      await prefs.setString(_activeKey, _activeBook!.toJsonString());
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_historyKey, _history.map((b) => b.toJsonString()).toList());
  }

  Future<String> _copyPdfToAppDir(String sourcePath, String title) async {
    final dir = await getApplicationDocumentsDirectory();
    final booksDir = Directory('${dir.path}/books');
    if (!await booksDir.exists()) await booksDir.create(recursive: true);
    final dest = '${booksDir.path}/${const Uuid().v4()}_${title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.pdf';
    await File(sourcePath).copy(dest);
    return dest;
  }

  Future<bool> importBook(String filePath, String title, int totalPages) async {
    if (hasActiveBook) return false;
    final localPath = await _copyPdfToAppDir(filePath, title);
    _activeBook = Book(
      id: const Uuid().v4(),
      title: title,
      filePath: localPath,
      totalPages: totalPages,
    );
    await _saveActive();
    notifyListeners();
    return true;
  }

  Future<void> updateProgress(int page) async {
    if (_activeBook == null || _activeBook!.isDoneForToday) return;
    final prev = _activeBook!.currentPage;
    _activeBook!.currentPage = page.clamp(0, _activeBook!.totalPages);
    _activeBook!.lastReadAt = DateTime.now();

    if (_activeBook!.currentPage > prev) {
      _pagesReadToday += (_activeBook!.currentPage - prev);
      final prefs = await SharedPreferences.getInstance();
      final todayStr = _todayKey();
      await prefs.setInt(_pagesTodayKey, _pagesReadToday);
      await prefs.setString(_pagesTodayDateKey, todayStr);
    }

    await _updateStreak();
    if (_activeBook!.currentPage >= _activeBook!.totalPages) {
      await completeBook();
      return;
    }
    await _saveActive();
    notifyListeners();
  }

  Future<void> markGoalDialogShown() async {
    _goalDialogShownToday = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('goal_dialog_shown_${_todayKey()}', true);
    notifyListeners();
  }

  Future<void> markDoneForToday() async {
    if (_activeBook == null) return;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _activeBook!.doneForTodayUntil = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    await _updateStreak();
    await _saveActive();
    notifyListeners();
  }

  Future<void> completeBook() async {
    if (_activeBook == null) return;
    _activeBook!.isCompleted = true;
    _activeBook!.completedAt = DateTime.now();
    _activeBook!.currentPage = _activeBook!.totalPages;
    _history.insert(0, _activeBook!);
    _activeBook = null;
    await _saveActive();
    await _saveHistory();
    notifyListeners();
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _activeBook = null;
    _history.clear();
    _hasCompletedOnboarding = false;
    _dailyGoalPages = 20;
    _streak = 0;
    _lastReadDate = null;
    _pagesReadToday = 0;
    _goalDialogShownToday = false;
    notifyListeners();
  }
}
