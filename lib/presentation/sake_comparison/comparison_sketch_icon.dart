import 'package:flutter/material.dart';

/// Ink-and-paper illustrations shared by the comparison entry and cart.
enum ComparisonSketch { basket, sparkle }

class ComparisonSketchIcon extends StatelessWidget {
  const ComparisonSketchIcon({
    super.key,
    this.kind = ComparisonSketch.basket,
    this.size = 28,
  });
  final ComparisonSketch kind;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _SketchPainter(kind)),
  );
}

class _SketchPainter extends CustomPainter {
  const _SketchPainter(this.kind);
  final ComparisonSketch kind;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 48, size.height / 48);
    final pen = Paint()
      ..color = const Color(0xFF143861)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    void shape(Path path, Color color) {
      canvas.drawPath(path, Paint()..color = color);
      canvas.drawPath(path, pen);
    }

    if (kind == ComparisonSketch.basket) {
      shape(
        Path()
          ..moveTo(17, 5)
          ..lineTo(23, 5.5)
          ..lineTo(23, 13)
          ..quadraticBezierTo(28, 17, 27, 24)
          ..lineTo(14, 24)
          ..lineTo(14, 18)
          ..quadraticBezierTo(17, 14, 17, 12)
          ..close(),
        const Color(0xFFD8E3CE),
      );
      shape(
        Path()
          ..moveTo(29, 12)
          ..lineTo(39, 10)
          ..lineTo(40, 26)
          ..lineTo(29, 27)
          ..close(),
        const Color(0xFFFFF6DE),
      );
      canvas.drawPath(
        Path()
          ..moveTo(32, 16)
          ..lineTo(36, 15.5)
          ..moveTo(32, 20)
          ..lineTo(37, 19.5),
        pen,
      );
      shape(
        Path()
          ..moveTo(7, 23)
          ..quadraticBezierTo(25, 21, 42, 23.5)
          ..lineTo(37, 40)
          ..quadraticBezierTo(23, 43, 12, 40)
          ..close(),
        const Color(0xFFFFD84D),
      );
      canvas.drawPath(
        Path()
          ..moveTo(8, 27)
          ..lineTo(41, 27.5)
          ..moveTo(18, 31)
          ..lineTo(19, 37)
          ..moveTo(25, 30)
          ..lineTo(25, 38)
          ..moveTo(32, 31)
          ..lineTo(31, 37),
        pen,
      );
    } else {
      shape(
        Path()
          ..moveTo(25, 5)
          ..quadraticBezierTo(27, 19, 39, 23)
          ..quadraticBezierTo(27, 26, 24, 41)
          ..quadraticBezierTo(21, 27, 8, 23)
          ..quadraticBezierTo(22, 20, 25, 5)
          ..close(),
        const Color(0xFFFFD84D),
      );
      canvas.drawPath(
        Path()
          ..moveTo(8, 5)
          ..lineTo(9, 12)
          ..moveTo(5, 9)
          ..lineTo(13, 8)
          ..moveTo(39, 33)
          ..lineTo(40, 41)
          ..moveTo(36, 37)
          ..lineTo(44, 36),
        pen,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SketchPainter oldDelegate) => kind != oldDelegate.kind;
}
