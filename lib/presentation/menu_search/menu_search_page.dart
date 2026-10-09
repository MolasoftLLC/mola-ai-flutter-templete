import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:mola_gemini_flutter_template/common/utils/file_utils.dart';
import 'package:mola_gemini_flutter_template/presentation/common/loading/ai_loading.dart';
import 'package:mola_gemini_flutter_template/presentation/menu_search/widgets/menu_history_section.dart';
import 'package:mola_gemini_flutter_template/presentation/menu_search/widgets/sake_result_tile.dart';
import 'package:provider/provider.dart';

import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/eintities/menu_sake_resolution.dart';
import '../../common/logger.dart';
import '../../common/localization/localization_extensions.dart';
import '../../domain/notifier/favorite/favorite_notifier.dart';
import '../../domain/notifier/saved_sake/saved_sake_notifier.dart';
import '../../domain/repository/place_map_repository.dart';
import '../sake_map/sake_master_detail_page.dart';
import '../common/widgets/guest_limit_dialog.dart';
import '../common/help/help_guide_dialog.dart';
import '../common/widgets/primary_app_bar.dart';
import 'menu_search_page_notifier.dart';
import 'widgets/menu_sake_detail_rows.dart';
import 'widgets/menu_result_place_field.dart';

class MenuSearchPage extends StatefulWidget {
  const MenuSearchPage._({Key? key}) : super(key: key);

  static Widget wrapped({File? initialImage}) {
    return MultiProvider(
      providers: [
        StateNotifierProvider<MenuSearchPageNotifier, MenuSearchPageState>(
          create: (context) => MenuSearchPageNotifier(
            context: context,
            initialImage: initialImage,
          ),
        ),
      ],
      child: const MenuSearchPage._(),
    );
  }

  @override
  State<MenuSearchPage> createState() => _MenuSearchPageState();
}

