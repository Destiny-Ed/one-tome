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

  @override
  void initState() {
    super.initState();
    final book = context.read<BookProvider>().activeBook;
    if (book != null) {
      _controller = PdfController(
        document: PdfDocument.openFile(book.filePath),
        initialPage: book.currentPage > 0 ? book.currentPage : 1,
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookProvider>();
    final book = provider.activeBook;
    if (book == null || _controller == null) {
      return const Scaffold(body: Center(child: Text('No active book')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(book.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            tooltip: 'Done for today',
            onPressed: book.isDoneForToday ? null : () => provider.markDoneForToday(),
          ),
        ],
      ),
      body: PdfView(
        controller: _controller!,
        onPageChanged: (page) {
          provider.updateProgress(page);
        },
      ),
    );
  }
}
