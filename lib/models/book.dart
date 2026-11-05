import 'dart:convert';

class Book {
  final String id;
  final String title;
  String filePath;
  String? thumbnailPath;
  final int totalPages;
  int currentPage;
  bool isCompleted;
  DateTime? completedAt;
  DateTime? lastReadAt;
  DateTime? doneForTodayUntil;
  final DateTime addedAt;

  Book({
    required this.id,
    required this.title,
    required this.filePath,
    this.thumbnailPath,
    required this.totalPages,
    this.currentPage = 0,
    this.isCompleted = false,
    this.completedAt,
    this.lastReadAt,
    this.doneForTodayUntil,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  bool get isDoneForToday {
    if (doneForTodayUntil == null) return false;
    return DateTime.now().isBefore(doneForTodayUntil!);
  }

  double get progress => totalPages == 0 ? 0 : currentPage / totalPages;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'filePath': filePath,
        'thumbnailPath': thumbnailPath,
        'totalPages': totalPages,
        'currentPage': currentPage,
        'isCompleted': isCompleted,
        'completedAt': completedAt?.toIso8601String(),
        'lastReadAt': lastReadAt?.toIso8601String(),
        'doneForTodayUntil': doneForTodayUntil?.toIso8601String(),
        'addedAt': addedAt.toIso8601String(),
      };

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        id: json['id'],
        title: json['title'],
        filePath: json['filePath'],
        thumbnailPath: json['thumbnailPath'],
        totalPages: json['totalPages'] ?? 0,
        currentPage: json['currentPage'] ?? 0,
        isCompleted: json['isCompleted'] ?? false,
        completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
        lastReadAt: json['lastReadAt'] != null ? DateTime.parse(json['lastReadAt']) : null,
        doneForTodayUntil: json['doneForTodayUntil'] != null ? DateTime.parse(json['doneForTodayUntil']) : null,
        addedAt: DateTime.parse(json['addedAt']),
      );

  String toJsonString() => jsonEncode(toJson());
  factory Book.fromJsonString(String s) => Book.fromJson(jsonDecode(s));
}
