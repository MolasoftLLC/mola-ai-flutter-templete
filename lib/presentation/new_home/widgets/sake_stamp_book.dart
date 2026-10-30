import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../domain/eintities/sake_catalog_browse.dart';
import 'japan_sake_map.dart';
import 'sake_stamp_page_turn.dart';

const _ink = Color(0xFFB73927);
const _unearnedInk = Color(0xFFAAA59A);

/// A short, nine-brand page sharing the catalog list's loaded pages.
class SakeStampBook extends StatefulWidget {
  const SakeStampBook({
    super.key,
    required this.prefectureName,
    required this.brands,
    required this.recordedBrandIds,
    required this.recordsReady,
    required this.onBrandTap,
    required this.hasMore,
    required this.loading,
    required this.failed,
    required this.loadMore,
    this.height = 212,
    this.preview = false,
  });
  final String prefectureName;
  final List<SakeBrandSummary> brands;
  final Set<int> recordedBrandIds;
  final bool recordsReady;
  final ValueChanged<SakeBrandSummary> onBrandTap;
  final bool hasMore;
  final bool loading;
  final bool failed;
  final VoidCallback loadMore;
  final double height;

  /// A single, non-interactive cover showing the total collected brand count.
  final bool preview;
  @override
  State<SakeStampBook> createState() => _SakeStampBookState();
}

class _SakeStampBookState extends State<SakeStampBook> {
  final _pageTurn = SakeStampPageTurnController();
  int? _dragTarget;
  int _dragStartPage = 0;
  double _dragDistance = 0;
  bool _allowDrag = false;
  int _page = 0;
  int? _requestedLength;
  int get _pages => math.max(
    1,
    (widget.brands.length + 8) ~/ 9 +
        (widget.hasMore && widget.brands.length % 9 == 0 ? 1 : 0),
  );

