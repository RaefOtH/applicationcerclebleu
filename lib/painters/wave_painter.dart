import 'package:flutter/material.dart';
import 'dart:math' as math;

class WavePainter extends CustomPainter {
  final double animation;
  final Color color;
  final double waveHeight;
  final double offset;

  WavePainter({
    required this.animation,
    required this.color,
    this.waveHeight = 20,
    this.offset = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        size.height * 0.7 +
            math.sin((i / size.width * 2 * math.pi) + (animation * 2 * math.pi) + offset) *
                waveHeight,
      );
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) => true;
}
