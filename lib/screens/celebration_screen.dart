import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'import_screen.dart';

class CelebrationScreen extends StatefulWidget {
  final String bookTitle;

  const CelebrationScreen({super.key, required this.bookTitle});

  @override
  State<CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends State<CelebrationScreen> {
  late ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 4));
    _controller.play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  const Icon(Icons.auto_stories, size: 80, color: AppTheme.primary),
                  const SizedBox(height: 28),
                  const Text(
                    'You finished it.',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.bookTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'One book down. Ready for the next?',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary(context),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(flex: 3),
                  FilledButton(
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.accent : AppTheme.navy,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Go home'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ImportScreen()));
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Add another book'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _controller,
              blastDirection: pi / 2,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              maxBlastForce: 40,
              minBlastForce: 15,
              gravity: 0.2,
              colors: const [
                AppTheme.primary,
                AppTheme.accent,
                Colors.amber,
                Colors.orange,
                Colors.pinkAccent,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
