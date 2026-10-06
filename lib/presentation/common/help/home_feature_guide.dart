import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ホームの2つの撮影ボタンを同時に案内するフォーカスガイド。
class HomeFeatureGuide {
  final headerScanKey = GlobalKey();
  final bottomScanKey = GlobalKey();
  final searchKey = GlobalKey();
  final mapKey = GlobalKey();
  final recommendationsKey = GlobalKey();
  final homeScrollController = ScrollController();
  bool _showing = false;
  static const _preferenceKey = 'home_feature_guide_shown_v1';

  void dispose() => homeScrollController.dispose();

  Future<Rect?> _scrollToRecommendations() async {
    if (!homeScrollController.hasClients) return null;
    // ListView の画面外の子が構築されるまで少しずつ進める。
    for (var i = 0; recommendationsKey.currentContext == null && i < 12; i++) {
      final position = homeScrollController.position;
      final next = (position.pixels + position.viewportDimension * .6).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if (next == position.pixels) break;
      await homeScrollController.animateTo(
        next,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
      );
      await WidgetsBinding.instance.endOfFrame;
      if (!homeScrollController.hasClients) return null;
    }
    final targetContext = recommendationsKey.currentContext;
    if (targetContext == null || !targetContext.mounted) return null;
    await Scrollable.ensureVisible(
      targetContext,
      alignment: .08,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );
    await WidgetsBinding.instance.endOfFrame;
    final box = recommendationsKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> showIfNeeded(
    BuildContext context,
    bool Function() isHome, {
    bool force = false,
  }) async {
    if (_showing) return;
    _showing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!force && prefs.getBool(_preferenceKey) == true) return;
      await WidgetsBinding.instance.endOfFrame;
      if (!context.mounted ||
          !isHome() ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      if (homeScrollController.hasClients) {
        await homeScrollController.animateTo(
          homeScrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
        );
        await WidgetsBinding.instance.endOfFrame;
      }
      if (!context.mounted ||
          !isHome() ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      Rect? bounds(GlobalKey key) {
        final box = key.currentContext?.findRenderObject();
        if (box is! RenderBox || !box.attached || !box.hasSize) return null;
        return box.localToGlobal(Offset.zero) & box.size;
      }

      final headerScan = bounds(headerScanKey);
      final bottomScan = bounds(bottomScanKey);
      final search = bounds(searchKey);
      final map = bounds(mapKey);
      if (headerScan == null ||
          bottomScan == null ||
          search == null ||
          map == null) {
        return;
      }
      final completed = await showGeneralDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, __, ___) => _HomeGuideOverlay(
          scrollToRecommendations: _scrollToRecommendations,
          mapBounds: () => bounds(mapKey),
          targets: [
            [headerScan, bottomScan],
            [search],
            [map],
          ],
        ),
      );
      if (completed == true) await prefs.setBool(_preferenceKey, true);
    } finally {
      _showing = false;
    }
  }
}

class _HomeGuideOverlay extends StatefulWidget {
  const _HomeGuideOverlay({
    required this.targets,
    required this.scrollToRecommendations,
    required this.mapBounds,
  });
  final Future<Rect?> Function() scrollToRecommendations;
  final Rect? Function() mapBounds;
  final List<List<Rect>> targets;

  @override
  State<_HomeGuideOverlay> createState() => _HomeGuideOverlayState();
}

class _HomeGuideOverlayState extends State<_HomeGuideOverlay> {
  int _step = -1;
  Rect? _mapBounds;
  bool _scrolling = false;
  Rect? _recommendations;
  static const _messages = [
    'ラベルから高速検索！今までの体感３倍の速度！',
    '名前やメニューからなど検索可能！',
    '新機能なのでまだまだですが近くでどんな日本酒が飲めるかじきにわかるようになるはず！',
    'マイページから好きなお酒の傾向を登録するとあなたの好きな日本酒がここに表示されます！',
  ];
  static const _titles = ['高速ラベル検索', 'いろいろな条件で検索', 'マップ機能', 'あなたが好きそうな日本酒'];

  Future<void> _next() async {
    if (_scrolling) return;
    if (_step == 3) {
      Navigator.of(context).pop(true);
    } else if (_step == 2) {
      setState(() => _scrolling = true);
      final target = await widget.scrollToRecommendations();
      if (!mounted) return;
      setState(() {
        _recommendations = target;
        _scrolling = false;
        _step = 3;
      });
    } else {
      if (_step == 1) {
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
        _mapBounds = widget.mapBounds();
      }
      setState(() => _step++);
    }
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _next,
          child: CustomPaint(
            painter: _HomeGuideFocusPainter(
              targets: _scrolling || _step == -1
                  ? const []
                  : _step == 3
                  ? [if (_recommendations != null) _recommendations!]
                  : _step == 2 && _mapBounds != null
                  ? [_mapBounds!]
                  : widget.targets[_step],
              circles: _step == 0,
              outline: _step == 2,
            ),
          ),
        ),
        if (!_scrolling)
          Align(
            alignment: _step == 3 ? Alignment.bottomCenter : Alignment.center,
            child: Padding(
              padding: _step == 3
                  ? EdgeInsets.fromLTRB(
                      24,
                      24,
                      24,
                      MediaQuery.paddingOf(context).bottom + 100,
                    )
                  : const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: _step == -1
                        ? CrossAxisAlignment.stretch
                        : CrossAxisAlignment.start,
                    children: [
                      if (_step >= 0)
                        Text(
                          '${_step + 1} / 4',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      if (_step == -1) ...[
                        Center(
                          child: Container(
                            width: 120,
                            height: 120,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF143861),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Image.asset(
                              'assets/images/sake_logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ] else
                        const SizedBox(height: 8),
                      Text(
                        _step == -1 ? '新SAKEPEDIAへようこそ！' : _titles[_step],
                        textAlign: _step == -1
                            ? TextAlign.center
                            : TextAlign.start,
                        style: const TextStyle(
                          color: Color(0xFF1D3567),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _step == -1 ? '新機能の説明を簡単にさせていただきます！' : _messages[_step],
                        textAlign: _step == -1
                            ? TextAlign.center
                            : TextAlign.start,
                        style: const TextStyle(
                          color: Color(0xFF1D3567),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: _next,
                          child: Text(_step == 3 ? 'わかった' : '次へ'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + 8,
          right: 16,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('スキップ', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    ),
  );
}

class _HomeGuideFocusPainter extends CustomPainter {
  const _HomeGuideFocusPainter({
    required this.targets,
    required this.circles,
    this.outline = false,
  });
  final List<Rect> targets;
  final bool circles;
  final bool outline;

  @override
  void paint(Canvas canvas, Size size) {
    final shadow = Path()..addRect(Offset.zero & size);
    for (final target in targets) {
      final rect = target.inflate(8);
      final hole = Path();
      if (circles) {
        hole.addOval(rect);
      } else {
        hole.addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(14)));
      }
      final cutout = Path.combine(PathOperation.difference, shadow, hole);
      shadow.reset();
      shadow.addPath(cutout, Offset.zero);
    }
    canvas.drawPath(
      shadow,
      Paint()..color = Colors.black.withValues(alpha: .85),
    );
    if (outline) {
      for (final target in targets) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(target.inflate(8), const Radius.circular(14)),
          Paint()
            ..color = const Color(0xFFFFD166)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HomeGuideFocusPainter oldDelegate) =>
      oldDelegate.targets != targets ||
      oldDelegate.circles != circles ||
      oldDelegate.outline != outline;
}
