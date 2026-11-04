import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/highlight.dart';

class HighlightProvider extends ChangeNotifier {
  static const _key = 'highlights';
  List<Highlight> _highlights = [];

  List<Highlight> get highlights => List.unmodifiable(_highlights);

  List<Highlight> forBook(String bookId) =>
      _highlights.where((h) => h.bookId == bookId).toList()..sort((a, b) => a.page.compareTo(b.page));

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    _highlights = list.map((s) => Highlight.fromJson(jsonDecode(s))).toList();
    notifyListeners();
  }

  Future<void> addHighlight({
    required String bookId,
    required int page,
    required String text,
    String? note,
  }) async {
    final h = Highlight(
      id: const Uuid().v4(),
      bookId: bookId,
      page: page,
      text: text,
      note: note,
    );
    _highlights.add(h);
    await _save();
    notifyListeners();
  }

  Future<void> removeHighlight(String id) async {
    _highlights.removeWhere((h) => h.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _highlights.map((h) => jsonEncode(h.toJson())).toList());
  }

  String exportForBook(String bookId, String bookTitle) {
    final list = forBook(bookId);
    if (list.isEmpty) return 'No notes for $bookTitle';
    final buffer = StringBuffer('Notes from $bookTitle\n\n');
    for (final h in list) {
      buffer.writeln('Page ${h.page}');
      buffer.writeln(h.text);
      if (h.note != null && h.note!.isNotEmpty) {
        buffer.writeln('Note: ${h.note}');
      }
      buffer.writeln();
    }
    return buffer.toString();
  }
}
