import 'dart:math' as math;
import 'package:flutter/material.dart';

class PageCurlOverlay extends StatefulWidget {
  final Widget child;
  final int page;
  final bool enabled;

  const PageCurlOverlay({
    super.key,
    required this.child,
    required this.page,
    this.enabled = true,
  });

  @override
  State<PageCurlOverlay> createState() => _PageCurlOverlayState();
}

class _PageCurlOverlayState extends State<PageCurlOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _lastPage = 0;
  bool _forward = true;

  @override
  void initState() {
    super.initState();
    _lastPage = widget.page;
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  }

  @override
  void didUpdateWidget(covariant PageCurlOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && widget.page != oldWidget.page) {
      _forward = widget.page > oldWidget.page;
      _lastPage = oldWidget.page;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.enabled)
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                if (_controller.value == 0 || _controller.isCompleted) {
                  return const SizedBox.shrink();
                }
                return CustomPaint(
                  size: Size.infinite,
                  painter: _CurlPainter(
                    progress: _controller.value,
                    forward: _forward,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _CurlPainter extends CustomPainter {
  final double progress;
  final bool forward;

  _CurlPainter({required this.progress, required this.forward});

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeInOut.transform(progress);
    final curlWidth = size.width * 0.55 * math.sin(t * math.pi);
    final startX = forward ? size.width : 0.0;
    final endX = forward ? size.width - curlWidth : curlWidth;

    final path = Path()
      ..moveTo(startX, 0)
      ..lineTo(endX, 0)
      ..quadraticBezierTo(
        endX + (forward ? -curlWidth * 0.3 : curlWidth * 0.3),
        size.height * 0.5,
        endX,
        size.height,
      )
      ..lineTo(startX, size.height)
      ..close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: forward ? Alignment.centerRight : Alignment.centerLeft,
        end: forward ? Alignment.centerLeft : Alignment.centerRight,
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.15),
          const Color(0xFFD8D0C4).withOpacity(0.55),
          const Color(0xFFC4B8A8).withOpacity(0.75),
        ],
        stops: const [0.0, 0.35, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, paint);

    final shadow = Paint()
      ..color = Colors.black.withOpacity(0.18 * math.sin(t * math.pi))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawPath(path, shadow);
  }

  @override
  bool shouldRepaint(covariant _CurlPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.forward != forward;
}
