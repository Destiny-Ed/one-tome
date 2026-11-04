import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import '../providers/reader_preferences_provider.dart';
import '../providers/highlight_provider.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  PdfController? _controller;
  final _audioPlayer = AudioPlayer();
  bool _dialogShowing = false;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    final book = context.read<BookProvider>().activeBook;
    if (book != null && !book.isDoneForToday) {
      _currentPage = book.currentPage > 0 ? book.currentPage : 1;
      _controller = PdfController(
        document: PdfDocument.openFile(book.filePath),
        initialPage: _currentPage,
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playPageSound() async {
    final prefs = context.read<ReaderPreferencesProvider>();
    if (!prefs.soundEnabled) return;
    try {
      await _audioPlayer.play(AssetSource('sounds/page_turn.mp3'));
    } catch (_) {}
  }

  Future<void> _checkAndShowGoalDialog() async {
    if (_dialogShowing) return;
    final provider = context.read<BookProvider>();
    if (!provider.shouldShowGoalDialog) return;

    _dialogShowing = true;
    await provider.markGoalDialogShown();

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Daily goal reached'),
        content: Text('You\'ve read ${provider.dailyGoalPages} pages today. Keep going or mark done for today?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Done for today'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    _dialogShowing = false;

    if (result == false && mounted) {
      await provider.markDoneForToday();
      if (mounted) Navigator.pop(context);
    }
  }

  void _addHighlight() {
    final book = context.read<BookProvider>().activeBook;
    if (book == null) return;
    final textController = TextEditingController();
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add highlight'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: textController, decoration: const InputDecoration(labelText: 'Highlighted text')),
            TextField(controller: noteController, decoration: const InputDecoration(labelText: 'Note (optional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (textController.text.trim().isEmpty) return;
              await context.read<HighlightProvider>().addHighlight(
                    bookId: book.id,
                    page: _currentPage,
                    text: textController.text.trim(),
                    note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                  );
              if (ctx.mounted) Navigator.pop(ctx);
              HapticFeedback.lightImpact();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showNotes() {
    final book = context.read<BookProvider>().activeBook;
    if (book == null) return;
    final highlights = context.read<HighlightProvider>().forBook(book.id);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: [
            Text('Notes', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (highlights.isEmpty)
              const Padding(padding: EdgeInsets.all(24), child: Text('No notes yet'))
            else
              ...highlights.map((h) => ListTile(
                    title: Text(h.text),
                    subtitle: Text('Page ${h.page}${h.note != null ? '\n${h.note}' : ''}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => context.read<HighlightProvider>().removeHighlight(h.id),
                    ),
                  )),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final text = context.read<HighlightProvider>().exportForBook(book.id, book.title);
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notes copied to clipboard')));
              },
              child: const Text('Export notes'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookProvider = context.watch<BookProvider>();
    final readerPrefs = context.watch<ReaderPreferencesProvider>();
    final book = bookProvider.activeBook;

    if (book == null || book.isDoneForToday || _controller == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndShowGoalDialog());

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: readerPrefs.showControls
          ? AppBar(
              backgroundColor: Colors.black.withOpacity(0.7),
              title: Text(book.title, overflow: TextOverflow.ellipsis),
              actions: [
                IconButton(
                  icon: Icon(readerPrefs.soundEnabled ? Icons.volume_up : Icons.volume_off),
                  onPressed: () => readerPrefs.setSoundEnabled(!readerPrefs.soundEnabled),
                ),
                IconButton(
                  icon: const Icon(Icons.highlight),
                  tooltip: 'Add highlight',
                  onPressed: _addHighlight,
                ),
                IconButton(
                  icon: const Icon(Icons.notes),
                  tooltip: 'Notes',
                  onPressed: _showNotes,
                ),
                IconButton(
                  icon: const Icon(Icons.done_all),
                  tooltip: 'Done for today',
                  onPressed: () async {
                    await bookProvider.markDoneForToday();
                    if (mounted) Navigator.pop(context);
                  },
                ),
              ],
            )
          : null,
      body: Stack(
        children: [
          GestureDetector(
            onTap: readerPrefs.toggleControls,
            child: Padding(
              padding: EdgeInsets.all(readerPrefs.margin),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(1 - readerPrefs.brightness),
                  BlendMode.darken,
                ),
                child: PdfView(
                  controller: _controller!,
                  onPageChanged: (page) {
                    setState(() => _currentPage = page);
                    bookProvider.updateProgress(page);
                    _playPageSound();
                    HapticFeedback.selectionClick();
                  },
                ),
              ),
            ),
          ),
          if (readerPrefs.showControls)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.85),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.brightness_low, color: Colors.white70, size: 18),
                        Expanded(
                          child: Slider(
                            value: readerPrefs.brightness,
                            min: 0.3,
                            max: 1.0,
                            onChanged: readerPrefs.setBrightness,
                            activeColor: Colors.white,
                            inactiveColor: Colors.white24,
                          ),
                        ),
                        const Icon(Icons.brightness_high, color: Colors.white70, size: 18),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('Margin', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Expanded(
                          child: Slider(
                            value: readerPrefs.margin,
                            min: 0,
                            max: 40,
                            onChanged: readerPrefs.setMargin,
                            activeColor: Colors.white,
                            inactiveColor: Colors.white24,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