class _MenuSearchPageState extends State<MenuSearchPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<MenuSearchPageNotifier>();
    final history = context.select(
      (MenuSearchPageState state) => state.menuAnalysisHistory,
    );
    final currentHistoryId = notifier.currentAnalysisHistoryId;
    final currentHistory = history
        .where((item) => item.id == currentHistoryId)
        .firstOrNull;
    final favNotifier = context.watch<FavoriteNotifier>();
    final savedNotifier = context.watch<SavedSakeNotifier>();
    final isLoading = context.select(
      (MenuSearchPageState state) => state.isLoading,
    );
    final isExtractingInfo = context.select(
      (MenuSearchPageState state) => state.isExtractingInfo,
    );
    final isGettingDetails = context.select(
      (MenuSearchPageState state) => state.isGettingDetails,
    );
    final isMasterLookupComplete = context.select(
      (MenuSearchPageState state) => state.isMasterLookupComplete,
    );
    final sakeImage = context.select(
      (MenuSearchPageState state) => state.sakeImage,
    );
    final extractedSakes = context.select(
      (MenuSearchPageState state) => state.extractedSakes,
    );
    final sakes = context.select((MenuSearchPageState state) => state.sakes);
    final myFavoriteList = context.select(
      (FavoriteState state) => state.myFavoriteList,
    );
    final mySavedList = context.select(
      (SavedSakeState state) => state.savedSakeList,
    );
    final errorMessage = context.select(
      (MenuSearchPageState state) => state.errorMessage,
    );
    // 各日本酒の読み込み状態
    final sakeLoadingStatus = context.select(
      (MenuSearchPageState state) => state.sakeLoadingStatus,
    );

    // 名前のマッピング（元の名前 -> 取得した詳細情報の名前）
    final nameMapping = context.select(
      (MenuSearchPageState state) => state.nameMapping,
    );
    final resolutionCandidates = context.select(
      (MenuSearchPageState state) => state.resolutionCandidates,
    );
    final matchPercents = context.select(
      (MenuSearchPageState state) => state.matchPercents,
    );
    final tasteProfiles = context.select(
      (MenuSearchPageState state) => state.tasteProfiles,
    );
    final unverifiedNames = context.select(
      (MenuSearchPageState state) => state.unverifiedNames,
    );

    String loadingText = context.l10n.loadingSakeInfo;
    if (isExtractingInfo) {
      loadingText = context.l10n.analyzingWithAd;
    } else if (isGettingDetails) {
      loadingText = context.l10n.loadingSakeInfo;
    }

    final hasScrolledToResults = context.select(
      (MenuSearchPageState state) => state.hasScrolledToResults,
    );

    if (extractedSakes.isNotEmpty &&
        isMasterLookupComplete &&
        !isLoading &&
        !isExtractingInfo &&
        !hasScrolledToResults) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        _scrollToResults(notifier.resultsSectionKey);
        notifier.setHasScrolledToResults(true);
      });
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: PrimaryAppBar(
          title: context.l10n.menuSearchPageTitle,
          actions: [
            IconButton(
              tooltip: context.l10n.helpGuide,
              icon: const Icon(Icons.help_outline, color: Color(0xFFFFD54F)),
              onPressed: () {
                HelpGuideDialog.showForType(
                  context,
                  type: HelpGuideType.menuSearch,
                );
              },
            ),
          ],
        ),
        body: Container(
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(color: Color(0xFF1D3567)),
          child: SingleChildScrollView(
            controller: _scrollController,
            child: isLoading
                ? AILoading(loadingText: loadingText)
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
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
                              Text(
                                context.l10n.menuPhotoDescription,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1D3567),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              if (sakeImage != null)
                                Stack(
                                  children: [
                                    Container(
                                      height: 200,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                          width: 2,
                                        ),
                                        image: DecorationImage(
                                          image: FileUtils.safeLoadImage(
                                            sakeImage.path,
                                            base64Image:
                                                null, // Current image doesn't have base64 yet
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: InkWell(
                                        onTap: () {
                                          notifier.clearImage();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.8,
                                            ),
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
                              else
                                Column(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        notifier.pickImageFromGallery();
                                      },
                                      child: Container(
                                        height: 150,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                            width: 2,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.menu_book,
                                              size: 48,
                                              color: Color(0xFF1D3567),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              context.l10n.tapToSelectImage,
                                              style: const TextStyle(
                                                color: Color(0xFF1D3567),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        notifier.pickImageFromCamera();
                                      },
                                      icon: const Icon(Icons.camera_alt),
                                      label: Text(context.l10n.takePhoto),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF1D3567,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 20),
                              if (sakeImage != null)
                                ElevatedButton.icon(
                                  onPressed: () {
                                    notifier.extractAndFetchSakeInfo(sakeImage);
                                  },
                                  icon: const Icon(Icons.search),
                                  label: Text(context.l10n.searchSakeFromMenu),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1D3567),
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
                              if (errorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.red.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: Colors.red.shade700,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            localizeLegacyMessage(
                                              context.l10n,
                                              errorMessage,
                                            ),
                                            style: TextStyle(
                                              color: Colors.red.shade700,
                                            ),
                                          ),
                                        ),
                                        if (notifier.hasPendingHistorySave)
                                          TextButton(
                                            onPressed: notifier
                                                .retrySaveMenuAnalysisHistory,
                                            child: Text(
                                              context.l10n.retryHistorySave,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (extractedSakes.isNotEmpty)
                          Container(
                            key: notifier.resultsSectionKey,
                            padding: const EdgeInsets.only(
                              top: 42,
                              left: 12,
                              right: 12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Text(
                                    context.l10n.detectedSake,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 20,
                                    bottom: 20,
                                  ),
                                  child: MenuResultPlaceField(
                                    key: ValueKey(currentHistoryId),
                                    history: currentHistory,
                                    onSave: (place) => notifier.setHistoryPlace(
                                      currentHistory!.id,
                                      place,
                                    ),
                                  ),
                                ),
                                if (!isMasterLookupComplete)
                                  const Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFFFFD54F),
                                      ),
                                    ),
                                  ),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: isMasterLookupComplete
                                      ? extractedSakes.length
                                      : 0,
                                  itemBuilder: (context, index) {
                                    final sake = extractedSakes[index];

                                    // 元の名前から取得した詳細情報の名前を取得
                                    final mappedName =
                                        nameMapping[sake.name] ?? sake.name;

                                    // 詳細情報が取得された日本酒を探す
                                    final detailedSake = sakes?.firstWhere(
                                      (s) => s.name == mappedName,
                                      orElse: () => Sake(
                                        name: sake.name,
                                        type: sake.type,
                                      ),
                                    );

                                    // この日本酒が現在読み込み中かどうか
                                    final isItemLoading =
                                        sakeLoadingStatus[sake.name] ?? false;

                                    // 詳細情報があるかどうか
                                    final hasDetails =
                                        sakes != null &&
                                        sakes.any((s) => s.name == mappedName);

                                    final matchPercent =
                                        matchPercents[sake.name];
                                    final candidates =
                                        resolutionCandidates[sake.name] ??
                                        const <MenuSakeCandidate>[];
                                    final hasFailed =
                                        !isItemLoading &&
                                        !hasDetails &&
                                        candidates.isEmpty &&
                                        sakeLoadingStatus.containsKey(
                                          sake.name,
                                        );

                                    final isFavorited = myFavoriteList.any(
                                      (favorite) =>
                                          favorite.name ==
                                              (hasDetails
                                                  ? detailedSake!.name
                                                  : sake.name) &&
                                          favorite.type ==
                                              (hasDetails
                                                  ? detailedSake!.type
                                                  : sake.type),
                                    );

                                    final isSaved = mySavedList.any(
                                      (saved) =>
                                          saved.name ==
                                              (hasDetails
                                                  ? detailedSake!.name
                                                  : sake.name) &&
                                          saved.type ==
                                              (hasDetails
                                                  ? detailedSake!.type
                                                  : sake.type),
                                    );

                                    return SakeResultTile(
                                      key: ValueKey(
                                        '${sake.name}\u0000${sake.type}',
                                      ),
                                      sake: sake,
                                      detailedSake: detailedSake,
                                      hasDetails: hasDetails,
                                      isItemLoading: isItemLoading,
                                      hasFailed: hasFailed,
                                      isFavorited: isFavorited,
                                      isLoading: isLoading,
                                      matchPercent: matchPercent,
                                      tasteProfile: tasteProfiles[sake.name],
                                      isUnverified: unverifiedNames.contains(
                                        sake.name,
                                      ),
                                      candidates: candidates,
                                      onCandidateSelected: (candidate) =>
                                          notifier.selectMenuCandidate(
                                            sake.name ?? '',
                                            candidate,
                                          ),
                                      onOpenDetails:
                                          (detailedSake?.sakeId ?? 0) > 0
                                          ? () => Navigator.of(context).push(
                                              MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    SakeMasterDetailPage(
                                                      venueSake: VenueSake(
                                                        sakeId: detailedSake!
                                                            .sakeId,
                                                        name:
                                                            detailedSake.name ??
                                                            sake.name ??
                                                            '名称不明',
                                                        brewery: detailedSake
                                                            .brewery,
                                                        type: detailedSake.type,
                                                        recordCount: 0,
                                                        primaryImageUrl:
                                                            detailedSake
                                                                .primaryImageUrl,
                                                        thumbnailImageUrl:
                                                            detailedSake
                                                                .thumbnailImageUrl,
                                                      ),
                                                    ),
                                              ),
                                            )
                                          : null,
                                      onToggleFavorite: () async {
                                        final favoriteSake = FavoriteSake(
                                          sakeId: detailedSake!.sakeId,
                                          name: detailedSake.name ?? 'Unknown',
                                          type: detailedSake.type,
                                        );
                                        if (!isFavorited &&
                                            favNotifier.hasReachedGuestLimit) {
                                          await GuestLimitDialog.showFavoriteLimit(
                                            context,
                                            maxCount: FavoriteNotifier
                                                .guestFavoriteLimit,
                                          );
                                          return;
                                        }
                                        try {
                                          await favNotifier.addOrRemoveFavorite(
                                            favoriteSake,
                                          );
                                        } on FavoriteGuestLimitReachedException {
                                          await GuestLimitDialog.showFavoriteLimit(
                                            context,
                                            maxCount: FavoriteNotifier
                                                .guestFavoriteLimit,
                                          );
                                        }
                                      },
                                      isSaved: isSaved,
                                      onSave: () async {
                                        if (detailedSake == null) {
                                          logger.warning(
                                            '詳細情報がない日本酒の保存操作が呼び出されました',
                                          );
                                          return false;
                                        }
                                        if (!isSaved &&
                                            savedNotifier
                                                .hasReachedGuestLimit) {
                                          await GuestLimitDialog.showSavedSakeLimit(
                                            context,
                                            maxCount: SavedSakeNotifier
                                                .guestSavedLimit,
                                          );
                                          return false;
                                        }
                                        if (!isSaved &&
                                            savedNotifier
                                                .hasReachedMemberLimit) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                context.l10n.savedSakeLimit(
                                                  SavedSakeNotifier
                                                      .memberSavedLimit,
                                                ),
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                          return false;
                                        }
                                        try {
                                          await savedNotifier.toggleSavedSake(
                                            detailedSake!,
                                          );
                                        } on SavedSakeGuestLimitReachedException {
                                          await GuestLimitDialog.showSavedSakeLimit(
                                            context,
                                            maxCount: SavedSakeNotifier
                                                .guestSavedLimit,
                                          );
                                          return false;
                                        } on SavedSakeMemberLimitReachedException {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                context.l10n.savedSakeLimit(
                                                  SavedSakeNotifier
                                                      .memberSavedLimit,
                                                ),
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                          return false;
                                        }
                                        return !isSaved;
                                      },
                                      buildInfoRow: (key, value, icon) =>
                                          buildMenuSakeInfoRow(
                                            key,
                                            value,
                                            icon,
                                          ),
                                      buildTypesRow: (types) =>
                                          buildMenuSakeTypesRow(context, types),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                        // メニュー解析履歴セクション
                        const MenuHistorySection(),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  static void _scrollToResults(GlobalKey resultsKey) {
    final target = resultsKey.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }
}
