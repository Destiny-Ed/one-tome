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
import '../theme/app_theme.dart';
import '../widgets/app_bottom_sheet.dart';
import 'celebration_screen.dart';

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
  bool _nightMode = false;
  double _zoom = 1.0;

  static const _nightShiftMatrix = [
    1.15, 0.05, 0.0, 0, 25,
    0.0, 0.82, 0.0, 0, 8,
    0.0, 0.0, 0.5, 0, 0,
    0, 0, 0, 1, 0,
  ];

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

  void _goToPage(int page) {
    final target = page.clamp(1, _book.totalPages);
    _controller.goToPage(pageNumber: target);
    setState(() => _currentPage = target);
  }

  void _applyZoom(double value) {
    final clamped = value.clamp(0.6, 3.0);
    setState(() => _zoom = clamped);
    final size = _controller.viewSize;
    final center = Offset(size.width / 2, size.height / 2);
    _controller.setZoom(center, clamped);
  }

  Future<void> _markDoneAndLeave() async {
    final provider = context.read<BookProvider>();
    await provider.markDoneForToday();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _completeBook() async {
    final provider = context.read<BookProvider>();
    final title = _book.title;
    await provider.completeBook();
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => CelebrationScreen(bookTitle: title)),
    );
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
      subtitle: 'You\'ve hit your reading target for today.',
      child: const Text('You can keep going, or mark this book done for today and continue tomorrow.'),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Continue reading'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Done for today'),
        ),
      ],
    );

    _dialogShowing = false;

    if (result == false && mounted) {
      await _markDoneAndLeave();
    }
  }

  void _createHighlightFromSelection() {
    if (_selectedText == null || _selectedText!.trim().isEmpty) return;

    final noteController = TextEditingController();
    AppBottomSheet.show(
      context: context,
      title: 'Save highlight',
      subtitle: 'The selected text will be saved with an optional note.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _selectedText!,
              style: TextStyle(fontStyle: FontStyle.italic, color: AppTheme.textPrimary(context)),
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
          child: const Text('Save highlight'),
        ),
      ],
    );
  }

  void _showReaderSettings() {
    final prefs = context.read<ReaderPreferencesProvider>();

    AppBottomSheet.show(
      context: context,
      title: 'Reading settings',
      subtitle: 'Zoom, brightness, and display.',
      child: StatefulBuilder(
        builder: (ctx, setSheetState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(_nightMode ? Icons.nightlight_round : Icons.light_mode, color: AppTheme.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(_nightMode ? 'Night shift' : 'Light mode', style: TextStyle(color: AppTheme.textPrimary(ctx)))),
                Switch(
                  value: _nightMode,
                  activeColor: AppTheme.primary,
                  onChanged: (v) {
                    setState(() => _nightMode = v);
                    setSheetState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.brightness_low, size: 18),
                Expanded(
                  child: Slider(
                    value: prefs.brightness,
                    min: 0.3,
                    max: 1.0,
                    activeColor: AppTheme.primary,
                    onChanged: (v) {
                      prefs.setBrightness(v);
                      setSheetState(() {});
                    },
                  ),
                ),
                const Icon(Icons.brightness_high, size: 18),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.zoom_out, size: 18),
                Expanded(
                  child: Slider(
                    value: _zoom,
                    min: 0.6,
                    max: 3.0,
                    activeColor: AppTheme.primary,
                    onChanged: (v) {
                      _applyZoom(v);
                      setSheetState(() {});
                    },
                  ),
                ),
                const Icon(Icons.zoom_in, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(prefs.soundEnabled ? Icons.volume_up : Icons.volume_off, color: AppTheme.primary, size: 20),
                const SizedBox(width: 12),
                const Expanded(child: Text('Page turn sound')),
                Switch(
                  value: prefs.soundEnabled,
                  activeColor: AppTheme.primary,
                  onChanged: (v) {
                    prefs.setSoundEnabled(v);
                    setSheetState(() {});
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReaderActions() {
    final prefs = context.read<ReaderPreferencesProvider>();

    AppBottomSheet.show(
      context: context,
      title: 'Reading options',
      subtitle: 'Layout, notes, and today.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(prefs.layout == ReadingLayout.vertical ? Icons.swap_vert : Icons.swap_horiz, color: AppTheme.primary),
            title: const Text('Layout'),
            subtitle: Text(prefs.layout == ReadingLayout.vertical ? 'Vertical (swipe up/down)' : 'Horizontal (swipe left/right)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              final next = prefs.layout == ReadingLayout.vertical ? ReadingLayout.horizontal : ReadingLayout.vertical;
              prefs.setLayout(next);
              _controller.invalidate();
              Navigator.pop(context);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.notes, color: AppTheme.primary),
            title: const Text('Notes & highlights'),
            subtitle: const Text('View and export what you\'ve saved'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              _showNotes();
            },
          ),
          if (widget.trackProgress)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.done_all, color: AppTheme.primary),
              title: const Text('Done for today'),
              subtitle: const Text('Stop tracking for today and continue tomorrow'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                Navigator.pop(context);
                await _markDoneAndLeave();
              },
            ),
        ],
      ),
    );
  }

  void _showNotes() {
    final highlights = context.read<HighlightProvider>().forBook(_book.id);
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
              child: Text('Select text in the book and tap highlight to save.'),
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
                  final text = context.read<HighlightProvider>().exportForBook(_book.id, _book.title);
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notes copied')));
                },
                child: const Text('Export notes'),
              ),
            ],
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

  Widget _wrapNightShift(Widget child) {
    if (!_nightMode) return child;
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(_nightShiftMatrix),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookProvider = context.watch<BookProvider>();
    final readerPrefs = context.watch<ReaderPreferencesProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = _nightMode ? const Color(0xFF1A1208) : AppTheme.background(context);
    final appBarBg = _nightMode ? const Color(0xFF1A1208) : AppTheme.surface(context);
    final fg = _nightMode ? const Color(0xFFFFE8C8) : AppTheme.textPrimary(context);
    final onLastPage = _currentPage >= _book.totalPages;

    if (!_fileExists) {
      return Scaffold(
        backgroundColor: AppTheme.background(context),
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
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _deleteBook,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete this book'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (widget.trackProgress) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndShowGoalDialog());
    }

    final body = Stack(
      children: [
        GestureDetector(
          onTap: readerPrefs.toggleControls,
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
        if (readerPrefs.showControls)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: BoxDecoration(
                color: appBarBg,
                border: Border(top: BorderSide(color: _nightMode ? const Color(0xFF3D2E1A) : (isDark ? Colors.grey.shade800 : Colors.grey.shade200))),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onLastPage && widget.trackProgress) ...[
                      FilledButton.icon(
                        onPressed: _completeBook,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Complete book'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(Icons.chevron_left, color: fg),
                          onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
                        ),
                        Text('$_currentPage / ${_book.totalPages}', style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
                        IconButton(
                          icon: Icon(Icons.chevron_right, color: fg),
                          onPressed: _currentPage < _book.totalPages ? () => _goToPage(_currentPage + 1) : null,
                        ),
                        IconButton(
                          icon: Icon(Icons.zoom_out, color: fg),
                          onPressed: () {
                            _controller.zoomDown();
                            setState(() => _zoom = (_zoom - 0.2).clamp(0.6, 3.0));
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.zoom_in, color: fg),
                          onPressed: () {
                            _controller.zoomUp();
                            setState(() => _zoom = (_zoom + 0.2).clamp(0.6, 3.0));
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _nightMode ? SystemUiOverlayStyle.light : (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark),
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: appBarBg,
          foregroundColor: fg,
          title: Text(_book.title, overflow: TextOverflow.ellipsis),
          actions: [
            if (_selectedText != null && _selectedText!.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.highlight),
                tooltip: 'Highlight selection',
                onPressed: _createHighlightFromSelection,
              ),
            IconButton(
              icon: Icon(_nightMode ? Icons.nightlight_round : Icons.light_mode),
              tooltip: 'Night shift',
              onPressed: () => setState(() => _nightMode = !_nightMode),
            ),
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'Reading settings',
              onPressed: _showReaderSettings,
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              tooltip: 'More',
              onPressed: _showReaderActions,
            ),
          ],
        ),
        body: _wrapNightShift(body),
      ),
    );
  }
}
