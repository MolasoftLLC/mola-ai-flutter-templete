import 'package:flutter/material.dart';

/// Composition guide only; it never crops or changes the captured image.
class LabelCaptureGuide extends StatelessWidget {
  const LabelCaptureGuide({super.key, required this.isBackLabel});

  final bool isBackLabel;

  @override
  Widget build(BuildContext context) => Center(
    child: AspectRatio(
      aspectRatio: isBackLabel ? 0.80 : 0.50,
      child: CustomPaint(painter: _LabelCaptureGuidePainter(isBackLabel)),
    ),
  );
}

class _LabelCaptureGuidePainter extends CustomPainter {
  const _LabelCaptureGuidePainter(this.isBackLabel);

  final bool isBackLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final path = Path();
    if (isBackLabel) {
      path.addRRect(
        RRect.fromRectAndRadius(bounds.deflate(5), const Radius.circular(16)),
      );
    } else {
      final width = size.width;
      final height = size.height;
      // Sake bottle: a narrow capped neck, gently rounded shoulders,
      // straight body and a softly rounded base.
      path
        ..moveTo(width * 0.39, height * 0.02)
        ..lineTo(width * 0.61, height * 0.02)
        ..quadraticBezierTo(
          width * 0.63,
          height * 0.02,
          width * 0.63,
          height * 0.035,
        )
        ..lineTo(width * 0.63, height * 0.055)
        ..lineTo(width * 0.61, height * 0.065)
        ..lineTo(width * 0.61, height * 0.24)
        ..cubicTo(
          width * 0.61,
          height * 0.32,
          width * 0.92,
          height * 0.34,
          width * 0.92,
          height * 0.46,
        )
        ..lineTo(width * 0.92, height * 0.95)
        ..quadraticBezierTo(
          width * 0.92,
          height * 0.98,
          width * 0.85,
          height * 0.98,
        )
        ..lineTo(width * 0.15, height * 0.98)
        ..quadraticBezierTo(
          width * 0.08,
          height * 0.98,
          width * 0.08,
          height * 0.95,
        )
        ..lineTo(width * 0.08, height * 0.46)
        ..cubicTo(
          width * 0.08,
          height * 0.34,
          width * 0.39,
          height * 0.32,
          width * 0.39,
          height * 0.24,
        )
        ..lineTo(width * 0.39, height * 0.065)
        ..lineTo(width * 0.37, height * 0.055)
        ..lineTo(width * 0.37, height * 0.035)
        ..quadraticBezierTo(
          width * 0.37,
          height * 0.02,
          width * 0.39,
          height * 0.02,
        )
        ..close();
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x33000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x80FFD54F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_LabelCaptureGuidePainter oldDelegate) =>
      isBackLabel != oldDelegate.isBackLabel;
}
