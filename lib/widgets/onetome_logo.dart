import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class OneTomeLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;

  const OneTomeLogo({super.key, this.size = 96, this.showWordmark = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.22),
          child: Image.asset(
            'assets/logo.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
        if (showWordmark) ...[
          const SizedBox(height: 16),
          Text(
            'OneTome',
            style: TextStyle(
              fontSize: size * 0.28,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'One book. Finish it.',
            style: TextStyle(
              fontSize: size * 0.14,
              color: AppTheme.textSecondary(context),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ],
    );
  }
}
