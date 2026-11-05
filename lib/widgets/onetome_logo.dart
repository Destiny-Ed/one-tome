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
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _LogoPainter(),
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

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppTheme.primary, AppTheme.accent],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), Radius.circular(w * 0.22)),
      bg,
    );

    final book = Paint()..color = Colors.white.withOpacity(0.95);
    final bookRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: w * 0.52, height: h * 0.62),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(bookRect, book);

    final spine = Paint()..color = AppTheme.navy.withOpacity(0.15);
    canvas.drawRect(
      Rect.fromLTWH(center.dx - w * 0.26, center.dy - h * 0.31, w * 0.06, h * 0.62),
      spine,
    );

    final line = Paint()
      ..color = AppTheme.primary.withOpacity(0.35)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final left = center.dx - w * 0.16;
    final right = center.dx + w * 0.18;
    for (var i = 0; i < 4; i++) {
      final y = center.dy - h * 0.14 + i * h * 0.08;
      canvas.drawLine(Offset(left, y), Offset(right, y), line);
    }

    final mark = Path()
      ..moveTo(center.dx + w * 0.04, center.dy - h * 0.22)
      ..lineTo(center.dx + w * 0.22, center.dy - h * 0.08)
      ..lineTo(center.dx + w * 0.04, center.dy + h * 0.06)
      ..close();
    canvas.drawPath(mark, Paint()..color = AppTheme.accent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
