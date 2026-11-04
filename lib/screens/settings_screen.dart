import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/book_provider.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadReminder();
  }

  Future<void> _loadReminder() async {
    final enabled = await NotificationService.isReminderEnabled();
    final time = await NotificationService.getReminderTime();
    if (mounted) {
      setState(() {
        _reminderEnabled = enabled;
        if (time != null) _reminderTime = time;
      });
    }
  }

  Future<void> _toggleReminder(bool value) async {
    setState(() => _reminderEnabled = value);
    if (value) {
      await NotificationService.scheduleDaily(_reminderTime);
    } else {
      await NotificationService.cancel();
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _reminderTime);
    if (picked != null) {
      setState(() => _reminderTime = picked);
      if (_reminderEnabled) {
        await NotificationService.scheduleDaily(picked);
      }
    }
  }

  void _editGoal(BuildContext context, BookProvider provider) {
    final controller = TextEditingController(text: provider.dailyGoalPages.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Daily reading goal'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Pages per day'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final pages = int.tryParse(controller.text) ?? provider.dailyGoalPages;
              provider.updateDailyGoal(pages.clamp(5, 200));
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text('This will remove your current book, history, streak, and reset onboarding. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await context.read<BookProvider>().clearAllData();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            child: const Text('Clear everything'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final bookProvider = context.watch<BookProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(title: Text('Settings')),
          SliverPadding(
            padding: const EdgeInsets.all(16),
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
                      subtitle: Text(_reminderEnabled ? _reminderTime.format(context) : 'Off'),
                      value: _reminderEnabled,
                      onChanged: _toggleReminder,
                    ),
                    if (_reminderEnabled)
                      ListTile(
                        title: const Text('Reminder time'),
                        trailing: Text(_reminderTime.format(context)),
                        onTap: _pickTime,
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
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(title, style: Theme.of(context).textTheme.titleMedium),
              ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
