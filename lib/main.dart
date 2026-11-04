import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/book_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..load()),
        ChangeNotifierProvider(create: (_) => BookProvider()..load()),
      ],
      child: const OneTomeApp(),
    ),
  );
}

class OneTomeApp extends StatelessWidget {
  const OneTomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final bookProvider = context.watch<BookProvider>();

    return MaterialApp(
      title: 'OneTome',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.themeMode,
      home: bookProvider.hasCompletedOnboarding
          ? const MainShell()
          : const OnboardingScreen(),
    );
  }
}
