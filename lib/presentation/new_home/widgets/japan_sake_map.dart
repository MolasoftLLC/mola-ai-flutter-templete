import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const japanMapNavy = Color(0xFF143861);
const japanMapOrange = Color(0xFFFF914D);

Color sakeJourneyColor(int count) => count >= 10
    ? japanMapOrange
    : count >= 5
    ? const Color(0xFFFFD54F)
    : count >= 1
    ? const Color(0xFFFFEDB2)
    : const Color(0xFFE1E9E9);

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
    this.productCounts = const {},
    required this.onSelected,
  });
  final List<JapanSakePrefecture> prefectures;
  final int? selectedCode;
  final Map<int, int> productCounts;
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
          painter: _JapanMapPainter(prefectures, selectedCode, productCounts),
        ),
      );
    },
  );
}

class _JapanMapPainter extends CustomPainter {
  const _JapanMapPainter(
    this.prefectures,
    this.selectedCode,
    this.productCounts,
  );
  final List<JapanSakePrefecture> prefectures;
  final int? selectedCode;
  final Map<int, int> productCounts;

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
        Paint()..color = sakeJourneyColor(productCounts[prefecture.code] ?? 0),
      );
      if ((productCounts[prefecture.code] ?? 0) == 0) {
        final dot = Paint()..color = japanMapNavy.withValues(alpha: .58);
        for (final point in prefecture.dots) {
          canvas.drawCircle(point, 2.15, dot);
        }
      }
      canvas.drawPath(
        prefecture.path,
        Paint()
          ..color = selected ? japanMapNavy : Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 4 : 2,
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
      oldDelegate.prefectures != prefectures ||
      !mapEquals(oldDelegate.productCounts, productCounts);
}

/// Keeps taps in map coordinates while the viewer applies zoom and pan.
class ZoomableJapanSakeMap extends StatefulWidget {
  const ZoomableJapanSakeMap({
    super.key,
    required this.prefectures,
    required this.onSelected,
    this.selectedCode,
    this.productCounts = const {},
    this.onExpand,
  });
  final List<JapanSakePrefecture> prefectures;
  final ValueChanged<JapanSakePrefecture> onSelected;
  final int? selectedCode;
  final Map<int, int> productCounts;
  final VoidCallback? onExpand;
  @override
  State<ZoomableJapanSakeMap> createState() => _ZoomableJapanSakeMapState();
}

class _ZoomableJapanSakeMapState extends State<ZoomableJapanSakeMap> {
  final _transform = TransformationController();
  double _scale = 1;
  Offset _doubleTap = Offset.zero;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_changed);
  }

  void _changed() {
    final next = _transform.value.getMaxScaleOnAxis();
    if ((next - _scale).abs() > .01) setState(() => _scale = next);
  }

  @override
  void dispose() {
    _transform.removeListener(_changed);
    _transform.dispose();
    super.dispose();
  }

  void _zoom(double target, Offset center) {
    final scale = target.clamp(1.0, 6.0);
    final scene = _transform.toScene(center);
    _transform.value = scale == 1
        ? Matrix4.identity()
        : (Matrix4.diagonal3Values(scale, scale, 1)..setTranslationRaw(
            center.dx - scene.dx * scale,
            center.dy - scene.dy * scale,
            0,
          ));
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final center = Size(
        constraints.maxWidth,
        constraints.maxHeight - 56,
      ).center(Offset.zero);
      final english = Localizations.localeOf(context).languageCode == 'en';
      return Stack(
        children: [
          Positioned.fill(
            bottom: 56,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: GestureDetector(
                onDoubleTapDown: (details) =>
                    _doubleTap = details.localPosition,
                onDoubleTap: () => _zoom(_scale > 1.1 ? 1 : 2.5, _doubleTap),
                child: InteractiveViewer(
                  key: const ValueKey('japan-map-viewer'),
                  transformationController: _transform,
                  minScale: 1,
                  maxScale: 6,
                  panEnabled: _scale > 1.01,
                  child: JapanSakeMap(
                    prefectures: widget.prefectures,
                    selectedCode: widget.selectedCode,
                    productCounts: widget.productCounts,
                    onSelected: widget.onSelected,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Material(
              color: Colors.white.withValues(alpha: .95),
              borderRadius: BorderRadius.circular(14),
              elevation: 1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: const ValueKey('japan-map-zoom-in'),
                    tooltip: english ? 'Zoom in' : '拡大',
                    color: japanMapNavy,
                    onPressed: _scale >= 5.99
                        ? null
                        : () => _zoom(_scale * 1.6, center),
                    icon: const Icon(Icons.add),
                  ),
                  IconButton(
                    key: const ValueKey('japan-map-zoom-out'),
                    tooltip: english ? 'Zoom out' : '縮小',
                    color: japanMapNavy,
                    onPressed: _scale <= 1.01
                        ? null
                        : () => _zoom(_scale / 1.6, center),
                    icon: const Icon(Icons.remove),
                  ),
                  IconButton(
                    key: const ValueKey('japan-map-reset'),
                    tooltip: english ? 'Show all Japan' : '全体を表示',
                    color: japanMapNavy,
                    onPressed: () => _transform.value = Matrix4.identity(),
                    icon: const Icon(Icons.fit_screen),
                  ),
                  if (widget.onExpand != null)
                    IconButton(
                      key: const ValueKey('japan-map-expand'),
                      tooltip: english ? 'Full screen map' : '大きな地図で選ぶ',
                      color: japanMapNavy,
                      onPressed: widget.onExpand,
                      icon: const Icon(Icons.fullscreen),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 8,
            top: 8,
            child: IgnorePointer(
              child: Text(
                english ? 'Pinch to zoom · drag to move' : 'ピンチで拡大・ドラッグで移動',
                style: const TextStyle(fontSize: 11, color: japanMapNavy),
              ),
            ),
          ),
        ],
      );
    },
  );
}
