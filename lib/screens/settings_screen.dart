import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/book_provider.dart';
import '../providers/notification_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_sheet.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _editGoal(BuildContext context, BookProvider provider) {
    final controller = TextEditingController(text: provider.dailyGoalPages.toString());
    AppBottomSheet.show(
      context: context,
      title: 'Daily reading goal',
      subtitle: 'How many pages do you want to aim for each day?',
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
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _confirmClear(BuildContext context) {
    AppBottomSheet.show(
      context: context,
      title: 'Clear all data?',
      subtitle: 'This cannot be undone.',
      child: const Text('This will remove your current book, history, streak, and reset onboarding.'),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
      backgroundColor: AppTheme.background(context),
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Settings'),
            pinned: true,
            backgroundColor: AppTheme.background(context),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _Section(
                  title: 'Appearance',
                  children: [
                    _ThemeOption(
                      icon: Icons.brightness_auto,
                      label: 'System',
                      selected: themeProvider.themeMode == ThemeMode.system,
                      onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                    ),
                    _ThemeOption(
                      icon: Icons.light_mode_outlined,
                      label: 'Light',
                      selected: themeProvider.themeMode == ThemeMode.light,
                      onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                    ),
                    _ThemeOption(
                      icon: Icons.dark_mode_outlined,
                      label: 'Dark',
                      selected: themeProvider.themeMode == ThemeMode.dark,
                      onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _Section(
                  title: 'Reading',
                  children: [
                    _SettingRow(
                      icon: Icons.flag_outlined,
                      title: 'Daily goal',
                      subtitle: '${bookProvider.dailyGoalPages} pages',
                      onTap: () => _editGoal(context, bookProvider),
                    ),
                    _SettingRow(
                      icon: Icons.local_fire_department_outlined,
                      title: 'Current streak',
                      subtitle: '${bookProvider.streak} day${bookProvider.streak == 1 ? '' : 's'}',
                    ),
                    _SettingRow(
                      icon: Icons.notifications_none,
                      title: 'Daily reminder',
                      subtitle: notificationProvider.enabled ? notificationProvider.time.format(context) : 'Off',
                      trailing: Switch(
                        value: notificationProvider.enabled,
                        activeColor: AppTheme.primary,
                        onChanged: notificationProvider.setEnabled,
                      ),
                    ),
                    if (notificationProvider.enabled)
                      _SettingRow(
                        icon: Icons.access_time,
                        title: 'Reminder time',
                        subtitle: notificationProvider.time.format(context),
                        onTap: () async {
                          final picked = await showTimePicker(context: context, initialTime: notificationProvider.time);
                          if (picked != null) notificationProvider.setTime(picked);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                _Section(
                  title: 'Data',
                  children: [
                    _SettingRow(
                      icon: Icons.delete_outline,
                      title: 'Clear all data',
                      subtitle: 'Reset onboarding and remove all books',
                      iconColor: Colors.red,
                      onTap: () => _confirmClear(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _Section(
                  title: 'About',
                  children: const [
                    _SettingRow(
                      icon: Icons.auto_stories_outlined,
                      title: 'OneTome',
                      subtitle: 'One book. Finish it.\nLocal-first PDF reader',
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

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary(context),
              letterSpacing: 0.3,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Color? iconColor;
  final VoidCallback? onTap;

  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppTheme.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor ?? AppTheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary(context))),
                  ],
                ),
              ),
              if (trailing != null) trailing! else if (onTap != null) Icon(Icons.chevron_right, color: AppTheme.textSecondary(context), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppTheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textPrimary(context))),
              ),
              if (selected)
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
