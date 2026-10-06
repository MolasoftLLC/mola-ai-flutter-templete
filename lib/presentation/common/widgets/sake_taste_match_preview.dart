import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../domain/eintities/preferences/taste_preference_profile.dart';
import '../../../domain/eintities/sake_label_scan.dart';

const _navy = Color(0xFF143861);

class SakeTasteMatchPreview extends StatelessWidget {
  const SakeTasteMatchPreview({
    super.key,
    required this.percent,
    this.profile,
    this.preference,
    this.radarSize = 92,
  });

  final int? percent;
  final SakeTasteProfileDetails? profile;
  final TastePreferenceProfile? preference;
  final double radarSize;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'あなたの好みマッチ度',
              style: TextStyle(
                color: Color(0xFF647184),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFFFA13C), Color(0xFFE95C9A)],
              ).createShader(bounds),
              child: Text(
                percent == null ? '--' : '${percent!.clamp(0, 100)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
      if (profile != null) ...[
        const SizedBox(width: 8),
        SizedBox.square(
          dimension: radarSize,
          child: FittedBox(
            child: _CompactTasteRadar(
              profile: profile!,
              preference: preference,
            ),
          ),
        ),
      ],
    ],
  );
}

class _CompactTasteRadar extends StatelessWidget {
  const _CompactTasteRadar({required this.profile, required this.preference});

  final SakeTasteProfileDetails profile;
  final TastePreferenceProfile? preference;

  @override
  Widget build(BuildContext context) {
    final values = _profileValues(profile);
    final preferenceValues = preference == null
        ? null
        : _preferenceValues(preference!);
    const size = 92.0;
    const radius = 28.0;
    const labels = ['香り', '甘み', '酸味', 'コク', 'キレ', '辛さ'];
    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          CustomPaint(
            size: const Size.square(size),
            painter: _CompactRadarPainter(
              values: values,
              preferenceValues: preferenceValues,
              radius: radius,
            ),
          ),
          for (var index = 0; index < labels.length; index++)
            _CompactRadarLabel(
              label: labels[index],
              index: index,
              size: size,
              radius: radius,
            ),
        ],
      ),
    );
  }
}

class _CompactRadarLabel extends StatelessWidget {
  const _CompactRadarLabel({
    required this.label,
    required this.index,
    required this.size,
    required this.radius,
  });

  final String label;
  final int index;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final angle = -math.pi / 2 + math.pi * 2 * index / 6;
    final labelRadius = radius + 11;
    const width = 28.0;
    final left = (size / 2 + math.cos(angle) * labelRadius - width / 2).clamp(
      0.0,
      size - width,
    );
    final top = (size / 2 + math.sin(angle) * labelRadius - 5).clamp(
      0.0,
      size - 10,
    );
    return Positioned(
      left: left,
      top: top,
      width: width,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _navy,
          fontSize: 7,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CompactRadarPainter extends CustomPainter {
  const _CompactRadarPainter({
    required this.values,
    required this.radius,
    this.preferenceValues,
  });

  final List<double> values;
  final List<double>? preferenceValues;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final grid = Paint()
      ..color = const Color(0xFFDCE5EF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var level = 1; level <= 4; level++) {
      canvas.drawPath(_path(center, radius * level / 4, null), grid);
    }
    final user = preferenceValues;
    if (user != null) {
      final path = _path(center, radius, user);
      canvas
        ..drawPath(
          path,
          Paint()..color = const Color(0xFF65C7FF).withValues(alpha: .25),
        )
        ..drawPath(
          path,
          Paint()
            ..color = const Color(0xFF2E8BFF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
    }
    final sakePath = _path(center, radius, values);
    final bounds = Rect.fromCircle(center: center, radius: radius);
    canvas
      ..drawPath(
        sakePath,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0xB8FFD96A), Color(0x55E95C9A)],
          ).createShader(bounds),
      )
      ..drawPath(
        sakePath,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFFFA13C), Color(0xFFE95C9A), Color(0xFF8D6CDB)],
          ).createShader(bounds)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
  }

  Path _path(Offset center, double radius, List<double>? source) {
    final path = Path();
    for (var index = 0; index < 6; index++) {
      final angle = -math.pi / 2 + math.pi * 2 * index / 6;
      final scaledRadius = radius * (source?[index].clamp(0, 1) ?? 1);
      final point = Offset(
        center.dx + math.cos(angle) * scaledRadius,
        center.dy + math.sin(angle) * scaledRadius,
      );
      index == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant _CompactRadarPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.preferenceValues != preferenceValues ||
      oldDelegate.radius != radius;
}

List<double> _profileValues(SakeTasteProfileDetails profile) => [
  profile.fruity,
  profile.sweetness,
  profile.acidity,
  profile.body ?? profile.umami,
  profile.kire,
  profile.dryness,
];

List<double> _preferenceValues(TastePreferenceProfile preference) => [
  preference.fruity,
  preference.sweetness,
  preference.acidity,
  preference.umami,
  preference.kire,
  preference.spiciness,
];
