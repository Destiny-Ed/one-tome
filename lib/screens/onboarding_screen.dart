import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import '../providers/notification_provider.dart';
import 'main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;
  int _dailyGoal = 20;
  late AnimationController _anim;

  final _pages = [
    {
      'title': 'One book.\nFinish it.',
      'subtitle': 'Focus on a single PDF until the last page. No more unfinished books gathering dust.',
      'icon': Icons.menu_book_rounded,
    },
    {
      'title': 'Progress that\nfeels real',
      'subtitle': 'Mark pages done or “done for today”. Come back tomorrow and continue exactly where you left off.',
      'icon': Icons.today_rounded,
    },
    {
      'title': 'Your daily\nreading goal',
      'subtitle': 'How many pages do you want to aim for each day?',
      'icon': Icons.flag_rounded,
    },
    {
      'title': 'Gentle daily\nreminder',
      'subtitle': 'A quiet nudge at the time that works for you.',
      'icon': Icons.notifications_active_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
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
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;
    final theme = Theme.of(context);
    final notificationProvider = context.watch<NotificationProvider>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.15),
                    theme.colorScheme.surface,
                    theme.colorScheme.secondary.withOpacity(0.08),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _pages.length,
                      onPageChanged: (i) {
                        setState(() => _currentPage = i);
                        _anim.reset();
                        _anim.forward();
                      },
                      itemBuilder: (context, i) {
                        final page = _pages[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 36),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FadeTransition(
                                opacity: _anim,
                                child: Icon(
                                  page['icon'] as IconData,
                                  size: 120,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 48),
                              Text(
                                page['title'] as String,
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  height: 1.15,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                page['subtitle'] as String,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (i == 2) ...[
                                const SizedBox(height: 40),
                                Text('$_dailyGoal pages / day', style: theme.textTheme.titleLarge),
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
                                const SizedBox(height: 32),
                                SwitchListTile(
                                  title: const Text('Enable daily reminder'),
                                  value: notificationProvider.enabled,
                                  onChanged: notificationProvider.setEnabled,
                                ),
                                if (notificationProvider.enabled)
                                  ListTile(
                                    title: const Text('Reminder time'),
                                    trailing: Text(notificationProvider.time.format(context)),
                                    onTap: () async {
                                      final t = await showTimePicker(context: context, initialTime: notificationProvider.time);
                                      if (t != null) notificationProvider.setTime(t);
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
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _pages.length,
                            (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 8,
                              width: _currentPage == i ? 24 : 8,
                              decoration: BoxDecoration(
                                color: _currentPage == i
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.primary.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _next,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(isLast ? 'Begin your first tome' : 'Continue'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
