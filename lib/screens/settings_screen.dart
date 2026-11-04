import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/book_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/app_bottom_sheet.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _editGoal(BuildContext context, BookProvider provider) {
    final controller = TextEditingController(text: provider.dailyGoalPages.toString());
    AppBottomSheet.show(
      context: context,
      title: 'Daily reading goal',
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Pages per day',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () {
            final pages = int.tryParse(controller.text) ?? provider.dailyGoalPages;
            provider.updateDailyGoal(pages.clamp(5, 200));
            Navigator.pop(context);
          },
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _confirmClear(BuildContext context) {
    AppBottomSheet.show(
      context: context,
      title: 'Clear all data?',
      child: const Text('This will remove your current book, history, streak, and reset onboarding. This cannot be undone.'),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: () async {
            await context.read<BookProvider>().clearAllData();
            if (context.mounted) {
              Navigator.pop(context);
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            }
          },
          child: const Text('Clear everything'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final bookProvider = context.watch<BookProvider>();
    final notificationProvider = context.watch<NotificationProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(
            title: Text('Settings'),
            pinned: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _GlassSection(
                  title: 'Appearance',
                  children: [
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
                  ],
                ),
                const SizedBox(height: 16),
                _GlassSection(
                  title: 'Reading',
                  children: [
                    ListTile(
                      title: const Text('Daily goal'),
                      subtitle: Text('${bookProvider.dailyGoalPages} pages'),
                      trailing: const Icon(Icons.edit),
                      onTap: () => _editGoal(context, bookProvider),
                    ),
                    ListTile(
                      title: const Text('Current streak'),
                      subtitle: Text('${bookProvider.streak} day${bookProvider.streak == 1 ? '' : 's'}'),
                    ),
                    SwitchListTile(
                      title: const Text('Daily reminder'),
                      subtitle: Text(notificationProvider.enabled ? notificationProvider.time.format(context) : 'Off'),
                      value: notificationProvider.enabled,
                      onChanged: notificationProvider.setEnabled,
                    ),
                    if (notificationProvider.enabled)
                      ListTile(
                        title: const Text('Reminder time'),
                        trailing: Text(notificationProvider.time.format(context)),
                        onTap: () async {
                          final picked = await showTimePicker(context: context, initialTime: notificationProvider.time);
                          if (picked != null) notificationProvider.setTime(picked);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _GlassSection(
                  title: 'Data',
                  children: [
                    ListTile(
                      title: const Text('Clear all data'),
                      subtitle: const Text('Reset onboarding and remove all books'),
                      leading: const Icon(Icons.delete_forever, color: Colors.red),
                      onTap: () => _confirmClear(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _GlassSection(
                  title: 'About',
                  children: const [
                    ListTile(
                      title: Text('OneTome'),
                      subtitle: Text('One book. Finish it.\nLocal-first PDF reader'),
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _GlassSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ),
              ...children,
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
