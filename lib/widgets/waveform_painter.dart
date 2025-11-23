import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class WaveformPainter extends CustomPainter {
  final List<double> samples;
  final Color color;
  final Color? secondaryColor;
  final double strokeWidth;
  final PaintingStyle style;

  WaveformPainter({
    required this.samples,
    required this.color,
    this.secondaryColor,
    this.strokeWidth = 2.0,
    this.style = PaintingStyle.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;

    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..style = style
      ..strokeCap = StrokeCap.round;

    if (secondaryColor != null) {
      paint.shader = ui.Gradient.linear(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        [color, secondaryColor!],
      );
    } else {
      paint.color = color;
    }

    final path = Path();
    final width = size.width;
    final height = size.height;
    final midY = height / 2;
    
    // Calculate width per sample
    final step = width / samples.length;

    for (var i = 0; i < samples.length; i++) {
      final x = i * step;
      final amplitude = samples[i];
      // Scale amplitude to height (max height is full height)
      final barHeight = amplitude * height;
      
      // Draw centered vertical bar
      final top = midY - (barHeight / 2);
      final bottom = midY + (barHeight / 2);
      
      canvas.drawLine(Offset(x, top), Offset(x, bottom), paint);
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.samples != samples ||
        oldDelegate.color != color ||
        oldDelegate.secondaryColor != secondaryColor;
  }
}
