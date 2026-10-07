import 'package:flutter/material.dart';

class SpectrumPainter extends CustomPainter {
  SpectrumPainter(this.magnitudes, {this.color = const Color(0xFFFFB45B)});
  final List<double> magnitudes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final axis = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (var i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), axis);
    }
    if (magnitudes.isEmpty) return;
    final fill = Paint()..color = color.withValues(alpha: 0.82);
    final w = size.width / magnitudes.length;
    for (var i = 0; i < magnitudes.length; i++) {
      final h = size.height * 0.9 * magnitudes[i].clamp(0.0, 1.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * w + 0.5, size.height - h, (w - 1).clamp(1.0, 8.0).toDouble(), h),
          const Radius.circular(2),
        ),
        fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SpectrumPainter oldDelegate) => oldDelegate.magnitudes != magnitudes;
}
