import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'menu_history_page.dart';
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
import 'menu_search_page_notifier.dart';
import 'menu_photo_flow_page.dart';
import 'widgets/menu_capture_entry.dart';
import 'widgets/menu_photo_style.dart';
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

  bool _openingPhoto = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final notifier = context.read<MenuSearchPageNotifier>();
      final initial = notifier.initialImage;
      if (initial != null) {
        await notifier.selectPhoto(initial);
        if (mounted) await _showPhotoFlow();
      }
    });
  }

  Future<void> _pickPhoto(Future<void> Function() pick) async {
    if (_openingPhoto) return;
    _openingPhoto = true;
    try {
      final notifier = context.read<MenuSearchPageNotifier>();
      final before = context.read<MenuSearchPageState>().sakeImage;
      await pick();
      if (!mounted) return;
      final after = context.read<MenuSearchPageState>().sakeImage;
      if (after != null && after != before) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => MenuPhotoFlowPage(notifier: notifier),
          ),
        );
      }
    } finally {
      _openingPhoto = false;
    }
  }

  Future<void> _showPhotoFlow() async {
    if (_openingPhoto) return;
    _openingPhoto = true;
    try {
      final notifier = context.read<MenuSearchPageNotifier>();
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => MenuPhotoFlowPage(notifier: notifier),
        ),
      );
    } finally {
      _openingPhoto = false;
    }
  }

  Future<void> _showHistory(String? id) async {
    final notifier = context.read<MenuSearchPageNotifier>();
    await MenuHistoryPage.open(context, notifier, historyId: id);
  }

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
    final isMasterLookupComplete = context.select(
      (MenuSearchPageState state) => state.isMasterLookupComplete,
    );
    final extractedSakes = context.select(
      (MenuSearchPageState state) => state.extractedSakes,
    );
    final sakes = context.select((MenuSearchPageState state) => state.sakes);
    final myFavoriteList = context.select(
      (FavoriteState state) => state.myFavoriteList,
    );
    final mySavedList = context.select(
      (SavedSakeState state) => state.bookmarkedSakes,
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
        backgroundColor: MenuPhotoStyle.blue,
        appBar: MenuPhotoStyle.appBar(
          context.l10n.navigationMenuAnalysis,
          onBack: Navigator.of(context).canPop()
              ? () => Navigator.of(context).pop()
              : null,
        ),
        body: SingleChildScrollView(
          controller: _scrollController,
          // Clear the scan button's 43pt overlap plus a little breathing room.
          padding: const EdgeInsets.only(bottom: 64),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MenuCaptureEntry(
                  history: history,
                  onCamera: () => _pickPhoto(notifier.pickImageFromCamera),
                  onGallery: () => _pickPhoto(notifier.pickImageFromGallery),
                  onHistory: (id) => _showHistory(id),
                  onMore: () => _showHistory(null),
                ),
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Text(
                          localizeLegacyMessage(context.l10n, errorMessage),
                          style: MenuPhotoStyle.text(13),
                        ),
                        if (notifier.hasPendingHistorySave)
                          TextButton(
                            onPressed: notifier.retrySaveMenuAnalysisHistory,
                            child: Text(context.l10n.retryHistorySave),
                          ),
                      ],
                    ),
                  ),
                if (extractedSakes.isNotEmpty)
                  Container(
                    key: notifier.resultsSectionKey,
                    padding: const EdgeInsets.only(
                      top: 24,
                      left: 24,
                      right: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: MenuResultPlaceField(
                            key: ValueKey(currentHistoryId),
                            history: currentHistory,
                            onSave: (place) => notifier.setHistoryPlace(
                              currentHistory!.id,
                              place,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                context.l10n.sakeCount(extractedSakes.length),
                                style: MenuPhotoStyle.text(16, bold: true),
                              ),
                            ),
                            if (currentHistory?.analysisStatus == 'partial' ||
                                currentHistory?.analysisStatus == 'pending')
                              Text(
                                currentHistory!.analysisStatus == 'partial'
                                    ? context.l10n.menuHistoryPartial
                                    : context.l10n.menuHistoryPending,
                                style: MenuPhotoStyle.text(
                                  12,
                                  color: MenuPhotoStyle.yellow,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
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
                              orElse: () =>
                                  Sake(name: sake.name, type: sake.type),
                            );

                            // この日本酒が現在読み込み中かどうか
                            final isItemLoading =
                                sakeLoadingStatus[sake.name] ?? false;

                            // 詳細情報があるかどうか
                            final hasDetails =
                                sakes != null &&
                                sakes.any((s) => s.name == mappedName);

                            final matchPercent = matchPercents[sake.name];
                            final candidates =
                                resolutionCandidates[sake.name] ??
                                const <MenuSakeCandidate>[];
                            final hasFailed =
                                !isItemLoading &&
                                !hasDetails &&
                                candidates.isEmpty &&
                                sakeLoadingStatus.containsKey(sake.name);

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
                              key: ValueKey('${sake.name}\u0000${sake.type}'),
                              dark: true,
                              sake: sake,
                              detailedSake: detailedSake,
                              hasDetails: hasDetails,
                              isItemLoading: isItemLoading,
                              hasFailed: hasFailed,
                              isFavorited: isFavorited,
                              isLoading: isLoading,
                              matchPercent: matchPercent,
                              tasteProfile: tasteProfiles[sake.name],
                              isUnverified: unverifiedNames.contains(sake.name),
                              candidates: candidates,
                              onCandidateSelected: (candidate) =>
                                  notifier.selectMenuCandidate(
                                    sake.name ?? '',
                                    candidate,
                                  ),
                              onOpenDetails: (detailedSake?.sakeId ?? 0) > 0
                                  ? () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => SakeMasterDetailPage(
                                          venueSake: VenueSake(
                                            sakeId: detailedSake!.sakeId,
                                            name:
                                                detailedSake.name ??
                                                sake.name ??
                                                '名称不明',
                                            brewery: detailedSake.brewery,
                                            type: detailedSake.type,
                                            recordCount: 0,
                                            primaryImageUrl:
                                                detailedSake.primaryImageUrl,
                                            thumbnailImageUrl:
                                                detailedSake.thumbnailImageUrl,
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
                                    maxCount:
                                        FavoriteNotifier.guestFavoriteLimit,
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
                                    maxCount:
                                        FavoriteNotifier.guestFavoriteLimit,
                                  );
                                }
                              },
                              isSaved: isSaved,
                              onSave: () async {
                                if (detailedSake == null) {
                                  logger.warning('詳細情報がない日本酒の保存操作が呼び出されました');
                                  return false;
                                }
                                if (!isSaved &&
                                    savedNotifier.hasReachedGuestLimit) {
                                  await GuestLimitDialog.showSavedSakeLimit(
                                    context,
                                    maxCount: SavedSakeNotifier.guestSavedLimit,
                                  );
                                  return false;
                                }
                                if (!isSaved &&
                                    savedNotifier.hasReachedMemberLimit) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        context.l10n.savedSakeLimit(
                                          SavedSakeNotifier.memberSavedLimit,
                                        ),
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return false;
                                }
                                try {
                                  final changed = await savedNotifier
                                      .toggleSavedSake(detailedSake);
                                  if (!changed) {
                                    if (context.mounted)
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            '保存状態を変更できませんでした。もう一度お試しください。',
                                          ),
                                        ),
                                      );
                                    return isSaved;
                                  }
                                } on SavedSakeGuestLimitReachedException {
                                  await GuestLimitDialog.showSavedSakeLimit(
                                    context,
                                    maxCount: SavedSakeNotifier.guestSavedLimit,
                                  );
                                  return false;
                                } on SavedSakeMemberLimitReachedException {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        context.l10n.savedSakeLimit(
                                          SavedSakeNotifier.memberSavedLimit,
                                        ),
                                      ),
                                      behavior: SnackBarBehavior.floating,
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
                                    dark: true,
                                  ),
                              buildTypesRow: (types) => buildMenuSakeTypesRow(
                                context,
                                types,
                                dark: true,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
              ],
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