  void _loadIfNeeded() {
    if (widget.preview ||
        !widget.hasMore ||
        widget.loading ||
        widget.failed ||
        (_page + 1) * 9 <= widget.brands.length ||
        _requestedLength == widget.brands.length) {
      return;
    }
    _requestedLength = widget.brands.length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.loadMore();
    });
  }

  @override
  void didUpdateWidget(covariant SakeStampBook oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Origin lookups and saved-record changes update ink without moving pages.
    if (oldWidget.brands.length != widget.brands.length ||
        (oldWidget.loading && !widget.loading)) {
      _loadIfNeeded();
    }
  }

  void _showPage(int page) {
    if (!mounted) return;
    setState(() => _page = page);
    _loadIfNeeded();
  }

  void _goTo(int page) {
    if (page == _page || page < 0 || page >= _pages) return;
    _pageTurn.turn(() => _showPage(page), backwards: page < _page);
  }

  void _startDrag(DragStartDetails details) {
    _allowDrag = !_pageTurn.isBusy;
    _dragStartPage = _page;
    _dragTarget = null;
    _dragDistance = 0;
  }

  void _updateDrag(DragUpdateDetails details) {
    if (!_allowDrag) return;
    _dragDistance += details.delta.dx;
    if (_dragTarget == null) {
      if (_dragDistance == 0) return;
      final target = _dragStartPage + (_dragDistance < 0 ? 1 : -1);
      if (target < 0 || target >= _pages) return;
      _dragTarget = target;
      _pageTurn.begin(
        () => _showPage(target),
        backwards: target < _dragStartPage,
      );
    }
    final distance = _dragTarget! < _dragStartPage
        ? _dragDistance
        : -_dragDistance;
    _pageTurn.update(distance / (context.size?.width ?? 1));
  }

  void _endDrag([DragEndDetails? details]) {
    final target = _dragTarget;
    if (target == null) return;
    final from = _dragStartPage;
    final speed = details?.primaryVelocity ?? 0;
    final forward = target > from;
    final progress =
        (forward ? -_dragDistance : _dragDistance) / (context.size?.width ?? 1);
    final commit =
        details != null &&
        (speed.abs() > 650
            ? (forward ? speed < 0 : speed > 0)
            : progress > .24);
    _allowDrag = false;
    _dragTarget = null;
    _pageTurn.finish(commit: commit, onCancel: () => _showPage(from));
  }

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final visible = widget.brands.skip(_page * 9).take(9).toList();
    final earned = visible
        .where((b) => widget.recordedBrandIds.contains(b.brandId))
        .length;
    final paper = Container(
      key: const ValueKey('sake-stamp-book'),
      height: widget.height,
      margin: const EdgeInsets.only(top: 12, bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6E5532).withValues(alpha: .10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: CustomPaint(
        painter: const SakeStampPaperPainter(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(19, 8, 10, 8),
          child: Column(
            children: [
              SizedBox(
                height: 28,
                child: Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${widget.prefectureName} ${english ? 'Sake stamps' : '酒印帳'}',
                          style: const TextStyle(
                            fontFamily: 'SakeSeal',
                            fontSize: 21,
                            color: japanMapNavy,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Semantics(
                      label: widget.preview
                          ? (english ? 'Collected brands' : '現在の酒印銘柄数')
                          : (english
                                ? 'Recorded brands on this page'
                                : 'このページの記録した銘柄'),
                      child: Text(
                        visible.isEmpty && widget.hasMore
                            ? (english
                                  ? 'Loading…'
                                  : widget.failed
                                  ? '未取得'
                                  : '読込中…')
                            : widget.recordsReady
                            ? widget.preview
                                  ? (english
                                        ? '${widget.recordedBrandIds.length} brands collected'
                                        : '現在${widget.recordedBrandIds.length}銘柄')
                                  : '$earned / ${visible.length}'
                            : (english ? 'Unconfirmed' : '記録未確認'),
                        key: const ValueKey('stamp-page-earned'),
                        style: TextStyle(
                          color: widget.recordsReady ? _ink : _unearnedInk,
                          fontSize: widget.recordsReady ? 16 : 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Column(
                  children: [
                    for (var row = 0; row < 3; row++)
                      Expanded(
                        child: Row(
                          children: [
                            for (var col = 0; col < 3; col++)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: row * 3 + col < visible.length
                                      ? _BrandSeal(
                                          brand: visible[row * 3 + col],
                                          earned:
                                              widget.recordsReady &&
                                              widget.recordedBrandIds.contains(
                                                visible[row * 3 + col].brandId,
                                              ),
                                          ready: widget.recordsReady,
                                          onTap: () => widget.onBrandTap(
                                            visible[row * 3 + col],
                                          ),
                                        )
                                      : const ExcludeSemantics(
                                          child: Center(
                                            child: Text(
                                              '・',
                                              style: TextStyle(
                                                color: Color(0xFFDCD3C1),
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (!widget.preview)
                SizedBox(
                  height: 28,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _PageArrow(
                        key: const ValueKey('stamp-previous'),
                        icon: Icons.chevron_left,
                        label: english ? 'Previous stamp page' : '前の酒印帳',
                        onTap: _page > 0 ? () => _goTo(_page - 1) : null,
                      ),
                      if (widget.failed &&
                          (_page + 1) * 9 > widget.brands.length &&
                          widget.hasMore)
                        TextButton(
                          key: const ValueKey('stamp-retry'),
                          onPressed: widget.loadMore,
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            foregroundColor: _ink,
                          ),
                          child: Text(
                            english ? 'Retry' : '再読み込み',
                            style: const TextStyle(fontSize: 11),
                          ),
                        )
                      else if (widget.loading &&
                          (_page + 1) * 9 > widget.brands.length)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: SizedBox.square(
                            dimension: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: _ink,
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '${_page + 1} / ${widget.hasMore ? '…' : _pages}',
                            key: const ValueKey('stamp-page-number'),
                            style: const TextStyle(
                              color: japanMapNavy,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      for (
                        var i = math.max(0, math.min(_page - 1, _pages - 4));
                        i < math.min(_pages, math.max(4, _page + 3));
                        i++
                      )
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Container(
                            width: i == _page ? 6 : 4,
                            height: i == _page ? 6 : 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == _page
                                  ? _ink
                                  : const Color(0xFFD7D1C7),
                            ),
                          ),
                        ),
                      _PageArrow(
                        key: const ValueKey('stamp-next'),
                        icon: Icons.chevron_right,
                        label: english ? 'Next stamp page' : '次の酒印帳',
                        onTap: _page + 1 < _pages
                            ? () => _goTo(_page + 1)
                            : null,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (widget.preview) return paper;
    return SakeStampPageTurn(
      controller: _pageTurn,
      child: GestureDetector(
        key: const ValueKey('sake-stamp-pages'),
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: _startDrag,
        onHorizontalDragUpdate: _updateDrag,
        onHorizontalDragEnd: _endDrag,
        onHorizontalDragCancel: _endDrag,
        child: paper,
      ),
    );
  }
}

class _PageArrow extends StatelessWidget {
  const _PageArrow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    enabled: onTap != null,
    child: InkResponse(
      onTap: onTap,
      radius: 22,
      child: SizedBox(
        width: 44,
        height: 28,
        child: Icon(
          icon,
          size: 22,
          color: onTap == null ? const Color(0xFFD1C7B6) : japanMapNavy,
        ),
      ),
    ),
  );
}

class _BrandSeal extends StatelessWidget {
  const _BrandSeal({
    required this.brand,
    required this.earned,
    required this.ready,
    required this.onTap,
  });
  final SakeBrandSummary brand;
  final bool earned;
  final bool ready;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final color = earned ? _ink : _unearnedInk;
    final characters = brand.name.characters.toList();
    final visible = characters.length > 10
        ? [...characters.take(9), '…']
        : characters;
    final split = (visible.length / 2).ceil();
    final label = visible.length <= 5
        ? visible.join()
        : '${visible.take(split).join()}\n${visible.skip(split).join()}';
    return Semantics(
      button: true,
      label:
          '${brand.name}、${!ready
              ? (english ? 'records unconfirmed' : '記録未確認')
              : earned
              ? (english ? 'recorded' : '記録あり')
              : (english ? 'not recorded' : '未記録')}',
      child: Tooltip(
        message: brand.name,
        excludeFromSemantics: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('brand-stamp-${brand.brandId}'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: CustomPaint(
              painter: SakeStampSealPainter(brand.brandId, color),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ExcludeSemantics(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        softWrap: false,
                        style: TextStyle(
                          fontFamily: 'SakeSeal',
                          fontWeight: FontWeight.w600,
                          color: color,
                          fontSize: visible.length <= 5 ? 21 : 17,
                          height: 1.05,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared washi background for the stamp book and its animation preview.
class SakeStampPaperPainter extends CustomPainter {
  const SakeStampPaperPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(4, 1, size.width - 5, size.height - 3),
      const Radius.circular(14),
    );
    canvas.drawRRect(
      rect.shift(const Offset(-3, 1)),
      Paint()..color = const Color(0xFFE8DDC5),
    );
    canvas.drawRRect(rect, Paint()..color = const Color(0xFFFFFAEF));
    canvas.drawRRect(
      rect.deflate(4),
      Paint()
        ..color = const Color(0xFFDBCDB0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .65,
    );
    canvas.save();
    canvas.clipRRect(rect);
    final random = math.Random(42);
    final fiber = Paint()
      ..color = const Color(0xFFB5A386).withValues(alpha: .10)
      ..strokeWidth = .5;
    for (var i = 0; i < 250; i++) {
      final p = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      canvas.drawLine(
        p,
        p + Offset(1 + random.nextDouble() * 5, random.nextDouble() * 2),
        fiber,
      );
    }
    canvas.drawLine(
      Offset(size.width / 2, 6),
      Offset(size.width / 2, size.height - 6),
      Paint()
        ..color = const Color(0xFFD7C8AD).withValues(alpha: .25)
        ..strokeWidth = .5,
    );
    canvas.restore();
    final binding = Paint()
      ..color = _ink.withValues(alpha: .75)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (final y in [size.height * .20, size.height * .5, size.height * .80]) {
      canvas.drawLine(Offset(1, y + 1), Offset(10, y - 1), binding);
      canvas.drawCircle(Offset(10, y - 1), 1.5, binding);
    }
  }

  @override
  bool shouldRepaint(covariant SakeStampPaperPainter oldDelegate) => false;
}

/// Deterministic, distressed seal outline shared by book stamps and previews.
class SakeStampSealPainter extends CustomPainter {
  const SakeStampSealPainter(this.seed, this.color);
  final int seed;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final rect = Rect.fromLTWH(3, 2.5, size.width - 6, size.height - 5);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    final ellipse = seed % 3 == 1;
    const points = 64;
    for (var i = 0; i <= points; i++) {
      final t = i / points;
      final a = t * math.pi * 2;
      final jitter = (random.nextDouble() - .5) * 1.3;
      final Offset p;
      if (ellipse) {
        p =
            rect.center +
            Offset(
              (rect.width / 2 + jitter) * math.cos(a),
              (rect.height / 2 + jitter) * math.sin(a),
            );
      } else {
        final edge = t * 4;
        p = edge < 1
            ? Offset(rect.left + rect.width * edge, rect.top + jitter)
            : edge < 2
            ? Offset(rect.right + jitter, rect.top + rect.height * (edge - 1))
            : edge < 3
            ? Offset(rect.right - rect.width * (edge - 2), rect.bottom + jitter)
            : Offset(
                rect.left + jitter,
                rect.bottom - rect.height * (edge - 3),
              );
      }
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
    if (!ellipse) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(3)),
        paint..strokeWidth = .55,
      );
    }
    final ornament = Paint()
      ..color = color.withValues(alpha: .65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7;
    final baseline = rect.bottom - 2;
    if (ellipse) {
      final wave = Path()..moveTo(rect.center.dx - 14, baseline);
      for (var i = 0; i < 4; i++) {
        final x = rect.center.dx - 14 + i * 7;
        wave.quadraticBezierTo(x + 3.5, baseline - 3, x + 7, baseline);
      }
      canvas.drawPath(wave, ornament);
    } else if (seed % 3 == 0) {
      canvas.drawPath(
        Path()
          ..moveTo(rect.center.dx - 11, baseline)
          ..lineTo(rect.center.dx - 2, baseline - 4)
          ..lineTo(rect.center.dx + 9, baseline)
          ..moveTo(rect.center.dx + 2, baseline - 2)
          ..lineTo(rect.center.dx + 8, baseline - 4)
          ..lineTo(rect.center.dx + 14, baseline),
        ornament,
      );
    }
    final fleck = Paint()
      ..color = const Color(0xFFFFFAEF).withValues(alpha: .75)
      ..strokeWidth = .7;
    for (var i = 0; i < 20; i++) {
      final y = random.nextDouble() * size.height;
      final x = random.nextBool() ? rect.left : rect.right;
      canvas.drawLine(Offset(x - 1, y), Offset(x + 1, y + .5), fleck);
    }
  }

  @override
  bool shouldRepaint(covariant SakeStampSealPainter oldDelegate) =>
      oldDelegate.seed != seed || oldDelegate.color != color;
}
