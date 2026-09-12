import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mola_gemini_flutter_template/presentation/common/loading/ai_loading.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/assets.dart';
import '../../common/localization/localization_extensions.dart';
import '../../common/utils/snack_bar_utils.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/notifier/auth/auth_notifier.dart';
import '../../domain/notifier/favorite/favorite_notifier.dart';
import '../../domain/notifier/saved_sake/saved_sake_notifier.dart';
import '../../domain/repository/place_map_repository.dart';
import '../common/help/help_guide_dialog.dart';
import '../common/widgets/guest_limit_dialog.dart';
import '../common/widgets/primary_app_bar.dart';
import '../favorite_search/favorite_search_page.dart';
import '../menu_search/menu_search_page.dart';
import '../sake_map/sake_map_page.dart';
import '../sake_map/sake_master_detail_page.dart';
import '../sake_scan/sake_scan_page.dart';
import 'main_search_page_notifier.dart';

class MainSearchPage extends StatelessWidget {
  MainSearchPage._()
    : _masterSakeSearchPanelKey = GlobalKey<_MasterSakeSearchPanelState>();

  static final ScrollController _scrollController = ScrollController();
  static final GlobalKey _resultSectionKey = GlobalKey();
  final GlobalKey<_MasterSakeSearchPanelState> _masterSakeSearchPanelKey;

  static Widget wrapped() {
    return MultiProvider(
      providers: [
        StateNotifierProvider<MainSearchPageNotifier, MainSearchPageState>(
          create: (context) => MainSearchPageNotifier(
            context: context,
            authNotifier: context.read<AuthNotifier>(),
          ),
        ),
      ],
      child: MainSearchPage._(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<MainSearchPageNotifier>();
    final favNotifier = context.watch<FavoriteNotifier>();
    final savedNotifier = context.watch<SavedSakeNotifier>();
    final myFavoriteList = context.select(
      (FavoriteState state) => state.myFavoriteList,
    );
    final savedSakeList = context.select(
      (SavedSakeState state) => state.savedSakeList,
    );
    final isLoading = context.select(
      (MainSearchPageState state) => state.isLoading,
    );
    final isAdLoading = context.select(
      (MainSearchPageState state) => state.isAdLoading,
    );
    final isAnalyzingInBackground = context.select(
      (MainSearchPageState state) => state.isAnalyzingInBackground,
    );
    final sakeInfo = context.select(
      (MainSearchPageState state) => state.sakeInfo,
    );
    final errorMessage = context.select(
      (MainSearchPageState state) => state.errorMessage,
    );
    final manualSearchSuggested = context.select(
      (MainSearchPageState state) => state.manualSearchSuggested,
    );
    final manualSearchQuery = context.select(
      (MainSearchPageState state) => state.manualSearchQuery,
    );
    final sakeImage = context.select(
      (MainSearchPageState state) => state.sakeImage,
    );
    final shareToTimeline = context.select(
      (MainSearchPageState state) => state.shareToTimeline,
    );
    final isLoggedIn = context.select(
      (MainSearchPageState state) => state.isLoggedIn,
    );
    final autoTweetEnabled = context.select(
      (MainSearchPageState state) => state.autoTweetEnabled,
    );
    final isAutoTweetUpdating = context.select(
      (MainSearchPageState state) => state.isAutoTweetUpdating,
    );

    if (sakeInfo != null && !isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToResults();
      });
    }

    final bool showLoadingIndicator = isLoading || isAdLoading;
    final double contentMinHeight =
        MediaQuery.of(context).size.height - kToolbarHeight - 48;
    final Widget loadingContent = SizedBox(
      height: contentMinHeight < 0 ? null : contentMinHeight,
      child: Align(
        alignment: const Alignment(0, -0.35),
        child: isAdLoading
            ? AILoading(loadingText: context.l10n.analyzingWithAd)
            : isAnalyzingInBackground
            ? AILoading(loadingText: context.l10n.loadingSakeInfo)
            : AILoading(loadingText: context.l10n.loadingSakeInfo),
      ),
    );

    return Scaffold(
      appBar: PrimaryAppBar(
        title: context.l10n.searchPageTitle,
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            tooltip: context.l10n.helpGuide,
            icon: const Icon(Icons.help_outline, color: Color(0xFFFFD54F)),
            onPressed: () {
              HelpGuideDialog.showForType(
                context,
                type: HelpGuideType.mainSearch,
              );
            },
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(color: Color(0xFF1D3567)),
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: showLoadingIndicator
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            child: showLoadingIndicator
                ? loadingContent
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _MasterSakeSearchPanel(
                            key: _masterSakeSearchPanelKey,
                          ),
                        ),
                        const SizedBox(height: 16),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _SearchShortcuts(
                            onMapTap: () => _openMap(context),
                            onMenuSearchTap: () => _openMenuSearch(context),
                            onFastSearchTap: () =>
                                _openFastSearch(context, notifier),
                            onPreferenceSearchTap: () =>
                                _openPreferenceSearch(context),
                          ),
                        ),
                        const SizedBox(height: 18),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildBottleSearchUI(
                            context,
                            notifier,
                            sakeImage,
                            isAnalyzingInBackground,
                            shareToTimeline,
                            isLoggedIn,
                            autoTweetEnabled,
                            isAutoTweetUpdating,
                          ),
                        ),
                        const SizedBox(height: 18),

