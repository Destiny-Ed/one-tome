import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
  final _pagesController = TextEditingController(text: '300');

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _path = result.files.single.path;
        _titleController.text = result.files.single.name.replaceAll('.pdf', '');
      });
    }
  }

  Future<void> _import() async {
    if (_path == null) return;
    final pages = int.tryParse(_pagesController.text) ?? 0;
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
      appBar: AppBar(title: const Text('Import PDF')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            FilledButton.tonal(onPressed: _pick, child: const Text('Choose PDF')),
            if (_path != null) ...[
              const SizedBox(height: 24),
              TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 16),
              TextField(
                controller: _pagesController,
                decoration: const InputDecoration(labelText: 'Total pages'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),
              FilledButton(onPressed: _import, child: const Text('Start this book')),
            ],
          ],
        ),
      ),
    );
  }
}
