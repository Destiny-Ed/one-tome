class Highlight {
  final String id;
  final String bookId;
  final int page;
  final String text;
  final String? note;
  final DateTime createdAt;

  Highlight({
    required this.id,
    required this.bookId,
    required this.page,
    required this.text,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookId': bookId,
        'page': page,
        'text': text,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Highlight.fromJson(Map<String, dynamic> json) => Highlight(
        id: json['id'],
        bookId: json['bookId'],
        page: json['page'],
        text: json['text'],
        note: json['note'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}
