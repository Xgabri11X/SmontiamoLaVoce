import 'package:flutter/material.dart';

class VowelPoint {
  const VowelPoint(this.label, this.f1, this.f2);
  final String label;
  final double f1;
  final double f2;
}

const vowelPoints = <VowelPoint>[
  VowelPoint('I', 300, 2300),
  VowelPoint('E', 430, 2050),
  VowelPoint('A', 750, 1300),
  VowelPoint('O', 450, 900),
  VowelPoint('U', 320, 700),
];

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
  VowelSpacePainter({required this.f1, required this.f2});
  final double f1;
  final double f2;

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

    for (final v in vowelPoints) {
      final o = formantsToOffset(size, v.f1, v.f2);
      canvas.drawCircle(o, 7, Paint()..color = const Color(0xFFFFB45B));
      final tp = TextPainter(
        text: TextSpan(
          text: v.label,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, o + const Offset(9, -18));
    }

    final current = formantsToOffset(size, f1, f2);
    canvas.drawCircle(current, 18, Paint()..color = const Color(0xFF58D5E8).withValues(alpha: 0.20));
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
  bool shouldRepaint(covariant VowelSpacePainter oldDelegate) => oldDelegate.f1 != f1 || oldDelegate.f2 != f2;
}
