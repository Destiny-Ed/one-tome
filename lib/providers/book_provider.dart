import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/book.dart';

class BookProvider extends ChangeNotifier {
  static const _activeKey = 'active_book';
  static const _historyKey = 'book_history';

  Book? _activeBook;
  List<Book> _history = [];
  bool _loading = true;

  Book? get activeBook => _activeBook;
  List<Book> get history => List.unmodifiable(_history);
  bool get loading => _loading;
  bool get hasActiveBook => _activeBook != null && !_activeBook!.isCompleted;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final activeJson = prefs.getString(_activeKey);
    if (activeJson != null) {
      _activeBook = Book.fromJsonString(activeJson);
    }
    final historyJson = prefs.getStringList(_historyKey) ?? [];
    _history = historyJson.map(Book.fromJsonString).toList();
    _loading = false;
    notifyListeners();
  }

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
    if (_activeBook == null) return;
    _activeBook!.currentPage = page.clamp(0, _activeBook!.totalPages);
    _activeBook!.lastReadAt = DateTime.now();
    if (_activeBook!.currentPage >= _activeBook!.totalPages) {
      await completeBook();
      return;
    }
    await _saveActive();
    notifyListeners();
  }

  Future<void> markDoneForToday() async {
    if (_activeBook == null) return;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _activeBook!.doneForTodayUntil = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
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

  Future<void> abandonActive() async {
    _activeBook = null;
    await _saveActive();
    notifyListeners();
  }
}
