import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import '../providers/notification_provider.dart';
import '../theme/app_theme.dart';
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

  final _pages = [
    {
      'title': 'One book.\nFinish it.',
      'subtitle': 'Focus on a single PDF until the last page.\nNo more unfinished books.',
    },
    {
      'title': 'Progress that\nfeels real',
      'subtitle': 'Mark pages done or “done for today”.\nCome back tomorrow and continue exactly where you left off.',
    },
    {
      'title': 'Your daily\nreading goal',
      'subtitle': 'Built around your pace and refined as you go.',
    },
    {
      'title': 'A gentle\nnudge',
      'subtitle': 'Optional reminder at a time that works for you.',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final notificationProvider = context.read<NotificationProvider>();
    await context.read<BookProvider>().completeOnboarding(dailyGoal: _dailyGoal);
    if (notificationProvider.enabled) {
      await notificationProvider.setTime(notificationProvider.time);
    }
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainShell(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;
    final notificationProvider = context.watch<NotificationProvider>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: List.generate(
                    _pages.length,
                    (i) => Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: i < _pages.length - 1 ? 6 : 0),
                        height: 3,
                        decoration: BoxDecoration(
                          color: i <= _currentPage ? AppTheme.primary : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, i) {
                    final page = _pages[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Spacer(flex: 2),
                          Text(
                            page['title'] as String,
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                              height: 1.1,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            page['subtitle'] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppTheme.textMuted,
                              height: 1.5,
                            ),
                          ),
                          if (i == 2) ...[
                            const SizedBox(height: 40),
                            Text(
                              '$_dailyGoal pages / day',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.navy,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text('daily goal', style: TextStyle(color: AppTheme.textMuted)),
                            const SizedBox(height: 16),
                            Slider(
                              value: _dailyGoal.toDouble(),
                              min: 5,
                              max: 100,
                              divisions: 19,
                              activeColor: AppTheme.primary,
                              inactiveColor: Colors.grey.shade200,
                              onChanged: (v) => setState(() => _dailyGoal = v.round()),
                            ),
                          ],
                          if (i == 3) ...[
                            const SizedBox(height: 32),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Daily reminder', style: TextStyle(color: AppTheme.navy)),
                              value: notificationProvider.enabled,
                              activeColor: AppTheme.primary,
                              onChanged: notificationProvider.setEnabled,
                            ),
                            if (notificationProvider.enabled)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Reminder time'),
                                trailing: Text(notificationProvider.time.format(context)),
                                onTap: () async {
                                  final t = await showTimePicker(context: context, initialTime: notificationProvider.time);
                                  if (t != null) notificationProvider.setTime(t);
                                },
                              ),
                          ],
                          const Spacer(flex: 3),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.navy,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(isLast ? 'Begin your first tome' : 'Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
