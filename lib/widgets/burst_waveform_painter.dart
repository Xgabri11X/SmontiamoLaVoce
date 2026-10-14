import 'dart:math' as math;

import 'package:flutter/material.dart';

class BurstWaveformPainter extends CustomPainter {
  BurstWaveformPainter({
    required this.samples,
    required this.burstSampleIndex,
    required this.closureStartSample,
    required this.closureEndSample,
  });

  final List<double> samples;
  final int burstSampleIndex;
  final int closureStartSample;
  final int closureEndSample;

  @override
  void paint(Canvas canvas, Size size) {
    final axis = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      axis,
    );

    if (samples.isEmpty) return;

    double xForSample(int index) =>
        size.width *
        index.clamp(0, samples.length - 1).toDouble() /
        math.max(1, samples.length - 1).toDouble();

    final closureLeft = xForSample(closureStartSample);
    final closureRight = xForSample(closureEndSample);
    final closurePaint = Paint()..color = const Color(0xFFF5B84B).withValues(alpha: 0.16);
    canvas.drawRect(
      Rect.fromLTRB(closureLeft, 0, math.max(closureLeft + 1, closureRight), size.height),
      closurePaint,
    );

    final wavePaint = Paint()
      ..color = const Color(0xFF58D5E8)
      ..strokeWidth = 1.7
      ..style = PaintingStyle.stroke;
    final path = Path();
    final step = math.max(1, samples.length ~/ math.max(1, size.width.floor()));
    var first = true;
    for (var i = 0; i < samples.length; i += step) {
      final x = size.width * i / math.max(1, samples.length - 1);
      final y = size.height * (0.5 - 0.43 * samples[i].clamp(-1.0, 1.0));
      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, wavePaint);

    final burstX = xForSample(burstSampleIndex);
    final burstPaint = Paint()
      ..color = const Color(0xFFFF6B6B)
      ..strokeWidth = 2.2;
    canvas.drawLine(Offset(burstX, 0), Offset(burstX, size.height), burstPaint);

    final labelPainter = TextPainter(
      text: const TextSpan(
        text: 'BURST',
        style: TextStyle(
          color: Color(0xFFFFA0A0),
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final labelX = (burstX + 5)
        .clamp(0.0, math.max(0.0, size.width - labelPainter.width))
        .toDouble();
    labelPainter.paint(canvas, Offset(labelX, 5));
  }

  @override
  bool shouldRepaint(covariant BurstWaveformPainter oldDelegate) {
    return oldDelegate.samples != samples ||
        oldDelegate.burstSampleIndex != burstSampleIndex ||
        oldDelegate.closureStartSample != closureStartSample ||
        oldDelegate.closureEndSample != closureEndSample;
  }
}
