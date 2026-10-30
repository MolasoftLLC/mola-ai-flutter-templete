import 'package:flutter/material.dart';
import 'japan_sake_map.dart';

/// A small illustrated paper label using the stamp book's brush lettering.
class SakeStampCollectionLabel extends StatelessWidget {
  const SakeStampCollectionLabel({
    super.key,
    this.prefecture,
    this.nationwideCount,
    required this.count,
    required this.ready,
  });
  final String? prefecture;
  final int? nationwideCount;
  final int count;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    return CustomPaint(
      painter: const _CollectionLabelPainter(),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 68),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 72, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (nationwideCount != null)
                  _countLine(
                    english,
                    english ? 'Stamps nationwide ' : '全国で集めた酒印 ',
                    nationwideCount!,
                    key: const ValueKey('nationwide-stamp-count'),
                    compact: prefecture != null,
                  ),
                if (nationwideCount != null && prefecture != null)
                  const SizedBox(height: 2),
                if (prefecture != null)
                  _countLine(
                    english,
                    english ? 'Stamps in $prefecture ' : '$prefectureで集めた酒印 ',
                    count,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _countLine(
    bool english,
    String label,
    int value, {
    Key? key,
    bool compact = false,
  }) => Text.rich(
    ready
        ? TextSpan(
            children: [
              TextSpan(text: label),
              TextSpan(
                text: '$value',
                style: TextStyle(
                  fontSize: compact ? 22 : 27,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFB73927),
                ),
              ),
              TextSpan(
                text: english ? ' brands' : '銘柄',
                style: const TextStyle(color: Color(0xFFB73927)),
              ),
            ],
          )
        : TextSpan(text: english ? 'Records unconfirmed' : '記録未確認'),
    key: key,
    style: TextStyle(
      fontFamily: english ? null : 'SakeSeal',
      fontSize: compact ? 14 : 16,
      fontWeight: FontWeight.w500,
      height: 1.3,
      color: japanMapNavy,
    ),
  );
}

class _CollectionLabelPainter extends CustomPainter {
  const _CollectionLabelPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paper = Path()
      ..moveTo(8, 4)
      ..quadraticBezierTo(w * .35, 1, w * .64, 4)
      ..lineTo(w - 8, 3)
      ..quadraticBezierTo(w - 3, h * .35, w - 6, h * .64)
      ..lineTo(w - 4, h - 6)
      ..quadraticBezierTo(w * .65, h - 2, w * .35, h - 5)
      ..lineTo(5, h - 3)
      ..quadraticBezierTo(2, h * .56, 5, h * .28)
      ..close();
    canvas.drawPath(
      paper.shift(const Offset(0, 2)),
      Paint()..color = const Color(0xFFEDE4D2),
    );
    canvas.drawPath(paper, Paint()..color = const Color(0xFFFFF8E9));
    final edge = Paint()
      ..color = const Color(0xFFBCA77E).withValues(alpha: .5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(paper, edge);
    canvas.drawPath(
      Path()
        ..moveTo(13, 8)
        ..quadraticBezierTo(w * .4, 5, w * .66, 8),
      edge..color = const Color(0xFFDAC9A7),
    );
    final fiber = Paint()
      ..color = const Color(0xFFCDBD9B).withValues(alpha: .22)
      ..strokeWidth = .6;
    for (var i = 0; i < 36; i++) {
      final x = 12 + (i * 41.3) % (w - 24);
      final y = 10 + (i * 17.1) % (h - 20);
      canvas.drawLine(Offset(x, y), Offset(x + 3, y + .7), fiber);
    }

    // A loose bottle-and-cup sketch, kept clear of the text at any text scale.
    canvas.save();
    canvas.translate(w - 65, h / 2 - 25);
    final ink = Paint()
      ..color = japanMapNavy.withValues(alpha: .58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final bottle = Path()
      ..moveTo(15, 4)
      ..lineTo(25, 4)
      ..lineTo(25, 8)
      ..lineTo(23, 9)
      ..cubicTo(23, 19, 25, 24, 29, 31)
      ..quadraticBezierTo(31, 35, 30, 47)
      ..quadraticBezierTo(20, 50, 10, 47)
      ..quadraticBezierTo(9, 36, 11, 31)
      ..cubicTo(15, 24, 17, 19, 17, 9)
      ..lineTo(15, 8)
      ..close();
    canvas.drawPath(bottle, Paint()..color = const Color(0xFFE5E9DA));
    canvas.drawPath(bottle, ink);
    canvas.drawLine(const Offset(15, 7), const Offset(25, 7), ink);
    canvas.drawPath(
      Path()
        ..moveTo(11, 32)
        ..quadraticBezierTo(21, 34, 30, 32)
        ..moveTo(10, 43)
        ..quadraticBezierTo(20, 45, 30, 43),
      ink..color = const Color(0xFFC3AD82),
    );
    canvas.drawCircle(
      const Offset(20, 38),
      3.2,
      Paint()..color = const Color(0xFFD39262).withValues(alpha: .7),
    );
    ink.color = japanMapNavy.withValues(alpha: .58);
    canvas.drawOval(const Rect.fromLTWH(32, 33, 19, 6), ink);
    canvas.drawPath(
      Path()
        ..moveTo(32, 36)
        ..quadraticBezierTo(33, 46, 38, 48)
        ..lineTo(45, 48)
        ..quadraticBezierTo(50, 45, 51, 36),
      ink,
    );
    canvas.drawLine(const Offset(38, 50), const Offset(45, 50), ink);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CollectionLabelPainter oldDelegate) => false;
}
