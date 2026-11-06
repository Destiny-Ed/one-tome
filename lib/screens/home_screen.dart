import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../providers/book_provider.dart';
import '../theme/app_theme.dart';
import 'import_screen.dart';
import 'reader_screen.dart';
import 'physical_reader_screen.dart';
import 'finished_book_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookProvider>();
    final book = provider.activeBook;
    final history = provider.history;

    if (provider.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('OneTome'),
            centerTitle: false,
            pinned: true,
            backgroundColor: AppTheme.background(context),
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (provider.streak > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department, color: Colors.orange, size: 18),
                          const SizedBox(width: 8),
                          Text('${provider.streak}-day streak', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.orange)),
                        ],
                      ),
                    ),
                  ),
                if (book != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface(context),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.today, color: AppTheme.primary, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          'Today: ${provider.pagesReadToday} / ${provider.dailyGoalPages} pages',
                          style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context)),
                        ),
                      ],
                    ),
                  ),
                  _ActiveBookView(book: book, dailyGoal: provider.dailyGoalPages),
                  const SizedBox(height: 28),
                ] else
                  const _EmptyState(),
                if (history.isNotEmpty) ...[
                  Text('Finished books', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
                  const SizedBox(height: 12),
                  ...history.map((b) => _FinishedBookCard(book: b)),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final Book book;
  const _TypeChip({required this.book});

  @override
  Widget build(BuildContext context) {
    final isPhysical = book.isPhysical;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPhysical ? Colors.teal.withOpacity(0.12) : AppTheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isPhysical ? 'Physical' : 'PDF',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isPhysical ? Colors.teal.shade700 : AppTheme.primary,
        ),
      ),
    );
  }
}

class _ActiveBookView extends StatelessWidget {
  final Book book;
  final int dailyGoal;
  const _ActiveBookView({required this.book, required this.dailyGoal});

  String _estimateCompletion() {
    final remaining = book.totalPages - book.currentPage;
    if (remaining <= 0) return 'Completed';
    if (dailyGoal <= 0) return 'Set a daily goal';

    final daysLeft = (remaining / dailyGoal).ceil();
    final finishDate = DateTime.now().add(Duration(days: daysLeft));
    final started = book.addedAt;
    final startedStr = DateFormat('MMM d').format(started);
    final finishStr = DateFormat('MMM d, yyyy').format(finishDate);

    return 'Started $startedStr \u2022 Est. finish $finishStr\n(~$daysLeft day${daysLeft == 1 ? '' : 's'} at $dailyGoal pages/day)';
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = book.isDoneForToday;
    final thumb = book.thumbnailPath;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (thumb != null && File(thumb).existsSync())
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(File(thumb), width: 56, height: 80, fit: BoxFit.cover),
                )
              else
                Container(
                  width: 56,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(book.isPhysical ? Icons.menu_book : Icons.auto_stories, color: AppTheme.primary),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
                    const SizedBox(height: 4),
                    _TypeChip(book: book),
                    if (book.author != null) ...[
                      const SizedBox(height: 4),
                      Text(book.author!, style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: book.progress,
              minHeight: 6,
              backgroundColor: Colors.grey.withOpacity(0.2),
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          Text('${book.currentPage} of ${book.totalPages} pages', style: TextStyle(color: AppTheme.textSecondary(context))),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.background(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.schedule, size: 18, color: AppTheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _estimateCompletion(),
                    style: TextStyle(color: AppTheme.textPrimary(context), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          if (isLocked) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_clock, color: Colors.amber, size: 18),
                  SizedBox(width: 8),
                  Expanded(child: Text('Done for today. Come back tomorrow to continue.')),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: isLocked
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => book.isPhysical ? const PhysicalReaderScreen() : const ReaderScreen(),
                      ),
                    ),
            icon: Icon(isLocked ? Icons.lock : Icons.play_arrow),
            label: Text(isLocked ? 'Locked until tomorrow' : 'Continue reading'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.accent : AppTheme.navy,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinishedBookCard extends StatelessWidget {
  final Book book;
  const _FinishedBookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    final thumb = book.thumbnailPath;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => FinishedBookScreen(book: book)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                if (thumb != null && File(thumb).existsSync())
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(File(thumb), width: 36, height: 48, fit: BoxFit.cover),
                  )
                else
                  Container(
                    width: 36,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.check, color: Colors.green, size: 18),
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(book.title, style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _TypeChip(book: book),
                          const SizedBox(width: 8),
                          Text(
                            'Finished ${book.completedAt != null ? DateFormat('MMM d, yyyy').format(book.completedAt!) : ''}',
                            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary(context)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppTheme.textSecondary(context), size: 20),
              ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_stories_rounded, size: 48, color: AppTheme.primary),
          ),
          const SizedBox(height: 24),
          Text('One book. Finish it.', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
          const SizedBox(height: 8),
          Text('Import a PDF or track a physical book.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary(context))),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportScreen())),
            icon: const Icon(Icons.add),
            label: const Text('Start a book'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.accent : AppTheme.navy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}
