import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/book_provider.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  PdfController? _controller;
  final _audioPlayer = AudioPlayer();
  bool _soundEnabled = true;
  double _brightness = 1.0;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    final book = context.read<BookProvider>().activeBook;
    if (book != null && !book.isDoneForToday) {
      _controller = PdfController(
        document: PdfDocument.openFile(book.filePath),
        initialPage: book.currentPage > 0 ? book.currentPage : 1,
      );
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _soundEnabled = prefs.getBool('reader_sound') ?? true;
        _brightness = prefs.getDouble('reader_brightness') ?? 1.0;
      });
    }
  }

  Future<void> _saveSound(bool value) async {
    setState(() => _soundEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reader_sound', value);
  }

  Future<void> _saveBrightness(double value) async {
    setState(() => _brightness = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('reader_brightness', value);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playPageSound() async {
    if (!_soundEnabled) return;
    try {
      await _audioPlayer.play(AssetSource('sounds/page_turn.mp3'));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookProvider>();
    final book = provider.activeBook;

    if (book == null || book.isDoneForToday || _controller == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _showControls
          ? AppBar(
              backgroundColor: Colors.black.withOpacity(0.7),
              title: Text(book.title, overflow: TextOverflow.ellipsis),
              actions: [
                IconButton(
                  icon: Icon(_soundEnabled ? Icons.volume_up : Icons.volume_off),
                  tooltip: 'Page turn sound',
                  onPressed: () => _saveSound(!_soundEnabled),
                ),
                IconButton(
                  icon: const Icon(Icons.done_all),
                  tooltip: 'Done for today',
                  onPressed: () async {
                    await provider.markDoneForToday();
                  },
                ),
              ],
            )
          : null,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => setState(() => _showControls = !_showControls),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(1 - _brightness),
                BlendMode.darken,
              ),
              child: PdfView(
                controller: _controller!,
                onPageChanged: (page) {
                  provider.updateProgress(page);
                  _playPageSound();
                },
              ),
            ),
          ),
          if (_showControls)
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
                            value: _brightness,
                            min: 0.3,
                            max: 1.0,
                            onChanged: _saveBrightness,
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
