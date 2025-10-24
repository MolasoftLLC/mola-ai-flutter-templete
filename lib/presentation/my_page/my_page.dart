import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:in_app_review/in_app_review.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/notifier/favorite/favorite_notifier.dart';
import '../../domain/notifier/auth/auth_notifier.dart';
import '../../domain/notifier/my_page/my_page_notifier.dart';
import '../../domain/notifier/saved_sake/saved_sake_notifier.dart';
import '../common/help/help_guide_dialog.dart';
import '../auth/email_link_auth_page.dart';
import '../sake_bottle/sake_bottle_list_page.dart';
import 'account_settings_page.dart';
import 'saved_sake_detail_page.dart';
import 'how_to_use/how_to_use_page.dart';

bool _isRemoteImagePath(String path) =>
    path.startsWith('http://') || path.startsWith('https://');

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

  // Future<void> _promptAppReview(BuildContext context) async {
  //   const appStoreUrl = 'https://apps.apple.com/jp/app/sakepedia/id6502377200';
  //   // final inAppReview = InAppReview.instance;
  //
  //   try {
  //     if (await inAppReview.isAvailable()) {
  //       await inAppReview.requestReview();
  //       return;
  //     }
  //   } catch (_) {
  //     // In-app review not available; fall back to Store link.
  //   }
  //
  //   final uri = Uri.parse(appStoreUrl);
  //   final launched = await launchUrl(
  //     uri,
  //     mode: LaunchMode.externalApplication,
  //   );
  //
  //   if (!launched) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('App Storeを開けませんでした。後ほどお試しください。'),
  //         behavior: SnackBarBehavior.floating,
  //       ),
  //     );
  //   }
  // }

  bool _isValidText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<MyPageNotifier>();
    final authNotifier = context.read<AuthNotifier>();
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
    final activeFilterTags =
        context.select((SavedSakeState state) => state.activeFilterTags);
    final allFilterTags = savedSakeList
        .expand((sake) => sake.userTags ?? const <String>[])
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final activeFilterTagSet = activeFilterTags.toSet();
    final filteredSakeList = activeFilterTagSet.isEmpty
        ? savedSakeList
        : savedSakeList
            .where(
              (sake) => (sake.userTags ?? const <String>[])
                  .map((tag) => tag.trim())
                  .any(activeFilterTagSet.contains),
            )
            .toList();
    final isFiltering = activeFilterTags.isNotEmpty;
    final preferences =
        context.select((MyPageState state) => state.preferences);
    final userName = context.select((MyPageState state) => state.userName);
    final authUser = context.select((AuthState state) => state.user);

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
          centerTitle: true,
          title: const Text(
            'マイページ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              tooltip: '使い方ガイド',
              icon: const Icon(
                Icons.help_outline,
                color: Color(0xFFFFD54F),
              ),
              onPressed: () {
                HelpGuideDialog.showForType(
                  context,
                  type: HelpGuideType.myPage,
                );
              },
            ),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    child: _AuthCard(
                      user: authUser,
                      userName: userName,
                      onAuthenticate: () {
                        authNotifier.clearMessages();
                        FocusScope.of(context).unfocus();
                        final navigator = Navigator.of(context);
                        navigator
                            .push<bool>(
                          MaterialPageRoute(
                            builder: (_) => const EmailLinkAuthPage(),
                          ),
                        )
                            .then((result) {
                          FocusScope.of(navigator.context).unfocus();
                          if (!navigator.mounted) {
                            return;
                          }
                          if (result == true) {
                            _showToast(
                              navigator.context,
                              message: 'ログインしました。',
                              icon: Icons.login,
                            );
                            notifier.fetchUserProfile();
                          }
                        });
                      },
                      onOpenAccountSettings: () {
                        authNotifier.clearMessages();
                        final navigator = Navigator.of(context);
                        FocusScope.of(context).unfocus();
                        navigator
                            .push<AccountSettingsResult?>(
                          MaterialPageRoute(
                            builder: (_) => const AccountSettingsPage(),
                          ),
                        )
                            .then((result) {
                          FocusScope.of(navigator.context).unfocus();
                          if (!navigator.mounted || result == null) {
                            return;
                          }
                          if (result == AccountSettingsResult.loggedOut) {
                            _showToast(
                              navigator.context,
                              message: 'ログアウトしました。',
                              icon: Icons.logout,
                            );
                          } else if (result ==
                              AccountSettingsResult.accountDeleted) {
                            _showToast(
                              navigator.context,
                              message: 'アカウントを削除しました。',
                              icon: Icons.delete_forever,
                            );
                          } else if (result ==
                              AccountSettingsResult.usernameUpdated) {
                            _showToast(
                              navigator.context,
                              message: 'ニックネームを更新しました。',
                              icon: Icons.person,
                            );
                            notifier.fetchUserProfile();
                          }
                        });
                      },
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
                                '保存酒',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: allFilterTags.isEmpty
                                    ? null
                                    : () {
                                        _showTagFilterSheet(
                                          context,
                                          notifier: savedNotifier,
                                          allTags: allFilterTags,
                                          selectedTags: activeFilterTags,
                                        );
                                      },
                                icon: Icon(
                                  Icons.tune,
                                  color: isFiltering
                                      ? Colors.amber
                                      : (allFilterTags.isEmpty
                                          ? Colors.white30
                                          : Colors.white),
                                ),
                                label: Text(
                                  '並び替え',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isFiltering
                                        ? Colors.amber
                                        : (allFilterTags.isEmpty
                                            ? Colors.white30
                                            : Colors.white),
                                    fontWeight: isFiltering
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  foregroundColor:
                                      isFiltering ? Colors.amber : Colors.white,
                                  disabledForegroundColor: Colors.white30,
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
                            child: filteredSakeList.isEmpty
                                ? _SavedSakeFilterEmptyView(
                                    onClear: savedNotifier.clearFilterTags,
                                  )
                                : isGridView
                                    ? _SavedSakeGrid(
                                        savedSakeList: filteredSakeList,
                                        onTap: (sake) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  SavedSakeDetailPage(
                                                      sake: sake),
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
                                        savedSakeList: filteredSakeList,
                                        onTap: (sake) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  SavedSakeDetailPage(
                                                      sake: sake),
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

                  // 酒瓶リストセクション（保存酒の下）
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
                                      onPressed: () async {
                                        final target =
                                            myFavoriteSakeList[index];
                                        await favNotifier
                                            .addOrRemoveFavorite(target);
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

                  // レビュー誘導セクション（ページ末尾）
                  // Container(
                  //   width: MediaQuery.of(context).size.width,
                  //   margin:
                  //       const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  //   padding: const EdgeInsets.all(16),
                  //   decoration: BoxDecoration(
                  //     color: Colors.white.withOpacity(0.12),
                  //     borderRadius: BorderRadius.circular(16),
                  //   ),
                  //   child: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       Row(
                  //         children: const [
                  //           Icon(
                  //             Icons.star_rounded,
                  //             color: Colors.amber,
                  //             size: 26,
                  //           ),
                  //           SizedBox(width: 12),
                  //           Expanded(
                  //             child: Text(
                  //               'レビューで応援してね',
                  //               style: TextStyle(
                  //                 color: Colors.white,
                  //                 fontSize: 18,
                  //                 fontWeight: FontWeight.bold,
                  //               ),
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //       const SizedBox(height: 8),
                  //       const Text(
                  //         'SakePediaの使い心地はいかがですか？App Storeでレビューをいただけると、今後の改善の励みになります。',
                  //         style: TextStyle(
                  //           color: Colors.white70,
                  //           fontSize: 14,
                  //           height: 1.4,
                  //         ),
                  //       ),
                  //       const SizedBox(height: 12),
                  //       Align(
                  //         alignment: Alignment.centerRight,
                  //         child: FilledButton.icon(
                  //           style: FilledButton.styleFrom(
                  //             backgroundColor: const Color(0xFFFFD54F),
                  //             foregroundColor: const Color(0xFF1D3567),
                  //             padding: const EdgeInsets.symmetric(
                  //               horizontal: 20,
                  //               vertical: 12,
                  //             ),
                  //             shape: RoundedRectangleBorder(
                  //               borderRadius: BorderRadius.circular(24),
                  //             ),
                  //           ),
                  //           onPressed: () => _promptAppReview(context),
                  //           icon: const Icon(Icons.open_in_new, size: 18),
                  //           label: const Text(
                  //             'レビューを書く',
                  //             style: TextStyle(fontWeight: FontWeight.bold),
                  //           ),
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTagFilterSheet(
    BuildContext context, {
    required SavedSakeNotifier notifier,
    required List<String> allTags,
    required List<String> selectedTags,
  }) {
    final sortedTags = List<String>.from(allTags)..sort();
    final tempSelected = List<String>.from(selectedTags);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final hasTags = sortedTags.isNotEmpty;
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0A1428),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'タグで絞り込む',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (!hasTags)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          '利用可能なタグがまだありません。',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: sortedTags.map((tag) {
                          final isSelected = tempSelected.contains(tag);
                          return FilterChip(
                            label: Text(
                              tag,
                              style: const TextStyle(
                                color: Color(0xFF0A1428),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (value) {
                              setState(() {
                                if (value) {
                                  tempSelected.add(tag);
                                } else {
                                  tempSelected.remove(tag);
                                }
                              });
                            },
                            backgroundColor: Colors.white.withOpacity(0.18),
                            selectedColor: Colors.amber,
                            checkmarkColor: const Color(0xFF0A1428),
                            shape: StadiumBorder(
                              side: BorderSide(
                                color:
                                    isSelected ? Colors.amber : Colors.white24,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        TextButton(
                          onPressed:
                              selectedTags.isEmpty && tempSelected.isEmpty
                                  ? null
                                  : () {
                                      notifier.clearFilterTags();
                                      Navigator.of(context).pop();
                                    },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white70,
                          ),
                          child: const Text('絞り込みを解除'),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: hasTags
                              ? () {
                                  notifier.setFilterTags(tempSelected);
                                  Navigator.of(context).pop();
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: const Color(0xFF0A1428),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('適用する'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.user,
    required this.userName,
    required this.onAuthenticate,
    required this.onOpenAccountSettings,
  });

  final User? user;
  final String? userName;
  final VoidCallback onAuthenticate;
  final VoidCallback onOpenAccountSettings;

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.white.withOpacity(0.1);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child:
          user == null ? _buildGuestView(context) : _buildSignedInView(context),
    );
  }

  Widget _buildGuestView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.mail_outline, color: Color(0xFFFFD54F)),
            SizedBox(width: 8),
            Text(
              'ログインでさらに便利に',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          '登録なしでも利用できますが、ログインすると保存数UP、保存酒リストのバックアップや端末間での同期が可能になります！',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onAuthenticate,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD54F),
              foregroundColor: const Color(0xFF1D3567),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'メールアドレスでログイン・登録',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignedInView(BuildContext context) {
    final resolvedName = () {
      if (userName != null && userName!.trim().isNotEmpty) {
        return userName!.trim();
      }
      final displayName = user?.displayName;
      if (displayName != null && displayName.trim().isNotEmpty) {
        return displayName.trim();
      }
      final email = user?.email;
      if (email != null && email.isNotEmpty) {
        return email;
      }
      return 'ユーザー';
    }();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.verified_user, color: Color(0xFFFFD54F)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ログイン中',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'こんにちは${resolvedName}さん！',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onOpenAccountSettings,
          tooltip: 'アカウント設定',
          icon: const Icon(
            size: 28,
            Icons.manage_accounts,
            color: Colors.white70,
          ),
        ),
      ],
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
        final isLocalOnly = sake.syncStatus == SavedSakeSyncStatus.localOnly;
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
                if (isLocalOnly)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '未同期',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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

class _SavedSakeFilterEmptyView extends StatelessWidget {
  const _SavedSakeFilterEmptyView({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.search_off,
            color: Colors.white54,
            size: 36,
          ),
          const SizedBox(height: 12),
          const Text(
            '選択中のタグに該当するお酒がありません。',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onClear,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.amber,
              side: const BorderSide(color: Colors.amber),
            ),
            child: const Text('絞り込みを解除'),
          ),
        ],
      ),
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
        crossAxisSpacing: 0,
        mainAxisSpacing: 0,
        childAspectRatio: 0.85,
      ),
      itemCount: savedSakeList.length,
      itemBuilder: (context, index) {
        final sake = savedSakeList[index];
        final imagePath = (sake.imagePaths?.isNotEmpty ?? false)
            ? sake.imagePaths!.first
            : null;
        final isLocalOnly = sake.syncStatus == SavedSakeSyncStatus.localOnly;
        Widget preview = Container(
          color: Colors.white.withOpacity(0.1),
          alignment: Alignment.center,
          child: const Icon(
            Icons.image_not_supported,
            color: Colors.white38,
            size: 36,
          ),
        );

        if (imagePath != null) {
          if (_isRemoteImagePath(imagePath)) {
            preview = Image.network(
              imagePath,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              },
              errorBuilder: (context, _, __) => Container(
                color: Colors.white10,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.broken_image,
                  color: Colors.white38,
                  size: 36,
                ),
              ),
            );
          } else {
            final file = File(imagePath);
            if (file.existsSync()) {
              preview = Image.file(
                file,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
                cacheWidth: 600,
              );
            }
          }
        }

        final hasPlace = sake.place != null && sake.place!.trim().isNotEmpty;
        final isRecommended = (sake.recommendationScore ?? 0) >= 7;

        return GestureDetector(
          onTap: () => onTap(sake),
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
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => onRemove(sake),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bookmark_remove,
                      color: Colors.amber,
                      size: 20,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.0),
                        Colors.black.withOpacity(0.65),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLocalOnly)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '未同期',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Text(
                        sake.name ?? '名称不明',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (hasPlace)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            sake.place!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      if ((sake.userTags ?? []).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: sake.userTags!
                                .take(3)
                                .map(
                                  (tag) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.45),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      tag,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
