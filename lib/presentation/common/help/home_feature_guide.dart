import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ホームの撮影・検索・メニュー解析などを案内するフォーカスガイド。
class HomeFeatureGuide {
  final headerScanKey = GlobalKey();
  final bottomScanKey = GlobalKey();
  final searchKey = GlobalKey();
  final menuAnalysisKey = GlobalKey();
  final mapKey = GlobalKey();
  final myPageKey = GlobalKey();
  final recommendationsKey = GlobalKey();
  final homeScrollController = ScrollController();
  bool _showing = false;
  static const _preferenceKey = 'home_feature_guide_shown_v3';

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
        final targetContext = key.currentContext;
        final box = targetContext?.findRenderObject();
        if (box is! RenderBox || !box.attached || !box.hasSize) return null;
        final rect = box.localToGlobal(Offset.zero) & box.size;
        if (key == recommendationsKey && targetContext != null) {
          final viewport = Scrollable.maybeOf(
            targetContext,
          )?.context.findRenderObject();
          if (viewport is RenderBox && viewport.attached && viewport.hasSize) {
            return rect.intersect(
              viewport.localToGlobal(Offset.zero) & viewport.size,
            );
          }
        }
        return rect;
      }

      final targetKeys = [
        [headerScanKey, bottomScanKey],
        [searchKey],
        [menuAnalysisKey],
        [mapKey],
        [myPageKey],
        [recommendationsKey],
      ];
      if (targetKeys
          .take(5)
          .expand((keys) => keys)
          .any((key) => bounds(key) == null)) {
        return;
      }
      final completed = await showGeneralDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, __, ___) => FeatureGuideOverlay(
          bottomMessageStep: 5,
          titles: const [
            '高速ラベル検索',
            'いろいろな条件で検索',
            'メニュー解析',
            'マップ機能',
            'マイページ',
            'あなたが好きそうな日本酒',
          ],
          messages: const [
            'ラベルから高速検索！今までの体感３倍の速度！',
            '名前やメニューからなど検索可能！',
            'お店のメニューを撮影すると、日本酒の一覧とあなたの好みマッチ度を確認できます。撮影後に必要な部分を切り抜けます。解析履歴はマイページからも見られます！',
            '近くでどんな日本酒が飲めるか、マップから探してみましょう。',
            '保存したお酒やメニュー解析履歴はここから。好みの設定、ポイントやバッジもマイページで確認できます。',
            'マイページで好きなお酒の傾向を登録すると、あなたに合いそうな日本酒がここに表示されます！',
          ],
          circleSteps: const {0, 4},
          outlineSteps: const {2, 3},
          prepareStep: (step) async {
            if (step == 5) await _scrollToRecommendations();
          },
          readTargets: (step) => [
            for (final key in targetKeys[step])
              if (bounds(key) case final Rect rect) rect,
          ],
        ),
      );
      if (completed == true) await prefs.setBool(_preferenceKey, true);
    } finally {
      _showing = false;
    }
  }
}

class FeatureGuideOverlay extends StatefulWidget {
  const FeatureGuideOverlay({
    super.key,
    required this.readTargets,
    required this.prepareStep,
    required this.titles,
    required this.messages,
    this.circleSteps = const {},
    this.outlineSteps = const {},
    this.welcomeTitle = '新SAKEPEDIAへようこそ！',
    this.welcomeMessage = '新機能の説明を簡単にさせていただきます！',
    this.bottomMessageStep,
  });
  final Future<void> Function(int step) prepareStep;
  final List<String> titles;
  final List<String> messages;
  final Set<int> circleSteps;
  final Set<int> outlineSteps;
  final String welcomeTitle;
  final String welcomeMessage;
  final int? bottomMessageStep;
  final List<Rect> Function(int step) readTargets;

  @override
  State<FeatureGuideOverlay> createState() => FeatureGuideOverlayState();
}

class FeatureGuideOverlayState extends State<FeatureGuideOverlay> {
  int _step = -1;
  bool _scrolling = false;
  final GlobalKey _overlayKey = GlobalKey();
  List<Rect> _focusRects = const [];
  Timer? _focusTimer;

  @override
  void initState() {
    super.initState();
    // Track late-loading content and viewport changes only while the guide is open.
    _focusTimer = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _refreshFocus(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshFocus());
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    super.dispose();
  }

  void _refreshFocus() {
    if (!mounted) return;
    final overlay = _overlayKey.currentContext?.findRenderObject();
    if (overlay is! RenderBox || !overlay.attached || !overlay.hasSize) return;
    final viewport = Offset.zero & overlay.size;
    final rects = <Rect>[];
    if (!_scrolling && _step >= 0) {
      for (final globalRect in widget.readTargets(_step)) {
        final localRect = Rect.fromPoints(
          overlay.globalToLocal(globalRect.topLeft),
          overlay.globalToLocal(globalRect.bottomRight),
        );
        final visible = localRect.intersect(viewport);
        if (!visible.isEmpty) rects.add(visible);
      }
    }
    if (!listEquals(_focusRects, rects)) setState(() => _focusRects = rects);
  }

  Future<void> _next() async {
    if (_scrolling) return;
    if (_step == widget.titles.length - 1) {
      Navigator.of(context).pop(true);
      return;
    }
    final nextStep = _step + 1;
    setState(() => _scrolling = true);
    await widget.prepareStep(nextStep);
    if (!mounted) return;
    setState(() {
      _scrolling = false;
      _step = nextStep;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshFocus());
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: Stack(
      key: _overlayKey,
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _next,
          child: CustomPaint(
            painter: _HomeGuideFocusPainter(
              targets: _scrolling ? const [] : _focusRects,
              circles: widget.circleSteps.contains(_step),
              outline: widget.outlineSteps.contains(_step),
            ),
          ),
        ),
        if (!_scrolling)
          Align(
            alignment: _step == widget.bottomMessageStep
                ? Alignment.bottomCenter
                : Alignment.center,
            child: Padding(
              padding: _step == widget.bottomMessageStep
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
                          '${_step + 1} / ${widget.titles.length}',
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
                        _step == -1
                            ? widget.welcomeTitle
                            : widget.titles[_step],
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
                        _step == -1
                            ? widget.welcomeMessage
                            : widget.messages[_step],
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
                          child: Text(
                            _step == widget.titles.length - 1 ? 'わかった' : '次へ',
                          ),
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
          left: 16,
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
