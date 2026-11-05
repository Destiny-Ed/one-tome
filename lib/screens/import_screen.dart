import 'dart:io';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import '../theme/app_theme.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  String? _path;
  final _titleController = TextEditingController();
  int _pages = 0;
  ui.Image? _preview;
  bool _detecting = false;

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      setState(() {
        _path = path;
        _titleController.text = result.files.single.name.replaceAll('.pdf', '');
        _detecting = true;
        _preview = null;
      });
      try {
        final doc = await PdfDocument.openFile(path);
        final pages = doc.pages.length;
        ui.Image? preview;
        if (doc.pages.isNotEmpty) {
          final page = doc.pages.first;
          preview = await page.renderForDisplay(
            width: 160,
            height: (page.height / page.width * 160).round(),
            backgroundColor: 0xffffffff,
          );
        }
        await doc.dispose();
        if (mounted) {
          setState(() {
            _pages = pages;
            _preview = preview;
            _detecting = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _detecting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not read this PDF.')),
          );
        }
      }
    }
  }

  Future<void> _import() async {
    if (_path == null || _pages <= 0) return;
    final ok = await context.read<BookProvider>().importBook(_path!, _titleController.text.trim(), _pages);
    if (ok && mounted) {
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Finish your current book first')));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _preview?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(title: const Text('Import a book')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_preview != null)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: RawImage(image: _preview, width: 120, fit: BoxFit.contain),
                  ),
                )
              else
                Icon(Icons.picture_as_pdf_outlined, size: 80, color: AppTheme.primary.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text('Choose a PDF', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'We\'ll copy it locally so you can read offline.',
                style: TextStyle(color: AppTheme.textSecondary(context)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              FilledButton.tonalIcon(
                onPressed: _pick,
                icon: const Icon(Icons.folder_open),
                label: const Text('Browse PDF'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              ),
              if (_detecting) ...[
                const SizedBox(height: 28),
                const Center(child: CircularProgressIndicator()),
              ],
              if (_path != null && !_detecting) ...[
                const SizedBox(height: 28),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Book title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_stories_outlined, color: AppTheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '$_pages pages',
                          style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context)),
                        ),
                      ),
                      Text('Auto-detected', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context))),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _import,
                  child: const Text('Start this book'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
