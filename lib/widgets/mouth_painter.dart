import 'dart:math' as math;
import 'package:flutter/material.dart';

class MouthPainter extends CustomPainter {
  MouthPainter({required this.f1, required this.f2});
  final double f1;
  final double f2;

  @override
  void paint(Canvas canvas, Size size) {
    final open = ((f1 - 250) / 650).clamp(0.0, 1.0).toDouble();
    final front = ((f2 - 600) / 2000).clamp(0.0, 1.0).toDouble();
    final rounded = ((1100 - f2) / 600).clamp(0.0, 1.0).toDouble() * (1 - open * 0.45);

    final skin = Paint()
      ..color = const Color(0xFFD9A078)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final cavity = Paint()
      ..color = const Color(0xFF351B2A)
      ..style = PaintingStyle.fill;
    final tonguePaint = Paint()
      ..color = const Color(0xFFE96A78)
      ..style = PaintingStyle.fill;
    final teeth = Paint()
      ..color = const Color(0xFFF6F0E6)
      ..style = PaintingStyle.fill;

    // Simplified sagittal head outline.
    final head = Path()
      ..moveTo(size.width * 0.18, size.height * 0.12)
      ..cubicTo(size.width * 0.55, 0, size.width * 0.78, size.height * 0.13, size.width * 0.78, size.height * 0.33)
      ..cubicTo(size.width * 0.93, size.height * 0.38, size.width * 0.92, size.height * 0.48, size.width * 0.78, size.height * 0.50)
      ..cubicTo(size.width * 0.70, size.height * 0.72, size.width * 0.56, size.height * 0.90, size.width * 0.42, size.height * 0.94)
      ..cubicTo(size.width * 0.28, size.height * 0.78, size.width * 0.20, size.height * 0.48, size.width * 0.18, size.height * 0.12);
    canvas.drawPath(head, skin);

    final mouthTop = size.height * 0.42;
    final mouthOpen = 18 + open * 52;
    final lipX = size.width * (0.77 + rounded * 0.05);
    final backX = size.width * 0.32;
    final cavityRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(backX, mouthTop - 8, lipX, mouthTop + mouthOpen),
      Radius.circular(18 + rounded * 15),
    );
    canvas.drawRRect(cavityRect, cavity);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.53, mouthTop - 5, size.width * 0.20, 9),
        const Radius.circular(3),
      ),
      teeth,
    );

    // Tongue position: F2 controls front/back; F1 inversely controls height.
    final tongueX = size.width * (0.40 + 0.22 * front);
    final tongueY = mouthTop + mouthOpen * (0.70 - 0.42 * (1 - open));
    final tongueW = size.width * 0.30;
    final tongueH = 24 + 18 * (1 - open);
    final tongue = Path()
      ..moveTo(backX + 8, mouthTop + mouthOpen - 8)
      ..cubicTo(
        tongueX - tongueW * 0.35,
        tongueY + tongueH * 0.3,
        tongueX - tongueW * 0.12,
        tongueY - tongueH * 0.65,
        tongueX + tongueW * 0.35,
        tongueY - tongueH * 0.30,
      )
      ..cubicTo(
        tongueX + tongueW * 0.55,
        tongueY,
        tongueX + tongueW * 0.45,
        mouthTop + mouthOpen - 5,
        backX + 8,
        mouthTop + mouthOpen - 8,
      )
      ..close();
    canvas.drawPath(tongue, tonguePaint);

    // Lips, visibly rounder toward /u/ and /o/.
    final lipPaint = Paint()
      ..color = const Color(0xFFC95666)
      ..strokeWidth = 5 + rounded * 4
      ..strokeCap = StrokeCap.round;
    final gap = math.max(4.0, mouthOpen * 0.26 * (1 - rounded * 0.45));
    canvas.drawLine(Offset(lipX - 6, mouthTop + 5), Offset(lipX + 8 + rounded * 8, mouthTop + 8), lipPaint);
    canvas.drawLine(
      Offset(lipX - 6, mouthTop + 5 + gap),
      Offset(lipX + 8 + rounded * 8, mouthTop + 8 + gap),
      lipPaint,
    );
  }

  @override
  bool shouldRepaint(covariant MouthPainter oldDelegate) => oldDelegate.f1 != f1 || oldDelegate.f2 != f2;
}
