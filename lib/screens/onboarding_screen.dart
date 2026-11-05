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

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;
  int _dailyGoal = 20;
  late AnimationController _fadeAnim;
  late AnimationController _scaleAnim;

  final _pages = [
    {
      'title': 'One book.\nFinish it.',
      'subtitle': 'Focus on a single PDF until the last page.\nNo more unfinished books.',
      'icon': Icons.menu_book_rounded,
    },
    {
      'title': 'Progress that\nfeels real',
      'subtitle': 'Mark pages done or “done for today”.\nCome back tomorrow and continue exactly where you left off.',
      'icon': Icons.auto_stories_rounded,
    },
    {
      'title': 'Set your\ndaily goal',
      'subtitle': 'How many pages do you want to aim for each day?',
      'icon': Icons.flag_rounded,
    },
    {
      'title': 'A gentle\nnudge',
      'subtitle': 'Optional reminder at a time that works for you.',
      'icon': Icons.notifications_none_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _fadeAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scaleAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim.forward();
    _scaleAnim.forward();
  }

  @override
  void dispose() {
    _fadeAnim.dispose();
    _scaleAnim.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int i) {
    setState(() => _currentPage = i);
    _fadeAnim.reset();
    _scaleAnim.reset();
    _fadeAnim.forward();
    _scaleAnim.forward();
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
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
      );
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
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 700),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primary.withOpacity(0.08),
                    AppTheme.surfaceSoft,
                    Colors.white,
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
                      onPageChanged: _onPageChanged,
                      itemBuilder: (context, i) {
                        final page = _pages[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 36),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ScaleTransition(
                                scale: CurvedAnimation(parent: _scaleAnim, curve: Curves.easeOutBack),
                                child: FadeTransition(
                                  opacity: _fadeAnim,
                                  child: Container(
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      page['icon'] as IconData,
                                      size: 76,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 52),
                              FadeTransition(
                                opacity: _fadeAnim,
                                child: Text(
                                  page['title'] as String,
                                  style: theme.textTheme.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    height: 1.08,
                                    letterSpacing: -0.8,
                                    color: const Color(0xFF1A2332),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 18),
                              FadeTransition(
                                opacity: _fadeAnim,
                                child: Text(
                                  page['subtitle'] as String,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: const Color(0xFF5A6A7A),
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              if (i == 2) ...[
                                const SizedBox(height: 44),
                                Text('$_dailyGoal pages / day', style: theme.textTheme.titleLarge?.copyWith(color: AppTheme.primary)),
                                const SizedBox(height: 4),
                                Slider(
                                  value: _dailyGoal.toDouble(),
                                  min: 5,
                                  max: 100,
                                  divisions: 19,
                                  activeColor: AppTheme.primary,
                                  onChanged: (v) => setState(() => _dailyGoal = v.round()),
                                ),
                              ],
                              if (i == 3) ...[
                                const SizedBox(height: 36),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Daily reminder'),
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
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _pages.length,
                            (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOut,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 6,
                              width: _currentPage == i ? 28 : 6,
                              decoration: BoxDecoration(
                                color: _currentPage == i ? AppTheme.primary : AppTheme.primary.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        FilledButton(
                          onPressed: _next,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
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
