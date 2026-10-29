import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const japanMapNavy = Color(0xFF143861);
const japanMapOrange = Color(0xFFFF914D);

class JapanSakePrefecture {
  JapanSakePrefecture({
    required this.code,
    required this.name,
    required this.englishName,
    required this.path,
  });
  final int code;
  final String name;
  final String englishName;
  final Path path;
  late final Rect bounds = path.getBounds();
  late final List<Offset> dots = [
    for (double y = (bounds.top / 8).floor() * 8; y <= bounds.bottom; y += 8)
      for (double x = (bounds.left / 8).floor() * 8; x <= bounds.right; x += 8)
        if (path.contains(Offset(x, y))) Offset(x, y),
  ];

  String label(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'en' ? englishName : name;
}

class JapanSakeMapData {
  static List<JapanSakePrefecture>? _data;
  static Future<List<JapanSakePrefecture>>? _pending;
  static Future<List<JapanSakePrefecture>> load() {
    if (_data != null) return SynchronousFuture(_data!);
    return _pending ??= _load()
        .then((data) {
          _data = data;
          return data;
        })
        .whenComplete(() => _pending = null);
  }

  static Future<List<JapanSakePrefecture>> _load() async {
    final json =
        jsonDecode(
              await rootBundle.loadString('assets/data/japan_sake_map.json'),
            )
            as Map;
    return (json['prefectures'] as List)
        .map((value) {
          final item = value as Map;
          final path = Path()..fillType = PathFillType.evenOdd;
          for (final ring in item['rings'] as List) {
            final points = (ring as List)
                .map(
                  (p) => Offset(
                    (p[0] as num).toDouble(),
                    (p[1] as num).toDouble(),
                  ),
                )
                .toList();
            path.addPolygon(points, true);
          }
          return JapanSakePrefecture(
            code: item['code'] as int,
            name: item['name'] as String,
            englishName: item['englishName'] as String,
            path: path,
          );
        })
        .toList(growable: false);
  }
}

/// Offline display map. The prefecture list also provides accessible selection.
class JapanSakeMap extends StatelessWidget {
  const JapanSakeMap({
    super.key,
    required this.prefectures,
    this.selectedCode,
    required this.onSelected,
  });
  final List<JapanSakePrefecture> prefectures;
  final int? selectedCode;
  final ValueChanged<JapanSakePrefecture> onSelected;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = constraints.biggest;
      final scale = math.min(size.width / 720, size.height / 760);
      final offset = Offset(
        (size.width - 720 * scale) / 2,
        (size.height - 760 * scale) / 2,
      );
      return GestureDetector(
        key: const ValueKey('japan-sake-map'),
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) {
          final point = (details.localPosition - offset) / scale;
          for (final prefecture in prefectures.reversed) {
            if (prefecture.path.contains(point)) {
              onSelected(prefecture);
              return;
            }
          }
        },
        child: CustomPaint(
          size: size,
          painter: _JapanMapPainter(prefectures, selectedCode),
        ),
      );
    },
  );
}

class _JapanMapPainter extends CustomPainter {
  const _JapanMapPainter(this.prefectures, this.selectedCode);
  final List<JapanSakePrefecture> prefectures;
  final int? selectedCode;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 720, size.height / 760);
    canvas.save();
    canvas.translate(
      (size.width - 720 * scale) / 2,
      (size.height - 760 * scale) / 2,
    );
    canvas.scale(scale);
    for (final prefecture in prefectures) {
      final selected = prefecture.code == selectedCode;
      canvas.drawPath(
        prefecture.path,
        Paint()..color = selected ? japanMapOrange : const Color(0xFFE1E9E9),
      );
      if (!selected) {
        final dot = Paint()..color = japanMapNavy.withValues(alpha: .58);
        for (final point in prefecture.dots) {
          canvas.drawCircle(point, 2.15, dot);
        }
      }
      canvas.drawPath(
        prefecture.path,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    // Separate the southwest-islands inset without moving the main islands.
    canvas.drawLine(
      const Offset(470, 590),
      const Offset(680, 590),
      Paint()
        ..color = japanMapNavy.withValues(alpha: .18)
        ..strokeWidth = 2,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_JapanMapPainter oldDelegate) =>
      oldDelegate.selectedCode != selectedCode ||
      oldDelegate.prefectures != prefectures;
}
