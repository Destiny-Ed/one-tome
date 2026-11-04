import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  String? _path;
  final _titleController = TextEditingController();
  final _pagesController = TextEditingController();
  bool _detecting = false;

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      setState(() {
        _path = path;
        _titleController.text = result.files.single.name.replaceAll('.pdf', '');
        _detecting = true;
      });
      try {
        final doc = await PdfDocument.openFile(path);
        final pages = doc.pages.length;
        await doc.dispose();
        if (mounted) {
          setState(() {
            _pagesController.text = pages.toString();
            _detecting = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _detecting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not read page count. Enter it manually.')),
          );
        }
      }
    }
  }

  Future<void> _import() async {
    if (_path == null) return;
    final pages = int.tryParse(_pagesController.text) ?? 0;
    if (pages <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid page count')));
      return;
    }
    final ok = await context.read<BookProvider>().importBook(_path!, _titleController.text.trim(), pages);
    if (ok && mounted) {
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Finish your current book first')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import a book')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Icon(Icons.picture_as_pdf_outlined, size: 80, color: Theme.of(context).colorScheme.primary.withOpacity(0.6)),
              const SizedBox(height: 16),
              Text('Choose a PDF', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'We\'ll copy it locally so you can read offline.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.tonalIcon(
                onPressed: _pick,
                icon: const Icon(Icons.folder_open),
                label: const Text('Browse PDF'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              ),
              if (_detecting) ...[
                const SizedBox(height: 32),
                const Center(child: CircularProgressIndicator()),
              ],
              if (_path != null && !_detecting) ...[
                const SizedBox(height: 32),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Book title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _pagesController,
                  decoration: const InputDecoration(
                    labelText: 'Total pages',
                    helperText: 'Auto-detected',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _import,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
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
