import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import 'import_screen.dart';
import 'reader_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookProvider>();
    final book = provider.activeBook;

    if (provider.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('OneTome'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  if (provider.hasActiveBook) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Finish your current book before starting another one.')),
                    );
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportScreen()));
                  }
                },
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (provider.streak > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Chip(
                        avatar: const Icon(Icons.local_fire_department, color: Colors.orange),
                        label: Text('${provider.streak}-day streak'),
                      ),
                    ),
                  book == null
                      ? const _EmptyState()
                      : _ActiveBookView(book: book, dailyGoal: provider.dailyGoalPages),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveBookView extends StatelessWidget {
  final dynamic book;
  final int dailyGoal;
  const _ActiveBookView({required this.book, required this.dailyGoal});

  @override
  Widget build(BuildContext context) {
    final isLocked = book.isDoneForToday;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(book.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              LinearProgressIndicator(value: book.progress, minHeight: 8, borderRadius: BorderRadius.circular(8)),
              const SizedBox(height: 12),
              Text('${book.currentPage} of ${book.totalPages} pages'),
              const SizedBox(height: 8),
              Text('Daily goal: $dailyGoal pages'),
              if (isLocked) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_clock, color: Colors.amber),
                      SizedBox(width: 8),
                      Expanded(child: Text('Done for today. Come back tomorrow to continue.')),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: isLocked ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReaderScreen())),
                icon: Icon(isLocked ? Icons.lock : Icons.play_arrow),
                label: Text(isLocked ? 'Locked until tomorrow' : 'Continue reading'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              ),
            ],
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
    return Column(
      children: [
        const SizedBox(height: 60),
        Icon(Icons.auto_stories_rounded, size: 100, color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
        const SizedBox(height: 24),
        Text('One book. Finish it.', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        const Text('Import a PDF to begin your first tome.', textAlign: TextAlign.center),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportScreen())),
          icon: const Icon(Icons.add),
          label: const Text('Start a book'),
        ),
      ],
    );
  }
}
