import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import 'import_screen.dart';
import 'reader_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookProvider>();

    if (provider.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('OneTome'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: provider.hasActiveBook
              ? _ActiveBookCard(book: provider.activeBook!)
              : const _EmptyState(),
        ),
      ),
      floatingActionButton: provider.hasActiveBook
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportScreen())),
              label: const Text('Start a book'),
              icon: const Icon(Icons.add),
            ),
    );
  }
}

class _ActiveBookCard extends StatelessWidget {
  final dynamic book;
  const _ActiveBookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(book.title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: book.progress),
                  const SizedBox(height: 8),
                  Text('${book.currentPage} / ${book.totalPages} pages'),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReaderScreen())),
                    child: const Text('Continue reading'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('One book. Finish it.', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Text('Import a PDF to begin', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
