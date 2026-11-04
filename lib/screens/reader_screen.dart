import 'dart:io';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../providers/book_provider.dart';
import '../providers/reader_preferences_provider.dart';
import '../providers/highlight_provider.dart';
import '../widgets/app_bottom_sheet.dart';

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

  Future<void> _replacePdf() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result == null || result.files.single.path == null) return;
    final provider = context.read<BookProvider>();
    bool ok = false;
    if (widget.bookOverride != null) {
      ok = await provider.replacePdfForHistoryBook(_book.id, result.files.single.path!);
    } else {
      ok = await provider.replacePdfForActiveBook(result.files.single.path!);
    }
    if (ok && mounted) {
      _book = widget.bookOverride != null
          ? provider.history.firstWhere((b) => b.id == _book.id)
          : provider.activeBook!;
      setState(() => _fileExists = true);
    }
  }

  Future<void> _deleteBook() async {
    final provider = context.read<BookProvider>();
    if (widget.bookOverride != null) {
      await provider.deleteHistoryBook(_book.id);
    } else {
      await provider.deleteActiveBook();
    }
    if (mounted) Navigator.pop(context);
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

    final result = await AppBottomSheet.show<bool>(
      context: context,
      title: 'Daily goal reached',
      child: Text('You\'ve read ${provider.dailyGoalPages} pages today. Keep going or mark done for today?'),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: const Text('Continue'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: const Text('Done for today'),
        ),
      ],
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
    AppBottomSheet.show(
      context: context,
      title: 'Highlight',
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
      actions: [
        FilledButton(
          onPressed: () async {
            await context.read<HighlightProvider>().addHighlight(
                  bookId: _book.id,
                  page: _currentPage,
                  text: _selectedText!.trim(),
                  note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                );
            if (mounted) Navigator.pop(context);
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Highlight saved')));
          },
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _showNotes() {
    final highlights = context.read<HighlightProvider>().forBook(_book.id);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          builder: (_, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Notes', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
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
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: const Text('Export notes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PdfPageLayout _buildLayout(List<PdfPage> pages, PdfViewerParams params, ReadingLayout layout) {
    final pageLayouts = <Rect>[];
    if (layout == ReadingLayout.horizontal) {
      final maxHeight = pages.fold<double>(0, (prev, page) => math.max(prev, page.height));
      double x = params.margin;
      for (final page in pages) {
        final y = (maxHeight - page.height) / 2 + params.margin;
        pageLayouts.add(Rect.fromLTWH(x, y, page.width, page.height));
        x += page.width + params.margin * 2;
      }
      return PdfPageLayout(
        pageLayouts: pageLayouts,
        documentSize: Size(x, maxHeight + params.margin * 2),
      );
    } else {
      final maxWidth = pages.fold<double>(0, (prev, page) => math.max(prev, page.width));
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookProvider = context.watch<BookProvider>();
    final readerPrefs = context.watch<ReaderPreferencesProvider>();

    if (!_fileExists) {
      return Scaffold(
        appBar: AppBar(title: const Text('PDF missing')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 72, color: Colors.orange),
                const SizedBox(height: 24),
                const Text(
                  'PDF file not found.\nIt may have been moved or deleted.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _replacePdf,
                  icon: const Icon(Icons.file_upload),
                  label: const Text('Replace PDF'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _deleteBook,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete this book'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
              ],
            ),
          ),
        ),
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
                  icon: Icon(readerPrefs.layout == ReadingLayout.vertical ? Icons.swap_vert : Icons.swap_horiz),
                  tooltip: 'Toggle layout',
                  onPressed: () {
                    final next = readerPrefs.layout == ReadingLayout.vertical
                        ? ReadingLayout.horizontal
                        : ReadingLayout.vertical;
                    readerPrefs.setLayout(next);
                    _controller.invalidate();
                  },
                ),
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
                    layoutPages: (pages, params) => _buildLayout(pages, params, readerPrefs.layout),
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
