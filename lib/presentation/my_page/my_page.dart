import 'dart:io';

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/notifier/favorite/favorite_notifier.dart';
import '../../domain/notifier/my_page/my_page_notifier.dart';
import '../../domain/notifier/saved_sake/saved_sake_notifier.dart';
import '../sake_bottle/sake_bottle_list_page.dart';
import 'saved_sake_detail_page.dart';
import 'how_to_use/how_to_use_page.dart';

class MyPage extends StatelessWidget {
  const MyPage._({Key? key}) : super(key: key);

  static Widget wrapped() {
    return const MyPage._();
  }

  void _showToast(
    BuildContext context, {
    required String message,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.amber.shade200, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1D3567).withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool _isValidText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<MyPageNotifier>();
    final isLoading = context.select((MyPageState state) => state.isLoading);
    final geminiResponse =
        context.select((MyPageState state) => state.geminiResponse);
    final myFavoriteSakeList =
        context.select((FavoriteState state) => state.myFavoriteList);
    final favNotifier = context.watch<FavoriteNotifier>();
    final savedNotifier = context.watch<SavedSakeNotifier>();
    final savedSakeList =
        context.select((SavedSakeState state) => state.savedSakeList);
    final isGridView =
        context.select((SavedSakeState state) => state.isGridView);
    final preferences =
        context.select((MyPageState state) => state.preferences);

    // Notifierから取得したTextEditingControllerを使用
    final preferencesController = notifier.preferencesController;

    return GestureDetector(
      // キーボード外タップでキーボードを閉じる
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1D3567),
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text(
            'マイページ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            // 歯車アイコンを追加
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                _showSettingsMenu(context);
              },
            ),
          ],
        ),
        body: Container(
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1D3567), Color(0xFF0A1428)],
            ),
          ),
          child: SingleChildScrollView(
            // キーボードが表示されたときにスクロール可能にする
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // 酒瓶リストセクション
                  Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SakeBottleListPage.wrapped(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.wine_bar,
                              color: Colors.amber,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              '酒瓶リスト',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 保存したお酒セクション
                  Container(
                    width: MediaQuery.of(context).size.width,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.bookmark,
                                color: Colors.amber,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                '保存したお酒',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      tooltip: 'リスト表示',
                                      splashRadius: 18,
                                      icon: Icon(
                                        Icons.view_list,
                                        color: isGridView
                                            ? Colors.white54
                                            : Colors.white,
                                      ),
                                      onPressed: () {
                                        savedNotifier.setGridView(false);
                                      },
                                    ),
                                    IconButton(
                                      tooltip: 'グリッド表示',
                                      splashRadius: 18,
                                      icon: Icon(
                                        Icons.grid_view,
                                        color: isGridView
                                            ? Colors.white
                                            : Colors.white54,
                                      ),
                                      onPressed: () {
                                        savedNotifier.setGridView(true);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (savedSakeList.isEmpty)
                          Container(
                            width: MediaQuery.of(context).size.width,
                            padding: const EdgeInsets.only(bottom: 24),
                            child: const Center(
                              child: Text(
                                'まだ保存したお酒はありません。\nメニュー検索からブックマークしてみましょう！',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        if (savedSakeList.isNotEmpty)
                          Container(
                            constraints: const BoxConstraints(maxHeight: 300),
                            child: isGridView
                                ? _SavedSakeGrid(
                                    savedSakeList: savedSakeList,
                                    onTap: (sake) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              SavedSakeDetailPage(sake: sake),
                                        ),
                                      );
                                    },
                                    onRemove: (sake) {
                                      savedNotifier.toggleSavedSake(sake);
                                      _showToast(
                                        context,
                                        message:
                                            '${sake.name ?? '名称不明'} を保存リストから削除しました',
                                        icon: Icons.bookmark_remove,
                                      );
                                    },
                                  )
                                : _SavedSakeList(
                                    savedSakeList: savedSakeList,
                                    onTap: (sake) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              SavedSakeDetailPage(sake: sake),
                                        ),
                                      );
                                    },
                                    onRemove: (sake) {
                                      savedNotifier.toggleSavedSake(sake);
                                      _showToast(
                                        context,
                                        message:
                                            '${sake.name ?? '名称不明'} を保存リストから削除しました',
                                        icon: Icons.bookmark_remove,
                                      );
                                    },
                                  ),
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),

                  // お気に入りのお酒セクション
                  Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.wine_bar,
                                color: Colors.amber,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'お気に入りのお酒',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                        ),
                        if (myFavoriteSakeList.isEmpty)
                          Container(
                            width: MediaQuery.of(context).size.width,
                            padding: const EdgeInsets.only(bottom: 24),
                            child: const Center(
                              child: Text(
                                'まだお気に入りはありません。\n日本酒を検索して♡マークを押してみましょう！',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        if (myFavoriteSakeList.isNotEmpty)
                          Container(
                            constraints: const BoxConstraints(maxHeight: 300),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const ClampingScrollPhysics(),
                              itemCount: myFavoriteSakeList.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      myFavoriteSakeList[index].name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.favorite,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed: () {
                                        final target =
                                            myFavoriteSakeList[index];
                                        favNotifier.addOrRemoveFavorite(target);
                                        _showToast(
                                          context,
                                          message:
                                              '${target.name} をお気に入りから削除しました',
                                          icon: Icons.favorite_border,
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        SizedBox(
                          height: 24,
                        ),
                      ],
                    ),
                  ),

                  // お酒診断ボタン
                  Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // お気に入りの日本酒が2つ以上あるか確認
                        if (myFavoriteSakeList.length >= 2) {
                          // 2つ以上ある場合は診断を実行
                          _showSakePreferenceAnalysisDialog(context, notifier);
                          notifier.analyzeSakePreference(myFavoriteSakeList);
                        } else {
                          // 2つ未満の場合はトーストメッセージのみ表示
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('もう少しお気に入りのお酒を登録してね！'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.psychology),
                      label: const Text('あなたにぴったりのお酒診断'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  // 好きなお酒の傾向入力フォーム
                  Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.wine_bar,
                              color: Colors.amber,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              '好きなお酒の傾向',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '好みのお酒の特徴を入力すると、おすすめの日本酒を探しやすくなります。',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: preferencesController,
                          maxLength: 200,
                          maxLines: 3,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: '例: 甘口でフルーティな香りが好きです。辛すぎるのは苦手です。',
                            hintStyle:
                                TextStyle(color: Colors.white.withOpacity(0.5)),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            counterStyle:
                                const TextStyle(color: Colors.white70),
                          ),
                          // onChangedは不要になりました（コントローラーのリスナーで処理）
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              // キーボードを閉じる
                              FocusScope.of(context).unfocus();
                              // 保存処理
                              notifier.savePreferences();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('好みを保存しました'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1D3567),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('保存する'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 設定メニューを表示するメソッド
  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '設定',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D3567),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading:
                    const Icon(Icons.description, color: Color(0xFF1D3567)),
                title: const Text('利用規約'),
                onTap: () async {
                  Navigator.pop(context); // 設定メニューを閉じる
                  await Navigator.of(context, rootNavigator: true).push<void>(
                    CupertinoPageRoute(builder: (_) => const HowToUse()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.business, color: Color(0xFF1D3567)),
                title: const Text('開発会社'),
                onTap: () async {
                  Navigator.pop(context); // 設定メニューを閉じる
                  await launchUrl(Uri.parse('https://molasoft.jp'));
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // 設定メニューを閉じる
                },
                child: const Text(
                  'キャンセル',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // お酒診断結果ダイアログを表示するメソッド
  void _showSakePreferenceAnalysisDialog(
      BuildContext context, MyPageNotifier notifier) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isLoading =
                context.select((MyPageState state) => state.isLoading);
            final sakePreferenceAnalysis = context
                .select((MyPageState state) => state.sakePreferenceAnalysis);

            return AlertDialog(
              title: const Text(
                'あなたにぴったりのお酒診断',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D3567),
                ),
              ),
              content: Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : sakePreferenceAnalysis != null
                          ? Text(
                              sakePreferenceAnalysis,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            )
                          : const Text(
                              'お気に入りのお酒から診断できませんでした。別のお酒を登録してみてください。',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // ダイアログを閉じる
                  },
                  child: const Text(
                    '閉じる',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (sakePreferenceAnalysis != null && !isLoading)
                  ElevatedButton(
                    onPressed: () {
                      notifier.saveSakePreferenceAsPreferences();
                      Navigator.pop(context); // ダイアログを閉じる
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('好みを保存しました'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D3567),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('好きな傾向に保存して閉じる'),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SavedSakeList extends StatelessWidget {
  const _SavedSakeList({
    required this.savedSakeList,
    required this.onTap,
    required this.onRemove,
  });

  final List<Sake> savedSakeList;
  final ValueChanged<Sake> onTap;
  final ValueChanged<Sake> onRemove;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: savedSakeList.length,
      itemBuilder: (context, index) {
        final sake = savedSakeList[index];
        final hasPlace = sake.place != null && sake.place!.trim().isNotEmpty;
        final isRecommended = (sake.recommendationScore ?? 0) >= 7;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            onTap: () => onTap(sake),
            title: Text(
              sake.name ?? '名称不明',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (sake.type != null)
                  Text(
                    sake.type!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                if (sake.brewery != null)
                  Text(
                    sake.brewery!,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                if (isRecommended)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.redAccent.withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.recommend,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (sake.recommendationScore ?? 0) >= 8
                              ? '超おすすめ！'
                              : 'おすすめ！',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (hasPlace)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '飲んだ場所: ${sake.place}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if ((sake.userTags ?? []).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: sake.userTags!
                          .map(
                            (tag) => Chip(
                              label: Text(tag),
                              backgroundColor: Colors.white.withOpacity(0.18),
                              labelStyle: const TextStyle(
                                color: Color(0xFF1D3567),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                    ),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.bookmark_remove,
                color: Colors.amber,
              ),
              onPressed: () => onRemove(sake),
            ),
          ),
        );
      },
    );
  }
}

class _SavedSakeGrid extends StatelessWidget {
  const _SavedSakeGrid({
    required this.savedSakeList,
    required this.onTap,
    required this.onRemove,
  });

  final List<Sake> savedSakeList;
  final ValueChanged<Sake> onTap;
  final ValueChanged<Sake> onRemove;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: savedSakeList.length,
      itemBuilder: (context, index) {
        final sake = savedSakeList[index];
        final imagePath = (sake.imagePaths?.isNotEmpty ?? false)
            ? sake.imagePaths!.first
            : null;
        Widget preview = Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.image_not_supported,
            color: Colors.white38,
            size: 36,
          ),
        );

        if (imagePath != null) {
          final file = File(imagePath);
          if (file.existsSync()) {
            preview = ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                file,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
                cacheWidth: 600,
              ),
            );
          }
        }

        final hasPlace = sake.place != null && sake.place!.trim().isNotEmpty;
        final isRecommended = (sake.recommendationScore ?? 0) >= 7;

        return GestureDetector(
          onTap: () => onTap(sake),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(child: preview),
                      if (isRecommended)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'おすすめ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    sake.name ?? '名称不明',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (hasPlace)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      sake.place!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ),
                if ((sake.userTags ?? []).isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: sake.userTags!
                          .take(3)
                          .map(
                            (tag) => Chip(
                              label: Text(tag),
                              backgroundColor: Colors.white.withOpacity(0.18),
                              labelStyle: const TextStyle(
                                color: Color(0xFF1D3567),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(
                      Icons.bookmark_remove,
                      color: Colors.amber,
                      size: 20,
                    ),
                    onPressed: () => onRemove(sake),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
