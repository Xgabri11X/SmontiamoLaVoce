import 'package:flutter/material.dart';

import '../models/vowel_inventory.dart';

Offset formantsToOffset(Size size, double f1, double f2) {
  final x = ((2600 - f2) / 2100).clamp(0.0, 1.0).toDouble() * size.width;
  final y = ((f1 - 250) / 650).clamp(0.0, 1.0).toDouble() * size.height;
  return Offset(x, y);
}

(double, double) offsetToFormants(Size size, Offset p) {
  final x = (p.dx / size.width).clamp(0.0, 1.0).toDouble();
  final y = (p.dy / size.height).clamp(0.0, 1.0).toDouble();
  final f2 = 2600 - 2100 * x;
  final f1 = 250 + 650 * y;
  return (f1, f2);
}

class VowelSpacePainter extends CustomPainter {
  VowelSpacePainter({
    required this.f1,
    required this.f2,
    required this.points,
  });

  final double f1;
  final double f2;
  final List<VowelPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (var i = 1; i < 5; i++) {
      final x = size.width * i / 5;
      final y = size.height * i / 5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final border = Paint()
      ..color = Colors.white.withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)),
      border,
    );

    // Conventional vowel-space outline: high/front at upper left, high/back
    // at upper right and open vowels toward the bottom.
    final trapezoid = Path()
      ..moveTo(formantsToOffset(size, 270, 2500).dx, formantsToOffset(size, 270, 2500).dy)
      ..lineTo(formantsToOffset(size, 270, 620).dx, formantsToOffset(size, 270, 620).dy)
      ..lineTo(formantsToOffset(size, 820, 900).dx, formantsToOffset(size, 820, 900).dy)
      ..lineTo(formantsToOffset(size, 820, 1650).dx, formantsToOffset(size, 820, 1650).dy)
      ..close();
    canvas.drawPath(
      trapezoid,
      Paint()
        ..color = const Color(0xFF58D5E8).withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    for (final v in points) {
      final o = formantsToOffset(size, v.f1, v.f2);
      canvas.drawCircle(o, 5.5, Paint()..color = const Color(0xFFFFB45B));
      final tp = TextPainter(
        text: TextSpan(
          text: v.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Keep labels inside the chart when a target is near an edge.
      var dx = o.dx + 7;
      var dy = o.dy - 16;
      if (dx + tp.width > size.width - 2) dx = o.dx - tp.width - 7;
      if (dy < 2) dy = o.dy + 7;
      tp.paint(canvas, Offset(dx, dy));
    }

    final current = formantsToOffset(size, f1, f2);
    canvas.drawCircle(
      current,
      18,
      Paint()..color = const Color(0xFF58D5E8).withValues(alpha: 0.20),
    );
    canvas.drawCircle(current, 9, Paint()..color = const Color(0xFF58D5E8));
    canvas.drawCircle(
      current,
      9,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant VowelSpacePainter oldDelegate) =>
      oldDelegate.f1 != f1 ||
      oldDelegate.f2 != f2 ||
      oldDelegate.points != points;
}
