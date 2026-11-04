import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/book_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final bookProvider = context.watch<BookProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Appearance'),
            subtitle: Text(themeProvider.themeMode.name),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('System'),
            value: ThemeMode.system,
            groupValue: themeProvider.themeMode,
            onChanged: (v) => themeProvider.setThemeMode(v!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Light'),
            value: ThemeMode.light,
            groupValue: themeProvider.themeMode,
            onChanged: (v) => themeProvider.setThemeMode(v!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark'),
            value: ThemeMode.dark,
            groupValue: themeProvider.themeMode,
            onChanged: (v) => themeProvider.setThemeMode(v!),
          ),
          const Divider(),
          ListTile(
            title: const Text('Daily reading goal'),
            subtitle: Text('${bookProvider.dailyGoalPages} pages'),
          ),
          const Divider(),
          const ListTile(
            title: Text('About OneTome'),
            subtitle: Text('One book. Finish it.\nLocal-first PDF reader'),
          ),
        ],
      ),
    );
  }
}
