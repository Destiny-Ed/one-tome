import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../providers/highlight_provider.dart';
import 'reader_screen.dart';

class FinishedBookScreen extends StatelessWidget {
  final Book book;
  const FinishedBookScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final highlights = context.watch<HighlightProvider>().forBook(book.id);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Finished book')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(book.title, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Finished ${book.completedAt != null ? DateFormat('MMMM d, yyyy').format(book.completedAt!) : ''}',
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
          ),
          const SizedBox(height: 24),
          _InfoRow(label: 'Total pages', value: '${book.totalPages}'),
          _InfoRow(label: 'Started', value: DateFormat('MMM d, yyyy').format(book.addedAt)),
          if (book.completedAt != null)
            _InfoRow(
              label: 'Days to finish',
              value: '${book.completedAt!.difference(book.addedAt).inDays + 1}',
            ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReaderScreen(bookOverride: book, trackProgress: false),
                ),
              );
            },
            icon: const Icon(Icons.menu_book),
            label: const Text('Read again (no tracking)'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
          const SizedBox(height: 32),
          Text('Notes & Highlights', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          if (highlights.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('No notes saved for this book'),
            )
          else
            ...highlights.map((h) => Card(
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      title: Text(h.text),
                      subtitle: Text('Page ${h.page}${h.note != null ? '\n${h.note}' : ''}'),
                    ),
                  ),
                )),
          if (highlights.isNotEmpty) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                final text = context.read<HighlightProvider>().exportForBook(book.id, book.title);
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notes copied')));
              },
              child: const Text('Export notes'),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
