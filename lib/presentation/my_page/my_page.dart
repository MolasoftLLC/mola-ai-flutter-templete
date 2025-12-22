import 'dart:io';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:in_app_review/in_app_review.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/notifier/favorite/favorite_notifier.dart';
import '../../domain/notifier/auth/auth_notifier.dart';
import '../../domain/notifier/my_page/my_page_notifier.dart';
import '../../domain/notifier/saved_sake/saved_sake_notifier.dart';
import '../../domain/eintities/preferences/taste_preference_profile.dart';
import '../../common/assets.dart';
import '../common/help/help_guide_dialog.dart';
import '../common/widgets/primary_app_bar.dart';
import '../auth/email_link_auth_page.dart';
import '../sake_bottle/sake_bottle_list_page.dart';
import '../timeline/timeline_page.dart';
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
    final userIconUrl =
        context.select((MyPageState state) => state.userIconUrl);
    final authUser = context.select((AuthState state) => state.user);
    final isLoggedIn = authUser != null;
    final achievementCounts =
        context.select((MyPageState state) => state.achievementCounts);
    final loginCount = achievementCounts['login'] ?? 0;
    final analyzedBottleCount = achievementCounts['analyzedBottle'] ?? 0;
    final menuAnalysisCount = achievementCounts['menuAnalysis'] ?? 0;
    final envyPointCount = achievementCounts['envyPoint'] ?? 0;

    // Notifierから取得したTextEditingControllerを使用
    final preferencesController = notifier.preferencesController;

    void openLogin() {
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
    }

    Future<void> handleRefresh() async {
      await Future.wait([
        notifier.refreshPreferencesFromServer(),
        notifier.fetchUserProfile(),
        notifier.refreshTasteProfile(),
        notifier.loadAchievementStats(),
        savedNotifier.refreshFromServer(),
        favNotifier.refreshFromServer(),
      ]);
    }

    return GestureDetector(
      // キーボード外タップでキーボードを閉じる
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: PrimaryAppBar(
          title: 'マイページ',
          automaticallyImplyLeading: false,
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
          child: RefreshIndicator(
            color: Colors.white,
            backgroundColor: const Color(0xFF1D3567),
            onRefresh: handleRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                        userIconUrl: userIconUrl,
                        envyPointCount: envyPointCount,
                        onAuthenticate: openLogin,
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
                    if (isLoggedIn)
                      _AchievementsCard(
                        loginCount: loginCount,
                        analyzedBottleCount: analyzedBottleCount,
                        menuAnalysisCount: menuAnalysisCount,
                        envyPointCount: envyPointCount,
                      ),
                    // 保存したお酒セクション
                    Container(
                      width: MediaQuery.of(context).size.width,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
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
                                    foregroundColor: isFiltering
                                        ? Colors.amber
                                        : Colors.white,
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

                    const SizedBox(height: 16),
                    _MyTimelineEntryTile(
                      isLoggedIn: isLoggedIn,
                      onLoginRequested: openLogin,
                    ),
                    const SizedBox(height: 8),

                    // 酒瓶リストセクション（保存酒の下）
                    Container(
                      width: MediaQuery.of(context).size.width,
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SakeBottleListPage.wrapped(),
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
                            if (!notifier.hasAnalysisQuota) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('診断は1日に3回までです。時間をおいてお試しください。'),
                                  duration: Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            // 2つ以上ある場合は診断を実行
                            _showSakePreferenceAnalysisDialog(
                                context, notifier);
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
                        label: const Text(
                          'あなたにぴったりのお酒診断',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
                          if (isLoggedIn)
                            _buildPreferenceChartPreview(
                              context.select(
                                (MyPageState state) => state.tasteProfile,
                              ),
                            )
                          else
                            _buildPreferenceChartLoginPrompt(openLogin),
                          const SizedBox(height: 16),
                          TextField(
                            controller: preferencesController,
                            maxLength: 200,
                            maxLines: 3,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: '例: 甘口でフルーティな香りが好きです。辛すぎるのは苦手です。',
                              hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.5)),
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
      ),
    );
  }

  Widget _buildPreferenceChartPreview(TastePreferenceProfile? profile) {
    final effectiveProfile = profile ?? TastePreferenceProfile.sample();
    final axes = <_PreferenceAxisData>[
      _PreferenceAxisData(
        title: 'フルーティ',
        leftLabel: '穏やか',
        rightLabel: 'フルーティ',
        value: effectiveProfile.fruity,
      ),
      _PreferenceAxisData(
        title: '甘味',
        leftLabel: '辛口',
        rightLabel: '甘口',
        value: effectiveProfile.sweetness,
      ),
      _PreferenceAxisData(
        title: '酸味',
        leftLabel: '低酸',
        rightLabel: '高酸',
        value: effectiveProfile.acidity,
      ),
      _PreferenceAxisData(
        title: '旨味',
        leftLabel: '淡麗',
        rightLabel: '濃醇',
        value: effectiveProfile.umami,
      ),
      _PreferenceAxisData(
        title: 'キレ',
        leftLabel: 'まろやか',
        rightLabel: 'シャープ',
        value: effectiveProfile.kire,
      ),
      _PreferenceAxisData(
        title: '辛さ',
        leftLabel: '穏やか',
        rightLabel: 'ピリッ',
        value: effectiveProfile.spiciness,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profile == null ? '好きなお酒の傾向（サンプル表示）' : '好きなお酒の傾向',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profile == null
                ? 'お気に入りデータがそろったら、あなた専用のチャートをここに表示します。'
                : 'お気に入りの日本酒から算出した平均傾向です。あくまでAIの解析なのでお手柔らかに。',
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: _PreferenceRadarChart(axes: axes),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceChartLoginPrompt(VoidCallback onAuthenticate) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ログインユーザー限定',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'お気に入りの日本酒から傾向チャートを自動生成します。ログインして自分専用の分析を確認しましょう。',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAuthenticate,
              icon: const Icon(Icons.login),
              label: const Text(
                'ログインしてチャートを見る',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD54F),
                foregroundColor: const Color(0xFF1D3567),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
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
            final tasteProfile =
                context.select((MyPageState state) => state.tasteProfile);

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
                          : tasteProfile != null
                              ? const Text(
                                  '味覚チャートを更新しました！\nお気に入りを増やすとさらに精度が上がります。',
                                  style: TextStyle(
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

class _PreferenceRadarChart extends StatefulWidget {
  const _PreferenceRadarChart({required this.axes});

  final List<_PreferenceAxisData> axes;

  @override
  State<_PreferenceRadarChart> createState() => _PreferenceRadarChartState();
}

class _PreferenceRadarChartState extends State<_PreferenceRadarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  final UniqueKey _visibilityKey = UniqueKey();
  bool _hasAnimated = false;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, 280.0);
        final chartRadius = size / 2 * 0.72;
        final labelRadius = chartRadius + 30;
        final labelWidth = 68.0;

        return VisibilityDetector(
          key: _visibilityKey,
          onVisibilityChanged: (info) {
            _isVisible = info.visibleFraction > 0.35;
            if (!_hasAnimated && _isVisible) {
              _hasAnimated = true;
              _controller.forward();
            }
          },
          child: SizedBox(
            width: size,
            height: size + 40,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: Size(size, size),
                      painter: _PreferenceRadarPainter(
                        axes: widget.axes,
                        chartRadius: chartRadius,
                        progress: _animation.value,
                      ),
                    ),
                    for (var i = 0; i < widget.axes.length; i++)
                      _buildAxisLabel(
                        widget.axes[i].title,
                        size,
                        labelRadius,
                        labelWidth,
                        i,
                        widget.axes.length,
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  void didUpdateWidget(covariant _PreferenceRadarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_listEqualsAxis(oldWidget.axes, widget.axes)) {
      _hasAnimated = false;
      _controller.reset();
      if (_isVisible) {
        _hasAnimated = true;
        _controller.forward();
      }
    }
  }

  bool _listEqualsAxis(
    List<_PreferenceAxisData> a,
    List<_PreferenceAxisData> b,
  ) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final left = a[i];
      final right = b[i];
      if (left.title != right.title ||
          (left.value - right.value).abs() > 0.0001) {
        return false;
      }
    }
    return true;
  }

  Widget _buildAxisLabel(
    String title,
    double size,
    double radius,
    double labelWidth,
    int index,
    int total,
  ) {
    final angle = -math.pi / 2 + (2 * math.pi * index) / total;
    final dx = math.cos(angle) * radius;
    final dy = math.sin(angle) * radius;

    final proposedLeft = size / 2 + dx - labelWidth / 2;
    final proposedTop = size / 2 + dy - 12;
    final safeLeft = (proposedLeft.clamp(0.0, size - labelWidth)) as double;
    final safeTop = (proposedTop.clamp(0.0, size - 30)) as double;

    return Positioned(
      left: safeLeft,
      top: safeTop,
      width: labelWidth,
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PreferenceRadarPainter extends CustomPainter {
  _PreferenceRadarPainter({
    required this.axes,
    required this.chartRadius,
    required this.progress,
  });

  final List<_PreferenceAxisData> axes;
  final double chartRadius;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final angleStep = (2 * math.pi) / axes.length;
    const levelCount = 4;

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final axisPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final fillPaint = Paint()
      ..color = const Color(0xFFFFD54F).withOpacity(0.32)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var level = 1; level <= levelCount; level++) {
      final factor = level / levelCount;
      final path = Path();
      for (var i = 0; i < axes.length; i++) {
        final angle = -math.pi / 2 + angleStep * i;
        final dx = center.dx + math.cos(angle) * chartRadius * factor;
        final dy = center.dy + math.sin(angle) * chartRadius * factor;
        if (i == 0) {
          path.moveTo(dx, dy);
        } else {
          path.lineTo(dx, dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    for (var i = 0; i < axes.length; i++) {
      final angle = -math.pi / 2 + angleStep * i;
      final dx = center.dx + math.cos(angle) * chartRadius;
      final dy = center.dy + math.sin(angle) * chartRadius;
      canvas.drawLine(center, Offset(dx, dy), axisPaint);
    }

    final animationValue = progress.clamp(0.0, 1.0).toDouble();

    final radarPath = Path();
    for (var i = 0; i < axes.length; i++) {
      final angle = -math.pi / 2 + angleStep * i;
      final baseValue = axes[i].value.clamp(0.0, 1.0);
      final value = baseValue * animationValue;
      final dx = center.dx + math.cos(angle) * chartRadius * value;
      final dy = center.dy + math.sin(angle) * chartRadius * value;
      if (i == 0) {
        radarPath.moveTo(dx, dy);
      } else {
        radarPath.lineTo(dx, dy);
      }
    }
    radarPath.close();

    canvas.drawPath(radarPath, fillPaint);
    canvas.drawPath(radarPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PreferenceAxisData {
  final String title;
  final String leftLabel;
  final String rightLabel;
  final double value;

  const _PreferenceAxisData({
    required this.title,
    required this.leftLabel,
    required this.rightLabel,
    required this.value,
  });
}

class _AchievementData {
  const _AchievementData({
    required this.id,
    required this.title,
    required this.description,
    required this.current,
    required this.target,
    required this.asset,
    required this.tier,
    required this.hasProgress,
  });

  final String id;
  final String title;
  final String description;
  final int current;
  final int target;
  final AssetImage asset;
  final _MedalTier tier;
  final bool hasProgress;

  double get progress =>
      target <= 0 ? 0 : (current / target).clamp(0, 1).toDouble();
  int get remaining => (target - current).clamp(0, 999);
  bool get isComplete => tier == _MedalTier.gold && current >= target;
}

class _AchievementDefinition {
  const _AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.asset,
    required this.thresholds,
  });

  final String id;
  final String title;
  final String description;
  final AssetImage asset;
  final List<int> thresholds;
}

const List<_AchievementDefinition> _achievementDefinitions = [
  _AchievementDefinition(
    id: 'login',
    title: 'ウェルカム乾杯',
    description: 'たくさん利用してバッジを集めましょう',
    asset: Assets.sakeLogoColor,
    thresholds: [1, 3, 7],
  ),
  _AchievementDefinition(
    id: 'analyzedBottle',
    title: 'ボトルマスター',
    description: '酒瓶解析で日本酒の知識を深めよう',
    asset: Assets.medalBin,
    thresholds: [1, 5, 15],
  ),
  _AchievementDefinition(
    id: 'envyPoint',
    title: 'うらやまコレクター',
    description: 'うらやまを集めて注目の的になろう',
    asset: Assets.medalLike,
    thresholds: [3, 7, 15],
  ),
];

class _AchievementsCard extends StatefulWidget {
  const _AchievementsCard({
    required this.loginCount,
    required this.analyzedBottleCount,
    required this.menuAnalysisCount,
    required this.envyPointCount,
  });

  final int loginCount;
  final int analyzedBottleCount;
  final int menuAnalysisCount;
  final int envyPointCount;

  @override
  State<_AchievementsCard> createState() => _AchievementsCardState();
}

class _AchievementsCardState extends State<_AchievementsCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shine;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _shine = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final achievements = _buildAchievements();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF253766), Color(0xFF0C1428)],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.emoji_events, color: Colors.amberAccent, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'バッジ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...achievements.map(_buildAchievementRow),
            ],
          ),
        ),
      ),
    );
  }

  List<_AchievementData> _buildAchievements() {
    return _achievementDefinitions.map((definition) {
      final current = _countFor(definition.id);
      final thresholds = List<int>.from(definition.thresholds)..sort();
      final hasProgress = current > 0;
      final target = _nextThreshold(current, thresholds);
      final tier = _determineTier(current, thresholds);

      return _AchievementData(
        id: definition.id,
        title: definition.title,
        description: definition.description,
        current: current,
        target: target,
        asset: definition.asset,
        tier: tier,
        hasProgress: hasProgress,
      );
    }).toList();
  }

  int _countFor(String id) {
    switch (id) {
      case 'login':
        return widget.loginCount;
      case 'analyzedBottle':
        return widget.analyzedBottleCount;
      case 'menuAnalysis':
        return widget.menuAnalysisCount;
      case 'envyPoint':
        return widget.envyPointCount;
      default:
        return 0;
    }
  }

  int _nextThreshold(int current, List<int> thresholds) {
    if (thresholds.isEmpty) {
      return current > 0 ? current : 1;
    }
    for (final threshold in thresholds) {
      if (current < threshold) {
        return threshold;
      }
    }
    return thresholds.last;
  }

  _MedalTier _determineTier(int current, List<int> thresholds) {
    if (thresholds.isEmpty) {
      return current > 0 ? _MedalTier.gold : _MedalTier.none;
    }

    final sorted = List<int>.from(thresholds)..sort();

    if (sorted.length == 1) {
      return current >= sorted[0] ? _MedalTier.gold : _MedalTier.none;
    }
    if (sorted.length == 2) {
      if (current >= sorted[1]) {
        return _MedalTier.gold;
      }
      if (current >= sorted[0]) {
        return _MedalTier.bronze;
      }
      return _MedalTier.none;
    }

    if (current >= sorted[2]) {
      return _MedalTier.gold;
    }
    if (current >= sorted[1]) {
      return _MedalTier.silver;
    }
    if (current >= sorted[0]) {
      return _MedalTier.bronze;
    }
    return _MedalTier.none;
  }

  Widget _buildAchievementRow(_AchievementData achievement) {
    final tier = achievement.tier;
    final remaining = achievement.remaining;
    final hasProgress = achievement.hasProgress;
    final displayCurrent = achievement.target <= 0
        ? achievement.current
        : math.min(achievement.current, achievement.target);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  _MedalBadge(
                    animation: _shine,
                    asset: achievement.asset,
                    tier: tier,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _tierLabel(tier),
                    style: TextStyle(
                      color: tier == _MedalTier.none
                          ? Colors.white60
                          : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            achievement.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${displayCurrent}/${achievement.target}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.description,
                      style: TextStyle(
                        color: hasProgress ? Colors.white60 : Colors.white38,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: achievement.progress,
                        backgroundColor: Colors.white.withOpacity(0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _progressColorForTier(tier, achievement.progress),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      achievement.isComplete
                          ? 'コンプリート！バッジを獲得しました'
                          : hasProgress
                              ? 'あと$remaining回で次のバッジ'
                              : 'まずは最初の挑戦から始めてみましょう',
                      style: TextStyle(
                        color: tier == _MedalTier.none
                            ? Colors.white60
                            : Colors.amberAccent,
                        fontSize: 11,
                        fontWeight: tier == _MedalTier.none
                            ? FontWeight.w500
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _progressColorForTier(_MedalTier tier, double progress) {
    switch (tier) {
      case _MedalTier.gold:
        return Color.lerp(
              const Color(0xFFFFA726),
              const Color(0xFFFFD54F),
              progress.clamp(0, 1),
            ) ??
            const Color(0xFFFFD54F);
      case _MedalTier.silver:
        return Color.lerp(
              const Color(0xFF90A4AE),
              const Color(0xFFCFD8DC),
              progress.clamp(0, 1),
            ) ??
            const Color(0xFFCFD8DC);
      case _MedalTier.bronze:
        return Color.lerp(
              const Color(0xFF8D6E63),
              const Color(0xFFBCAAA4),
              progress.clamp(0, 1),
            ) ??
            const Color(0xFFBCAAA4);
      case _MedalTier.none:
        return Colors.white38;
    }
  }

  String _tierLabel(_MedalTier tier) {
    switch (tier) {
      case _MedalTier.gold:
        return 'ゴールドバッジ';
      case _MedalTier.silver:
        return 'シルバーバッジ';
      case _MedalTier.bronze:
        return 'ブロンズバッジ';
      case _MedalTier.none:
        return '未獲得';
    }
  }
}

enum _MedalTier { none, bronze, silver, gold }

class _MedalBadge extends StatelessWidget {
  const _MedalBadge({
    required this.animation,
    required this.asset,
    required this.tier,
  });

  final Animation<double> animation;
  final AssetImage asset;
  final _MedalTier tier;

  List<Color> _gradientForTier() {
    switch (tier) {
      case _MedalTier.gold:
        return const [Color(0xFFFFD54F), Color(0xFFF9A825)];
      case _MedalTier.silver:
        return const [Color(0xFFCFD8DC), Color(0xFF90A4AE)];
      case _MedalTier.bronze:
        return const [Color(0xFFBCAAA4), Color(0xFF8D6E63)];
      case _MedalTier.none:
        return const [Color(0xFF2F3344), Color(0xFF252A38)];
    }
  }

  Color _glowColor() {
    switch (tier) {
      case _MedalTier.gold:
        return Colors.amberAccent;
      case _MedalTier.silver:
        return const Color(0xFFCFD8DC);
      case _MedalTier.bronze:
        return const Color(0xFFBCAAA4);
      case _MedalTier.none:
        return Colors.white24;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final glow =
            tier == _MedalTier.none ? 0.03 : 0.08 + (animation.value * 0.12);
        return Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _glowColor().withOpacity(glow),
                blurRadius: tier == _MedalTier.none ? 8 : 14,
                spreadRadius: tier == _MedalTier.none ? 1 : 3,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _gradientForTier(),
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 1.2,
                  ),
                ),
              ),
              _MedalShimmer(
                animationValue: animation.value,
                tier: tier,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.35),
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Image(
                    image: asset,
                    fit: BoxFit.contain,
                    color: tier == _MedalTier.none ? Colors.white54 : null,
                    colorBlendMode:
                        tier == _MedalTier.none ? BlendMode.srcIn : null,
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

class _MedalShimmer extends StatelessWidget {
  const _MedalShimmer({
    required this.animationValue,
    required this.tier,
    required this.child,
  });

  final double animationValue;
  final _MedalTier tier;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final highlightOpacity = tier == _MedalTier.none ? 0.18 : 0.45;
    final gradient = LinearGradient(
      begin: Alignment(-1.0, -0.35),
      end: Alignment(1.0, 0.35),
      colors: [
        Colors.white.withOpacity(0.0),
        Colors.white.withOpacity(highlightOpacity),
        Colors.white.withOpacity(0.0),
      ],
      stops: const [0.3, 0.5, 0.7],
      transform: _SlidingGradientTransform(slidePercent: animationValue),
    );

    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(bounds),
      blendMode: BlendMode.srcATop,
      child: child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});

  final double slidePercent;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final double translateX = bounds.width * (slidePercent * 2 - 1);
    return Matrix4.identity()
      ..translate(translateX)
      ..rotateZ(math.pi / 10);
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.user,
    required this.userName,
    this.userIconUrl,
    this.envyPointCount = 0,
    required this.onAuthenticate,
    required this.onOpenAccountSettings,
  });

  final User? user;
  final String? userName;
  final String? userIconUrl;
  final int envyPointCount;
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

    const double avatarSize = 48;

    Widget buildPlaceholder() {
      return Container(
        width: avatarSize,
        height: avatarSize,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.person,
          color: Colors.white70,
          size: 24,
        ),
      );
    }

    String? resolvedIcon = userIconUrl?.trim();
    final userProvidedPhoto = user?.photoURL;
    if ((resolvedIcon == null || resolvedIcon.isEmpty) &&
        userProvidedPhoto != null &&
        userProvidedPhoto.trim().isNotEmpty) {
      resolvedIcon = userProvidedPhoto.trim();
    }

    final Widget avatarWidget;
    if (resolvedIcon != null && resolvedIcon.isNotEmpty) {
      avatarWidget = ClipOval(
        child: Image.network(
          resolvedIcon,
          width: avatarSize,
          height: avatarSize,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => buildPlaceholder(),
        ),
      );
    } else {
      avatarWidget = buildPlaceholder();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            avatarWidget,
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
        ),
        const SizedBox(height: 16),
        _EnvyPointHighlight(count: envyPointCount),
      ],
    );
  }
}

