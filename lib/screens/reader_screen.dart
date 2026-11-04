import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import '../providers/reader_preferences_provider.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  PdfController? _controller;
  final _audioPlayer = AudioPlayer();
  bool _dialogShowing = false;

  @override
  void initState() {
    super.initState();
    final book = context.read<BookProvider>().activeBook;
    if (book != null && !book.isDoneForToday) {
      _controller = PdfController(
        document: PdfDocument.openFile(book.filePath),
        initialPage: book.currentPage > 0 ? book.currentPage : 1,
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
                  tooltip: 'Page turn sound',
                  onPressed: () => readerPrefs.setSoundEnabled(!readerPrefs.soundEnabled),
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
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(1 - readerPrefs.brightness),
                BlendMode.darken,
              ),
              child: PdfView(
                controller: _controller!,
                onPageChanged: (page) {
                  bookProvider.updateProgress(page);
                  _playPageSound();
                },
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
                    const SizedBox(height: 4),
                    Text(
                      'Brightness',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
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
