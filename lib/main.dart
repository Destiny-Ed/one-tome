import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/book_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => BookProvider()..load(),
      child: const OneTomeApp(),
    ),
  );
}

class OneTomeApp extends StatelessWidget {
  const OneTomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OneTome',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
