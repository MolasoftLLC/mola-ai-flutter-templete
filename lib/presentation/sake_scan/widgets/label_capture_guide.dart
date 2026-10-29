import 'package:flutter/material.dart';

/// Composition guide only; it never crops or changes the captured image.
class LabelCaptureGuide extends StatelessWidget {
  const LabelCaptureGuide({super.key, required this.isBackLabel});

  final bool isBackLabel;

  @override
  Widget build(BuildContext context) => Padding(
    // The front bottle is intentionally large and extends behind the floating
    // controls. This is a visual overlay only; it must not intercept touch.
    padding: isBackLabel
        ? const EdgeInsets.fromLTRB(20, 136, 20, 166)
        : EdgeInsets.fromLTRB(
            12,
            128 + (MediaQuery.textScalerOf(context).scale(12) - 12) * 5,
            12,
            12,
          ),
    child: Center(
      child: AspectRatio(
        aspectRatio: isBackLabel ? 0.80 : 0.30,
        child: CustomPaint(painter: _LabelCaptureGuidePainter(isBackLabel)),
      ),
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
      // Follow the reference bottle's proportions: a tall narrow closure,
      // a neck flowing into a long curved taper, and straight sides only in
      // the lower third. Keep the neck/shoulder/body joins tangent-continuous.
      path
        ..moveTo(width * 0.39, height * 0.02)
        ..quadraticBezierTo(
          width * 0.50,
          height * 0.015,
          width * 0.61,
          height * 0.02,
        )
        ..quadraticBezierTo(
          width * 0.65,
          height * 0.02,
          width * 0.65,
          height * 0.03,
        )
        ..lineTo(width * 0.65, height * 0.135)
        ..quadraticBezierTo(
          width * 0.68,
          height * 0.145,
          width * 0.64,
          height * 0.15,
        )
        ..lineTo(width * 0.64, height * 0.25)
        ..cubicTo(
          width * 0.64,
          height * 0.42,
          width * 0.92,
          height * 0.49,
          width * 0.92,
          height * 0.70,
        )
        ..lineTo(width * 0.92, height * 0.94)
        ..quadraticBezierTo(
          width * 0.92,
          height * 0.975,
          width * 0.83,
          height * 0.98,
        )
        ..quadraticBezierTo(
          width * 0.50,
          height * 0.995,
          width * 0.17,
          height * 0.98,
        )
        ..quadraticBezierTo(
          width * 0.08,
          height * 0.975,
          width * 0.08,
          height * 0.94,
        )
        ..lineTo(width * 0.08, height * 0.70)
        ..cubicTo(
          width * 0.08,
          height * 0.49,
          width * 0.36,
          height * 0.42,
          width * 0.36,
          height * 0.25,
        )
        ..lineTo(width * 0.36, height * 0.15)
        ..quadraticBezierTo(
          width * 0.32,
          height * 0.145,
          width * 0.35,
          height * 0.135,
        )
        ..lineTo(width * 0.35, height * 0.03)
        ..quadraticBezierTo(
          width * 0.35,
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
