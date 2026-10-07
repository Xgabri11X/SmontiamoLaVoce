import 'dart:math' as math;
import 'package:flutter/material.dart';

class WaveformPainter extends CustomPainter {
  WaveformPainter(this.samples, {this.color = const Color(0xFF58D5E8)});
  final List<double> samples;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), grid);
    if (samples.isEmpty) return;

    final p = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path();
    final step = math.max(1, samples.length ~/ math.max(1, size.width.floor()));
    var first = true;
    var x = 0.0;
    for (var i = 0; i < samples.length; i += step) {
      final y = size.height * (0.5 - 0.44 * samples[i].clamp(-1.0, 1.0));
      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
      x += size.width * step / samples.length;
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) => oldDelegate.samples != samples;
}
