import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_feature_guide.dart';

/// マイページの見出しを実際の位置に合わせて案内する。
class MyPageFeatureGuide {
  final accountKey = GlobalKey();
  final savedKey = GlobalKey();
  final historyKey = GlobalKey();
  final favoritesKey = GlobalKey();
  final preferencesKey = GlobalKey();
  final scrollController = ScrollController();
  bool _showing = false;
  static const _preferenceKey = 'my_page_feature_guide_shown_v1';

  List<GlobalKey> get _keys => [
    accountKey,
    savedKey,
    historyKey,
    favoritesKey,
    preferencesKey,
  ];

  void dispose() => scrollController.dispose();

  Rect? _bounds(int step) {
    final targetContext = _keys[step].currentContext;
    final box = targetContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    // 長い一覧全体ではなく、機能を示す見出しをフォーカスする。
    var rect =
        box.localToGlobal(Offset.zero) &
        Size(
          box.size.width,
          box.size.height.clamp(0, step == 0 ? 120 : 64).toDouble(),
        );
    final viewport = targetContext == null
        ? null
        : Scrollable.maybeOf(targetContext)?.context.findRenderObject();
    if (viewport is RenderBox && viewport.attached && viewport.hasSize) {
      rect = rect.intersect(
        viewport.localToGlobal(Offset.zero) & viewport.size,
      );
    }
    return rect.isEmpty ? null : rect;
  }

  Future<void> showIfNeeded(BuildContext context, {bool force = false}) async {
    if (_showing) return;
    _showing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!force && prefs.getBool(_preferenceKey) == true) return;
      await WidgetsBinding.instance.endOfFrame;
      if (!context.mounted || ModalRoute.of(context)?.isCurrent != true) return;
      if (_keys.any((key) => key.currentContext == null)) return;
      FocusScope.of(context).unfocus();
      final completed = await showGeneralDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, __, ___) => FeatureGuideOverlay(
          welcomeTitle: 'マイページの使い方',
          welcomeMessage: 'お酒の記録や、あなたの好みをまとめて管理できます。主な機能をご案内します。',
          titles: const [
            'プロフィール・ポイント',
            '保存したお酒',
            'メニュー解析履歴',
            'お気に入りのお酒',
            '好きなお酒の傾向',
          ],
          messages: const [
            'プロフィールの設定やログインはこちらから。うらやま・マップ貢献ポイントやバッジは、タップすると詳しく確認できます。',
            'スキャンして保存したお酒を振り返れます。お酒をタップして、写真や飲んだ場所などの記録を確認しましょう。',
            '解析したメニューの履歴を確認できます。履歴をタップすると、お酒の詳細や好みマッチ度を見返せます。「もっと見る」で過去の履歴を開けます。',
            '気になるお酒はハートでお気に入りに。好きなお酒を２つ以上登録すると、好み診断も利用できます。',
            '好きな味やお酒の傾向を入力して保存しましょう。好みの設定は、メニュー解析のマッチ度やホームのおすすめに使われます。',
          ],
          outlineSteps: const {0, 1, 2, 3, 4},
          readTargets: (step) => [if (_bounds(step) case final Rect rect) rect],
          prepareStep: (step) async {
            final target = _keys[step].currentContext;
            if (target == null || !target.mounted) return;
            await Scrollable.ensureVisible(
              target,
              alignment: .03,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutCubic,
            );
            await WidgetsBinding.instance.endOfFrame;
          },
        ),
      );
      if (completed == true) await prefs.setBool(_preferenceKey, true);
    } finally {
      _showing = false;
    }
  }
}
