import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  PdfController? _controller;
  final _audioPlayer = AudioPlayer();

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
      appBar: AppBar(
        title: Text(book.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Done for today',
            onPressed: () async {
              await provider.markDoneForToday();
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: PdfView(
        controller: _controller!,
        onPageChanged: (page) {
          provider.updateProgress(page);
          _playPageSound();
        },
      ),
    );
  }
}
