import 'package:flutter/material.dart';
import 'package:one_tome/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'providers/book_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/reader_preferences_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/highlight_provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_shell.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..load()),
        ChangeNotifierProvider(create: (_) => BookProvider()..load()),
        ChangeNotifierProvider(create: (_) => ReaderPreferencesProvider()..load()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()..load()),
        ChangeNotifierProvider(create: (_) => HighlightProvider()..load()),
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

    return MaterialApp(
      title: 'OneTome',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.themeMode,
      home: const SplashScreen(),
    );
  }
}