                        if (manualSearchSuggested &&
                            manualSearchQuery != null &&
                            manualSearchQuery.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: _ManualSakeSearchSuggestion(
                              query: manualSearchQuery,
                              onTap: () => _openManualNameSearch(
                                notifier,
                                manualSearchQuery,
                              ),
                            ),
                          ),
                        if (manualSearchSuggested &&
                            manualSearchQuery != null &&
                            manualSearchQuery.trim().isNotEmpty)
                          const SizedBox(height: 18),

                        // 検索結果表示
                        if (sakeInfo != null)
                          Container(
                            key: _resultSectionKey,
                            child: _buildSakeInfoCard(
                              context,
                              notifier,
                              favNotifier,
                              savedNotifier,
                              sakeInfo,
                              myFavoriteList,
                              savedSakeList,
                            ),
                          ),

                        if (errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              localizeLegacyMessage(context.l10n, errorMessage),
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _openManualNameSearch(MainSearchPageNotifier notifier, String query) {
    notifier.dismissManualSearchSuggestion();
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _masterSakeSearchPanelKey.currentState?.searchFor(query);
    });
  }

  Future<void> _openMap(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => SakeMapPage.wrapped()));
  }

  Future<void> _openPreferenceSearch(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => FavoriteSearchPage.wrapped()),
    );
  }

  Future<void> _openMenuSearch(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => MenuSearchPage.wrapped()),
    );
  }

  Future<void> _openFastSearch(
    BuildContext context,
    MainSearchPageNotifier notifier,
  ) async {
    final result = await Navigator.of(context).push<Sake>(
      PageRouteBuilder<Sake>(
        pageBuilder: (_, __, ___) => SakeScanPage.wrapped(),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                  reverseCurve: Curves.easeInCubic,
                ),
              ),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 240),
      ),
    );
    if (result != null && context.mounted) {
      notifier.applySakeScanResult(result);
    }
  }

  // 酒瓶検索UI
  Widget _buildBottleSearchUI(
    BuildContext context,
    MainSearchPageNotifier notifier,
    File? sakeImage,
    bool isAnalyzingInBackground,
    bool shareToTimeline,
    bool isLoggedIn,
    bool? autoTweetEnabled,
    bool isAutoTweetUpdating,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            context.l10n.selectBottleImage,
            style: TextStyle(fontSize: 14, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            width: double.infinity,
            child: sakeImage != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          sakeImage,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: InkWell(
                          onTap: notifier.clearImage,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Color(0xFF1D3567),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : InkWell(
                    onTap: () => notifier.pickImage(ImageSource.gallery),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image(
                            image: Assets.medalBin,
                            width: 48,
                            height: 48,
                            color: const Color(0xFF1D3567),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.l10n.tapToSelectImage,
                            style: TextStyle(
                              color: Color(0xFF1D3567),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          if (sakeImage == null)
            ElevatedButton.icon(
              onPressed: () => notifier.pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: Text(context.l10n.takePhoto),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D3567),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: shareToTimeline,
            onChanged: (value) {
              if (value == null) return;
              notifier.onTimelineShareToggle(value);
            },
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: const Color(0xFF1D3567),
            contentPadding: EdgeInsets.zero,
            title: Text(
              context.l10n.shareToTimeline,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(context.l10n.onlyFirstImageShared),
          ),
          CheckboxListTile(
            value: autoTweetEnabled ?? true,
            onChanged: (value) {
              if (value == null ||
                  autoTweetEnabled == null ||
                  isAutoTweetUpdating) {
                return;
              }
              notifier.onAutoTweetToggle(value);
            },
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: const Color(0xFF1D3567),
            contentPadding: EdgeInsets.zero,
            title: Text(
              context.l10n.autoPostToX,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.l10n.autoPostToXDescription),
                if (!isLoggedIn)
                  Text(
                    context.l10n.loginToChangeSetting,
                    style: TextStyle(fontSize: 12),
                  ),
                if (isLoggedIn && autoTweetEnabled == null)
                  Text(
                    context.l10n.loadingAutoPostSetting,
                    style: TextStyle(fontSize: 12),
                  ),
                if (isAutoTweetUpdating)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              Color(0xFF1D3567),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.l10n.updatingSetting,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: sakeImage != null && !isAnalyzingInBackground
                      ? () async => notifier.saveAndAnalyzeBottle()
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD54F),
                    foregroundColor: const Color(0xFF1D3567),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey.shade400,
                  ),
                  child: Text(
                    context.l10n.analyzeAndSave,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: sakeImage != null && !isAnalyzingInBackground
                      ? () async => notifier.analyzeSakeBottle()
                      : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1D3567),
                    side: BorderSide(
                      color: const Color(0xFF1D3567).withOpacity(0.4),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledForegroundColor: Colors.grey.shade500,
                    disabledBackgroundColor: Colors.transparent,
                  ),
                  child: Text(
                    context.l10n.analyzeOnly,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // 日本酒情報カードを修正
  Widget _buildSakeInfoCard(
    BuildContext context,
    MainSearchPageNotifier notifier,
    FavoriteNotifier favNotifier,
    SavedSakeNotifier savedNotifier,
    Sake sakeInfo,
    List<FavoriteSake> myFavoriteList,
    List<Sake> savedSakeList,
  ) {
    // 日本酒名とタイプが一致するかどうかでお気に入り判定
    final bool isFavorite = myFavoriteList.any(
      (item) => item.name == sakeInfo.name && item.type == sakeInfo.type,
    );

    // おすすめ度の表示を決定
    String recommendationText = '';
    Color recommendationColor = Colors.orange;
    IconData recommendationIcon = Icons.star;

    if (sakeInfo.recommendationScore != null) {
      if (sakeInfo.recommendationScore! >= 8) {
        recommendationText = context.l10n.highlyRecommended;
        recommendationColor = Colors.red;
        recommendationIcon = Icons.star;
      } else if (sakeInfo.recommendationScore! >= 6) {
        recommendationText = context.l10n.recommended;
        recommendationColor = Colors.orange;
        recommendationIcon = Icons.star;
      } else if (sakeInfo.recommendationScore! >= 4) {
        recommendationText = context.l10n.goodSake;
        recommendationColor = Colors.amber;
        recommendationIcon = Icons.star_half;
      }
    }

    final bool isSaved = savedSakeList.any(
      (item) => item.name == sakeInfo.name && item.type == sakeInfo.type,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー部分（日本酒名）
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF0F214A),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    sakeInfo.name ?? context.l10n.unknown,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: isSaved
                      ? context.l10n.removeSavedSake
                      : context.l10n.saveSake,
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_outline,
                    color: isSaved ? Colors.amberAccent : Colors.white,
                  ),
                  onPressed: () async {
                    if (!isSaved && savedNotifier.hasReachedGuestLimit) {
                      await GuestLimitDialog.showSavedSakeLimit(
                        context,
                        maxCount: SavedSakeNotifier.guestSavedLimit,
                      );
                      return;
                    }
                    if (!isSaved && savedNotifier.hasReachedMemberLimit) {
                      SnackBarUtils.showWarningSnackBar(
                        context,
                        message: context.l10n.savedSakeLimit(
                          SavedSakeNotifier.memberSavedLimit,
                        ),
                      );
                      return;
                    }
                    final shouldShowSavedToast = !isSaved;
                    try {
                      await savedNotifier.toggleSavedSake(sakeInfo);
                    } on SavedSakeGuestLimitReachedException {
                      await GuestLimitDialog.showSavedSakeLimit(
                        context,
                        maxCount: SavedSakeNotifier.guestSavedLimit,
                      );
                      return;
                    } on SavedSakeMemberLimitReachedException {
                      SnackBarUtils.showWarningSnackBar(
                        context,
                        message: context.l10n.savedSakeLimit(
                          SavedSakeNotifier.memberSavedLimit,
                        ),
                      );
                      return;
                    }
                    if (shouldShowSavedToast) {
                      SnackBarUtils.showInfoSnackBar(
                        context,
                        message: context.l10n.savedToMyPage,
                      );
                    }
                  },
                ),
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.white,
                  ),
                  onPressed: () async {
                    final favoriteSake = FavoriteSake(
                      name: sakeInfo.name ?? context.l10n.unknown,
                      type: sakeInfo.type,
                    );

                    if (!isFavorite && favNotifier.hasReachedGuestLimit) {
                      await GuestLimitDialog.showFavoriteLimit(
                        context,
                        maxCount: FavoriteNotifier.guestFavoriteLimit,
                      );
                      return;
                    }

                    try {
                      await favNotifier.addOrRemoveFavorite(favoriteSake);
                    } on FavoriteGuestLimitReachedException {
                      await GuestLimitDialog.showFavoriteLimit(
                        context,
                        maxCount: FavoriteNotifier.guestFavoriteLimit,
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          // おすすめ度表示（スコアがある場合のみ）
          if (recommendationText.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: recommendationColor.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    recommendationIcon,
                    color: recommendationColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    recommendationText,
                    style: TextStyle(
                      color: recommendationColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  if (sakeInfo.recommendationScore != null)
                    Text(
                      '${sakeInfo.recommendationScore}/10',
                      style: TextStyle(
                        color: recommendationColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),

          // 日本酒の詳細情報
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 特徴
                if (sakeInfo.taste != null)
                  _buildInfoRow(
                    context,
                    context.l10n.characteristics,
                    sakeInfo.taste!,
                    Icons.description,
                  ),

                // 蔵元情報（特徴の下に移動）
                if (sakeInfo.brewery != null)
                  _buildInfoRow(
                    context,
                    context.l10n.brewery,
                    sakeInfo.brewery!,
                    Icons.business,
                  ),

                // 日本酒度
                if (sakeInfo.sakeMeterValue != null)
                  _buildInfoRow(
                    context,
                    context.l10n.sakeMeterValue,
                    '${sakeInfo.sakeMeterValue! > 0 ? '+' : ''}${sakeInfo.sakeMeterValue}',
                    Icons.scale,
                  ),

                // 甘口/辛口の表示
                if (sakeInfo.sakeMeterValue != null)
                  _buildSakeMeterScale(
                    context,
                    sakeInfo.sakeMeterValue!.toDouble(),
                  ),

                // タイプ別検索（甘口・辛口ゲージの下に移動）
                if (sakeInfo.types != null && sakeInfo.types!.isNotEmpty)
                  _buildTypesRowEnhanced(context, notifier, sakeInfo),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.amberAccent.shade200, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.85),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // タイプ別検索の表示を修正
  Widget _buildTypesRowEnhanced(
    BuildContext context,
    MainSearchPageNotifier notifier,
    Sake sakeInfo,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.search, color: Colors.amberAccent.shade200, size: 20),
              const SizedBox(width: 12),
              Text(
                context.l10n.searchByType,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: sakeInfo.types!.map((type) {
              return InkWell(
                onTap: () {
                  notifier.searchByNameAndType(
                    sakeName: sakeInfo.name ?? '',
                    sakeType: type,
                  );
                },
                child: Chip(
                  label: Text(type),
                  backgroundColor: Colors.white.withOpacity(0.9),
                  labelStyle: const TextStyle(
                    color: Color(0xFF1D3567),
                    fontWeight: FontWeight.bold,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  avatar: const Icon(
                    Icons.search,
                    size: 16,
                    color: Color(0xFF1D3567),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 日本酒度のスケール表示
  Widget _buildSakeMeterScale(BuildContext context, double sakeMeterValue) {
    // 日本酒度の範囲は一般的に-15〜+15程度
    // UIでは-10〜+10の範囲で表示
    final double normalizedValue = sakeMeterValue.clamp(-10.0, 10.0);
    final double percentage = (normalizedValue + 10) / 20; // 0〜1の範囲に正規化

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.sweet,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
              ),
              Text(
                context.l10n.dry,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.pink, Colors.white, Colors.blue],
                stops: [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Stack(
              children: [
                // インジケーター
                Positioned(
                  left:
                      percentage *
                      MediaQuery.of(context).size.width *
                      0.7, // 親の幅の70%を使用
                  child: Container(
                    width: 12,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D3567),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _scrollToResults() {
    final context = _resultSectionKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
        alignment: 0.05,
      );
      return;
    }
    if (_scrollController.hasClients) {
      final double targetPosition =
          _scrollController.position.maxScrollExtent * 0.6;
      _scrollController.animateTo(
        targetPosition,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }
}

class _ManualSakeSearchSuggestion extends StatelessWidget {
  const _ManualSakeSearchSuggestion({required this.query, required this.onTap});

  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFB74D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.manage_search, color: Color(0xFF8A4B00)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.manualSakeSearchTitle,
                  style: const TextStyle(
                    color: Color(0xFF5D3500),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.manualSakeSearchDescription(query),
            style: const TextStyle(color: Color(0xFF5D3500), height: 1.45),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.search),
              label: Text(context.l10n.manualSakeSearchAction(query)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF8A4B00),
                side: const BorderSide(color: Color(0xFFFF9800)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MasterSakeSearchPanel extends StatefulWidget {
  const _MasterSakeSearchPanel({super.key});

  @override
  State<_MasterSakeSearchPanel> createState() => _MasterSakeSearchPanelState();
}

class _MasterSakeSearchPanelState extends State<_MasterSakeSearchPanel> {
  static const _recentSearchesKey = 'master_sake_search_recent_v1';
  static const _recentSearchLimit = 3;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _debounce;
  int _requestId = 0;
  bool _isLoading = false;
  bool _hasSearched = false;
  bool _hasError = false;
  List<SakeMapSearchResult> _results = const [];
  List<SakeMapSearchResult> _recentResults = const [];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    unawaited(_loadRecentSearches());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_recentSearchesKey) ?? const [];
      final recent = stored
          .map(_recentSearchResultFromJson)
          .whereType<SakeMapSearchResult>()
          .take(_recentSearchLimit)
          .toList(growable: false);
      if (mounted) setState(() => _recentResults = recent);
    } catch (_) {
      // 検索履歴が利用できない端末でも検索機能は継続する。
    }
  }

  SakeMapSearchResult? _recentSearchResultFromJson(String source) {
    try {
      final json = jsonDecode(source);
      if (json is! Map<String, dynamic>) return null;
      final name = json['name'] as String?;
      if (name == null || name.trim().isEmpty) return null;
      return SakeMapSearchResult(
        sakeId: (json['sakeId'] as num?)?.toInt(),
        searchToken: json['searchToken'] as String?,
        name: name,
        brewery: json['brewery'] as String?,
        type: json['type'] as String?,
        primaryImageUrl: json['primaryImageUrl'] as String?,
        thumbnailImageUrl: json['thumbnailImageUrl'] as String?,
        isMaster: true,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveRecentSearch(SakeMapSearchResult sake) async {
    final next = [
      sake,
      ..._recentResults.where(
        (recent) => recent.sakeId != sake.sakeId && recent.name != sake.name,
      ),
    ].take(_recentSearchLimit).toList(growable: false);
    setState(() => _recentResults = next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _recentSearchesKey,
        next
            .map(
              (item) => jsonEncode({
                'sakeId': item.sakeId,
                'searchToken': item.searchToken,
                'name': item.name,
                'brewery': item.brewery,
                'type': item.type,
                'primaryImageUrl': item.primaryImageUrl,
                'thumbnailImageUrl': item.thumbnailImageUrl,
              }),
            )
            .toList(growable: false),
      );
    } catch (_) {
      // 保存できない場合も、今回の画面では候補を表示する。
    }
  }

  void searchFor(String query) {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) return;
    _controller.value = TextEditingValue(
      text: normalizedQuery,
      selection: TextSelection.collapsed(offset: normalizedQuery.length),
    );
    _focusNode.requestFocus();
    _onChanged(normalizedQuery);
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      _requestId++;
      setState(() {
        _isLoading = false;
        _hasSearched = false;
        _hasError = false;
        _results = const [];
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), _search);
  }

  Future<void> _search() async {
    _debounce?.cancel();
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      _hasSearched = false;
      _hasError = false;
    });
    try {
      final results = await context
          .read<PlaceMapRepository>()
          .searchSakeMasters(query);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _results = results;
        _isLoading = false;
        _hasSearched = true;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _results = const [];
        _isLoading = false;
        _hasSearched = true;
        _hasError = true;
      });
    }
  }

  void _openDetail(SakeMapSearchResult sake) {
    unawaited(_saveRecentSearch(sake));
    _focusNode.unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SakeMasterDetailPage(
          venueSake: VenueSake(
            sakeId: sake.sakeId,
            searchToken: sake.searchToken,
            name: sake.name,
            brewery: sake.brewery,
            type: sake.type,
            recordCount: 0,
            primaryImageUrl: sake.primaryImageUrl,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showRecentSearches =
        _focusNode.hasFocus && _controller.text.trim().isEmpty;
    final displayedResults = showRecentSearches ? _recentResults : _results;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const ValueKey('masterSakeNameSearchField'),
            controller: _controller,
            focusNode: _focusNode,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: _onChanged,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              hintText: context.l10n.enterSakeName,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(13),
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      tooltip: context.l10n.search,
                      icon: const Icon(Icons.search),
                      onPressed: _search,
                    ),
              filled: true,
              fillColor: const Color(0xFFF5F7FA),
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFFFF7A1A),
                  width: 1.5,
                ),
              ),
            ),
          ),
          if (_hasError) ...[
            const SizedBox(height: 14),
            Text(
              context.l10n.dataFetchFailed,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ] else if (_hasSearched && _results.isEmpty) ...[
            const SizedBox(height: 14),
            Text(
              context.l10n.errorSakeNotFound,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF666666)),
            ),
          ] else if (displayedResults.isNotEmpty) ...[
            const SizedBox(height: 12),
            if (showRecentSearches) ...[
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.history, size: 17, color: Color(0xFF697386)),
                    SizedBox(width: 6),
                    Text(
                      '最近見た日本酒',
                      style: TextStyle(
                        color: Color(0xFF697386),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE1E5EB)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: displayedResults.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final sake = displayedResults[index];
                      final details = [
                        sake.brewery?.trim(),
                        sake.type?.trim(),
                      ].whereType<String>().where((value) => value.isNotEmpty);
                      return ListTile(
                        key: ValueKey('masterSakeCandidate_${sake.sakeId}'),
                        leading: _SakeCandidateImage(
                          imageUrl:
                              sake.thumbnailImageUrl ?? sake.primaryImageUrl,
                        ),
                        title: Text(
                          sake.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF1D3567),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: details.isEmpty
                            ? null
                            : Text(
                                details.join(' / '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openDetail(sake),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SakeCandidateImage extends StatelessWidget {
  const _SakeCandidateImage({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final imageUrl = this.imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 46,
        height: 46,
        color: const Color(0xFFF0F2F5),
        child: imageUrl == null
            ? const Icon(Icons.local_drink_outlined, color: Color(0xFF1D3567))
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.local_drink_outlined,
                  color: Color(0xFF1D3567),
                ),
              ),
      ),
    );
  }
}

class _SearchShortcuts extends StatelessWidget {
  const _SearchShortcuts({
    required this.onMapTap,
    required this.onMenuSearchTap,
    required this.onFastSearchTap,
    required this.onPreferenceSearchTap,
  });

  final VoidCallback onMapTap;
  final VoidCallback onMenuSearchTap;
  final VoidCallback onFastSearchTap;
  final VoidCallback onPreferenceSearchTap;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: _SearchShortcutCard(
              icon: Icons.map_outlined,
              title: context.l10n.mapSearchShortcut,
              description: context.l10n.mapSearchShortcutDescription,
              onTap: onMapTap,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SearchShortcutCard(
              icon: Icons.document_scanner_outlined,
              title: context.l10n.fastSearchShortcut,
              description: context.l10n.fastSearchShortcutDescription,
              onTap: onFastSearchTap,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _SearchShortcutCard(
              icon: Icons.landscape_outlined,
              title: context.l10n.searchByRegion,
              description: context.l10n.preferenceSearchDescription,
              onTap: onPreferenceSearchTap,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SearchShortcutCard(
              icon: Icons.menu_book_outlined,
              title: context.l10n.menuSearchPageTitle,
              description: context.l10n.menuPhotoDescription,
              onTap: onMenuSearchTap,
            ),
          ),
        ],
      ),
    ],
  );
}

class _SearchShortcutCard extends StatelessWidget {
  const _SearchShortcutCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 126,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 18, 12, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: const Color(0xFF1D3567), size: 32),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1D3567),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF606060),
                          fontSize: 11,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: -9,
            right: -7,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFFF7A1A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                child: Text(
                  context.l10n.newFeatureBadge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final ButtonStyle flatButtonStyle = TextButton.styleFrom(
  foregroundColor: Colors.black,
  minimumSize: Size(88, 36),
  padding: EdgeInsets.symmetric(horizontal: 16),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(2)),
  ),
);
