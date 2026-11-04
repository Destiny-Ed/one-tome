import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<BookProvider>().history;

    return Scaffold(
      appBar: AppBar(title: const Text('Finished books')),
      body: history.isEmpty
          ? const Center(child: Text('No completed books yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, i) {
                final book = history[i];
                return Card(
                  child: ListTile(
                    title: Text(book.title),
                    subtitle: Text('Finished ${book.completedAt?.toLocal().toString().split(' ')[0] ?? ''}'),
                    trailing: const Icon(Icons.check_circle, color: Colors.green),
                  ),
                );
              },
            ),
    );
  }
}