class _EnvyPointHighlight extends StatelessWidget {
  const _EnvyPointHighlight({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final bool hasPoints = count > 0;
    final headline = hasPoints ? '累計うらやまポイント' : 'うらやまを集めよう';
    final detail =
        hasPoints ? 'これまでに $count 件のうらやまを獲得しています' : 'タイムラインで共有すると仲間からうらやまが届きます';
    final highlightColor = hasPoints ? Colors.pinkAccent : Colors.white54;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: hasPoints
              ? [
                  const Color(0xFFFF7EB3).withOpacity(0.35),
                  const Color(0xFFFFC371).withOpacity(0.35),
                ]
              : [
                  Colors.white10,
                  Colors.white10,
                ],
        ),
        border: Border.all(
          color:
              hasPoints ? Colors.pinkAccent.withOpacity(0.4) : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: highlightColor.withOpacity(0.18),
            ),
            child: Icon(
              hasPoints ? Icons.favorite : Icons.favorite_border,
              color: highlightColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$count pt',
                style: TextStyle(
                  color: highlightColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                hasPoints ? 'みんなが賞賛！' : '集めてみよう',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
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

class _MyTimelineEntryTile extends StatelessWidget {
  const _MyTimelineEntryTile({
    required this.isLoggedIn,
    required this.onLoginRequested,
  });

  final bool isLoggedIn;
  final VoidCallback onLoginRequested;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (!isLoggedIn) {
              onLoginRequested();
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TimelinePage.myPosts(),
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
              children: const [
                Icon(
                  Icons.person_pin_circle,
                  color: Colors.amber,
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '自分の投稿',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
