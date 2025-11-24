import 'package:flutter/material.dart';

class WaveformPainter extends CustomPainter {
  final List<double> samples;
  final Color color;
  final Color? secondaryColor;
  final double strokeWidth;
  final PaintingStyle style;
  final Duration? currentPosition;
  final Duration? totalDuration;

  WaveformPainter({
    required this.samples,
    required this.color,
    this.secondaryColor,
    this.strokeWidth = 2.0,
    this.style = PaintingStyle.stroke,
    this.currentPosition,
    this.totalDuration,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;

    final width = size.width;
    final height = size.height;
    final midY = height / 2;
    final step = width / samples.length;

    // Calculate playback progress position
    double? progressX;
    if (currentPosition != null && totalDuration != null && totalDuration!.inMilliseconds > 0) {
      final progress = currentPosition!.inMilliseconds / totalDuration!.inMilliseconds;
      progressX = progress * width;
    }

    // Draw waveform bars
    for (var i = 0; i < samples.length; i++) {
      final x = i * step;
      final amplitude = samples[i];
      final barHeight = amplitude * height;

      final top = midY - (barHeight / 2);
      final bottom = midY + (barHeight / 2);

      // Determine color based on playback position
      final paint = Paint()
        ..strokeWidth = strokeWidth
        ..style = style
        ..strokeCap = StrokeCap.round;

      if (progressX != null && x <= progressX) {
        // Played portion - use full color
        paint.color = color;
      } else {
        // Unplayed portion - use dimmed color
        if (secondaryColor != null) {
          paint.color = secondaryColor!.withValues(alpha: 0.4);
        } else {
          paint.color = color.withValues(alpha: 0.3);
        }
      }

      canvas.drawLine(Offset(x, top), Offset(x, bottom), paint);
    }

    // Draw playback position indicator line
    if (progressX != null) {
      final indicatorPaint = Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(progressX, 0),
        Offset(progressX, height),
        indicatorPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return !identical(oldDelegate.samples, samples) ||
        oldDelegate.samples.length != samples.length ||
        oldDelegate.color != color ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.currentPosition != currentPosition ||
        oldDelegate.totalDuration != totalDuration;
  }
}
