import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import '../services/notification_service.dart';
import 'main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  int _dailyGoal = 20;
  bool _enableReminder = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);

  final _pages = [
    {
      'title': 'One book. Finish it.',
      'subtitle': 'OneTome helps you focus on a single PDF until you complete it. No more unfinished books.',
      'icon': Icons.menu_book_rounded,
    },
    {
      'title': 'Daily progress that feels real',
      'subtitle': 'Mark pages done or “done for today”. Come back tomorrow and continue exactly where you left off.',
      'icon': Icons.today_rounded,
    },
    {
      'title': 'Set your reading goal',
      'subtitle': 'How many pages do you want to aim for each day?',
      'icon': Icons.flag_rounded,
    },
    {
      'title': 'Daily reminder',
      'subtitle': 'Would you like a gentle reminder to read each day?',
      'icon': Icons.notifications_active_rounded,
    },
  ];

  Future<void> _finish() async {
    await context.read<BookProvider>().completeOnboarding(dailyGoal: _dailyGoal);
    if (_enableReminder) {
      await NotificationService.scheduleDaily(_reminderTime);
    }
    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
    }
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(page['icon'] as IconData, size: 100, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 40),
                        Text(page['title'] as String, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        Text(page['subtitle'] as String, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
                        if (i == 2) ...[
                          const SizedBox(height: 32),
                          Text('$_dailyGoal pages / day', style: Theme.of(context).textTheme.titleLarge),
                          Slider(
                            value: _dailyGoal.toDouble(),
                            min: 5,
                            max: 100,
                            divisions: 19,
                            label: '$_dailyGoal',
                            onChanged: (v) => setState(() => _dailyGoal = v.round()),
                          ),
                        ],
                        if (i == 3) ...[
                          const SizedBox(height: 24),
                          SwitchListTile(
                            title: const Text('Enable daily reminder'),
                            value: _enableReminder,
                            onChanged: (v) => setState(() => _enableReminder = v),
                          ),
                          if (_enableReminder)
                            ListTile(
                              title: const Text('Reminder time'),
                              trailing: Text(_reminderTime.format(context)),
                              onTap: () async {
                                final t = await showTimePicker(context: context, initialTime: _reminderTime);
                                if (t != null) setState(() => _reminderTime = t);
                              },
                            ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: FilledButton(
                onPressed: _next,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                child: Text(isLast ? 'Start reading' : 'Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
