import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import '../providers/highlight_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_sheet.dart';
import 'celebration_screen.dart';

class PhysicalReaderScreen extends StatefulWidget {
  const PhysicalReaderScreen({super.key});

  @override
  State<PhysicalReaderScreen> createState() => _PhysicalReaderScreenState();
}

class _PhysicalReaderScreenState extends State<PhysicalReaderScreen> {
  late TextEditingController _pageController;
  bool _dialogShowing = false;

  @override
  void initState() {
    super.initState();
    final book = context.read<BookProvider>().activeBook!;
    _pageController = TextEditingController(text: book.currentPage.toString());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _saveProgress() async {
    final book = context.read<BookProvider>().activeBook;
    if (book == null || book.isDoneForToday) return;

    final page = int.tryParse(_pageController.text.trim()) ?? book.currentPage;
    final isComplete = page >= book.totalPages && book.totalPages > 0;

    if (isComplete) {
      await _confirmComplete(page);
      return;
    }

    await context.read<BookProvider>().updateProgress(page);
    if (mounted) await _checkGoal();
  }

  Future<void> _confirmComplete(int page) async {
    if (_dialogShowing) return;
    _dialogShowing = true;

    final result = await AppBottomSheet.show<bool>(
      context: context,
      title: 'Book completed?',
      subtitle: 'You entered the last page.',
      child: const Text('Mark this book as finished and celebrate, or keep it open and continue later.'),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Yes, complete book'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Not yet'),
        ),
      ],
    );

    _dialogShowing = false;

    if (!mounted) return;

    if (result == true) {
      await context.read<BookProvider>().updateProgress(page);
      await _complete();
    } else {
      // Save progress but do not complete
      await context.read<BookProvider>().updateProgress(page);
      if (mounted) await _checkGoal();
    }
  }

  Future<void> _checkGoal() async {
    if (_dialogShowing) return;
    final provider = context.read<BookProvider>();
    if (!provider.shouldShowGoalDialog) return;

    _dialogShowing = true;
    await provider.markGoalDialogShown();
    if (!mounted) return;

    final result = await AppBottomSheet.show<bool>(
      context: context,
      title: 'Daily goal reached',
      subtitle: 'You\'ve hit your reading target for today.',
      child: const Text('You can keep going, or mark this book done for today and continue tomorrow.'),
      actions: [
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continue')),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: () => Navigator.pop(context, false), child: const Text('Done for today')),
      ],
    );
    _dialogShowing = false;
    if (result == false && mounted) {
      await context.read<BookProvider>().markDoneForToday();
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _complete() async {
    final provider = context.read<BookProvider>();
    final title = provider.activeBook!.title;
    await provider.completeBook();
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => CelebrationScreen(bookTitle: title)),
    );
  }

  void _addNote() {
    final book = context.read<BookProvider>().activeBook!;
    final pageCtrl = TextEditingController(text: book.currentPage.toString());
    final textCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    AppBottomSheet.show(
      context: context,
      title: 'Add note',
      subtitle: 'Save a thought from today\'s reading.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: pageCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Page', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: textCtrl,
            decoration: const InputDecoration(labelText: 'What stood out?', border: OutlineInputBorder()),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteCtrl,
            decoration: const InputDecoration(labelText: 'Your note (optional)', border: OutlineInputBorder()),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () async {
            final text = textCtrl.text.trim();
            if (text.isEmpty) return;
            final page = int.tryParse(pageCtrl.text.trim()) ?? book.currentPage;
            await context.read<HighlightProvider>().addHighlight(
                  bookId: book.id,
                  page: page,
                  text: text,
                  note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                );
            if (mounted) Navigator.pop(context);
            HapticFeedback.lightImpact();
          },
          child: const Text('Save note'),
        ),
      ],
    );
  }

  void _showNotes() {
    final book = context.read<BookProvider>().activeBook!;
    final highlights = context.read<HighlightProvider>().forBook(book.id);

    AppBottomSheet.show(
      context: context,
      title: 'Notes',
      subtitle: highlights.isEmpty ? 'No notes yet' : '${highlights.length} saved',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (highlights.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Add a note while you read.'),
            )
          else
            ...highlights.map((h) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(h.text),
                  subtitle: Text('Page ${h.page}${h.note != null ? '\n${h.note}' : ''}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => context.read<HighlightProvider>().removeHighlight(h.id),
                  ),
                )),
        ],
      ),
      actions: highlights.isEmpty
          ? null
          : [
              OutlinedButton(
                onPressed: () {
                  final text = context.read<HighlightProvider>().exportForBook(book.id, book.title);
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notes copied')));
                },
                child: const Text('Export notes'),
              ),
            ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookProvider>();
    final book = provider.activeBook;
    if (book == null) {
      return const Scaffold(body: Center(child: Text('No active book')));
    }

    final isLocked = book.isDoneForToday;

    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        title: Text(book.title),
        actions: [
          IconButton(icon: const Icon(Icons.notes), onPressed: _showNotes),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (book.author != null)
                  Text(book.author!, style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 16)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: book.progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text('${book.currentPage} of ${book.totalPages} pages',
                    style: TextStyle(color: AppTheme.textSecondary(context))),
                const SizedBox(height: 28),
                Text('Update your page', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
                const SizedBox(height: 12),
                TextField(
                  controller: _pageController,
                  enabled: !isLocked,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Current page',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: isLocked ? null : _saveProgress,
                  child: const Text('Save progress'),
                ),
                if (isLocked) ...[
                  const SizedBox(height: 16),
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
                        Expanded(child: Text('Done for today. Come back tomorrow.')),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                OutlinedButton.icon(
                  onPressed: _addNote,
                  icon: const Icon(Icons.add),
                  label: const Text('Add a note'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: isLocked
                      ? null
                      : () async {
                          await context.read<BookProvider>().markDoneForToday();
                          if (mounted) Navigator.pop(context);
                        },
                  icon: const Icon(Icons.done_all),
                  label: const Text('Done for today'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
