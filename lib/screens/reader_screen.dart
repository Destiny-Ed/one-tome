import 'dart:io';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../providers/book_provider.dart';
import '../providers/reader_preferences_provider.dart';
import '../providers/highlight_provider.dart';

class ReaderScreen extends StatefulWidget {
  final Book? bookOverride;
  final bool trackProgress;

  const ReaderScreen({super.key, this.bookOverride, this.trackProgress = true});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final _audioPlayer = AudioPlayer();
  bool _dialogShowing = false;
  int _currentPage = 1;
  String? _selectedText;
  final _controller = PdfViewerController();
  late Book _book;
  bool _fileExists = true;

  @override
  void initState() {
    super.initState();
    final provider = context.read<BookProvider>();
    _book = widget.bookOverride ?? provider.activeBook!;
    _currentPage = _book.currentPage > 0 ? _book.currentPage : 1;
    _checkFile();
  }

  Future<void> _checkFile() async {
    final exists = await File(_book.filePath).exists();
    if (mounted) setState(() => _fileExists = exists);
  }

  @override
  void dispose() {
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
    if (!widget.trackProgress || _dialogShowing) return;
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

  void _createHighlightFromSelection() {
    if (_selectedText == null || _selectedText!.trim().isEmpty) return;

    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Highlight'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400, maxWidth: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _selectedText!,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Add a note (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await context.read<HighlightProvider>().addHighlight(
                    bookId: _book.id,
                    page: _currentPage,
                    text: _selectedText!.trim(),
                    note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                  );
              if (ctx.mounted) Navigator.pop(ctx);
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Highlight saved')));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showNotes() {
    final highlights = context.read<HighlightProvider>().forBook(_book.id);
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
                final text = context.read<HighlightProvider>().exportForBook(_book.id, _book.title);
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

    if (!_fileExists) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('PDF file not found. It may have been moved or deleted.')),
      );
    }

    if (widget.trackProgress && (bookProvider.activeBook == null || bookProvider.activeBook!.isDoneForToday)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (widget.trackProgress) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndShowGoalDialog());
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: readerPrefs.showControls
          ? AppBar(
              backgroundColor: Colors.black.withOpacity(0.7),
              title: Text(_book.title, overflow: TextOverflow.ellipsis),
              actions: [
                IconButton(
                  icon: Icon(readerPrefs.soundEnabled ? Icons.volume_up : Icons.volume_off),
                  onPressed: () => readerPrefs.setSoundEnabled(!readerPrefs.soundEnabled),
                ),
                if (_selectedText != null && _selectedText!.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.highlight),
                    tooltip: 'Highlight selection',
                    onPressed: _createHighlightFromSelection,
                  ),
                IconButton(
                  icon: const Icon(Icons.notes),
                  tooltip: 'Notes',
                  onPressed: _showNotes,
                ),
                if (widget.trackProgress)
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
                child: PdfViewer.file(
                  _book.filePath,
                  controller: _controller,
                  initialPageNumber: _currentPage,
                  params: PdfViewerParams(
                    layoutPages: (pages, params) {
                      final maxWidth = pages.fold<double>(0, (prev, page) => math.max(prev, page.width));
                      final pageLayouts = <Rect>[];
                      double y = params.margin;
                      for (final page in pages) {
                        final x = (maxWidth - page.width) / 2 + params.margin;
                        pageLayouts.add(Rect.fromLTWH(x, y, page.width, page.height));
                        y += page.height + params.margin * 2;
                      }
                      return PdfPageLayout(
                        pageLayouts: pageLayouts,
                        documentSize: Size(maxWidth + params.margin * 2, y),
                      );
                    },
                    textSelectionParams: PdfTextSelectionParams(
                      onTextSelectionChange: (selection) async {
                        if (selection.isCopyAllowed) {
                          final text = await selection.getSelectedText();
                          if (mounted) setState(() => _selectedText = text);
                        }
                      },
                    ),
                    onPageChanged: (page) {
                      if (page == null) return;
                      setState(() => _currentPage = page);
                      if (widget.trackProgress) {
                        bookProvider.updateProgress(page);
                      }
                      _playPageSound();
                      HapticFeedback.selectionClick();
                    },
                  ),
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
