import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../common/localization/localization_extensions.dart';
import '../../common/sake/master.dart' as sake_master;
import '../../common/utils/custom_image_picker.dart';
import '../../common/utils/image_cropper_service.dart';
import '../../common/utils/snack_bar_utils.dart';
import '../../domain/eintities/sake_label_scan.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/notifier/auth/auth_notifier.dart';
import '../../domain/notifier/favorite/favorite_notifier.dart';
import '../../domain/notifier/my_page/my_page_notifier.dart';
import '../../domain/notifier/saved_sake/saved_sake_notifier.dart';
import '../../domain/repository/place_map_repository.dart';
import '../../domain/repository/auth_repository.dart';
import '../../domain/repository/sake_menu_recognition_repository.dart';
import '../../domain/repository/sake_scan_repository.dart';
import '../../domain/repository/sake_community_repository.dart';
import '../common/widgets/guest_limit_dialog.dart';
import '../my_page/widgets/place_picker_sheet.dart';
import 'sake_map_page.dart';

const _navy = Color(0xFF143861);
const _orange = Color(0xFFFF7A1A);

class SakeMasterDetailPage extends StatefulWidget {
  const SakeMasterDetailPage({super.key, required this.venueSake});
  final VenueSake venueSake;

  @override
  State<SakeMasterDetailPage> createState() => _SakeMasterDetailPageState();
}

class _SakeMasterDetailPageState extends State<SakeMasterDetailPage> {
  Future<SakeOverview>? _future;
  final ScrollController _scrollController = ScrollController();
  bool _initialized = false;
  bool _showCompactHeader = false;
  SakeOverview? _headerOverview;
  SavedSakeNotifier? _savedSakeNotifier;
  FavoriteNotifier? _favoriteNotifier;
  void Function()? _removeSavedSakeListener;
  void Function()? _removeFavoriteListener;
  Timer? _masterEnrichmentPollTimer;
  var _masterEnrichmentPollCount = 0;
  var _isFetchingDetails = false;

  bool get _isAiSearchCandidate =>
      widget.venueSake.sakeId == null &&
      (widget.venueSake.searchToken?.startsWith('candidate:') ?? false);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bindNotifiers();
    if (_initialized) return;
    _initialized = true;
    _isFetchingDetails = true;
    _future = _fetch();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateCompactHeaderVisibility);
  }

  void _updateCompactHeaderVisibility() {
    final shouldShow =
        _scrollController.hasClients && _scrollController.offset >= 180;
    if (shouldShow != _showCompactHeader && mounted) {
      setState(() => _showCompactHeader = shouldShow);
    }
  }

  void _bindNotifiers() {
    final saved = Provider.of<SavedSakeNotifier?>(context, listen: false);
    final favorite = Provider.of<FavoriteNotifier?>(context, listen: false);
    if (!identical(_savedSakeNotifier, saved)) {
      _removeSavedSakeListener?.call();
      _savedSakeNotifier = saved;
      _removeSavedSakeListener = _savedSakeNotifier?.addListener(
        (_) => _refreshFromNotifier(),
      );
    }
    if (!identical(_favoriteNotifier, favorite)) {
      _removeFavoriteListener?.call();
      _favoriteNotifier = favorite;
      _removeFavoriteListener = _favoriteNotifier?.addListener(
        (_) => _refreshFromNotifier(),
      );
    }
  }

  void _refreshFromNotifier() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _masterEnrichmentPollTimer?.cancel();
    _scrollController
      ..removeListener(_updateCompactHeaderVisibility)
      ..dispose();
    _removeSavedSakeListener?.call();
    _removeFavoriteListener?.call();
    super.dispose();
  }

  Future<SakeOverview> _fetch() async {
    final id = _headerOverview?.sake.sakeId ?? widget.venueSake.sakeId;
    try {
      final SakeOverview overview;
      if (id != null && id > 0) {
        overview = await context.read<SakeScanRepository>().fetchOverview(
          id,
          trackView: true,
        );
      } else if (_isAiSearchCandidate) {
        final analyzed = await context
            .read<SakeMenuRecognitionRepository>()
            .resolveSakeCandidateOverview(widget.venueSake.searchToken!);
        if (analyzed == null || (analyzed.sake.sakeId ?? 0) <= 0) {
          throw StateError('AI候補の詳細情報を取得できませんでした');
        }
        overview = analyzed;
      } else {
        throw StateError('詳細取得に必要な日本酒IDがありません');
      }

      if (mounted) {
        setState(() => _headerOverview = overview);
      }
      unawaited(_syncOverviewImagesToSavedRecord(overview));
      _scheduleMasterEnrichmentPolling(overview);
      return overview;
    } finally {
      if (mounted) {
        setState(() => _isFetchingDetails = false);
      }
    }
  }

  void _scheduleMasterEnrichmentPolling(SakeOverview overview) {
    _masterEnrichmentPollTimer?.cancel();
    if (!overview.masterEnrichmentPending ||
        overview.master.tasteProfile != null) {
      return;
    }
    _masterEnrichmentPollCount = 0;
    _masterEnrichmentPollTimer = Timer.periodic(const Duration(seconds: 2), (
      timer,
    ) async {
      final sakeId = _headerOverview?.sake.sakeId ?? widget.venueSake.sakeId;
      if (!mounted ||
          sakeId == null ||
          sakeId <= 0 ||
          _masterEnrichmentPollCount >= 30) {
        timer.cancel();
        return;
      }
      _masterEnrichmentPollCount += 1;
      try {
        final refreshed = await context
            .read<SakeScanRepository>()
            .fetchOverview(sakeId);
        if (!mounted) return;
        setState(() => _headerOverview = refreshed);
        unawaited(_syncOverviewImagesToSavedRecord(refreshed));
        if (!refreshed.masterEnrichmentPending ||
            refreshed.master.tasteProfile != null) {
          timer.cancel();
        }
      } catch (_) {
        // 初回の詳細は表示済みなので、次回アクセス時に再試行する。
      }
    });
  }

  Future<void> _syncOverviewImagesToSavedRecord(SakeOverview overview) async {
    final notifier = _savedSakeNotifier;
    final record = _findSavedSake(notifier, overview.sake);
    if (notifier == null || record == null) return;
    final savedId = record.savedId;
    if (savedId == null || savedId.isEmpty) return;
    final primary = overview.sake.primaryImageUrl?.trim();
    final thumbnail = overview.sake.thumbnailImageUrl?.trim();
    if ((primary == null || primary.isEmpty) &&
        (thumbnail == null || thumbnail.isEmpty)) {
      return;
    }
    final nextPrimary = primary?.isNotEmpty == true
        ? primary
        : record.primaryImageUrl;
    final nextThumbnail = thumbnail?.isNotEmpty == true
        ? thumbnail
        : record.thumbnailImageUrl;
    if (record.primaryImageUrl == nextPrimary &&
        record.thumbnailImageUrl == nextThumbnail) {
      return;
    }
    await notifier.updateSavedSakeWithInfo(savedId, overview.sake);
  }

  Future<void> _reload() async {
    setState(() {
      _isFetchingDetails = true;
      _future = _fetch();
    });
    try {
      await _future;
    } catch (_) {
      // FutureBuilder presents the failure and retry action.
    }
  }

  Future<void> _handleCommunityImage(SakeCommunityImage image) async {
    if (!image.isOwner && context.read<AuthRepository>().currentUser == null) {
      await GuestLimitDialog.show(
        context,
        title: '報告にはログインが必要です',
        message: '同じ画像への重複報告を防ぐため、ログインしてください。',
      );
      return;
    }
    final repository = context.read<SakeCommunityRepository>();
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                image.isOwner ? Icons.delete_outline : Icons.flag_outlined,
              ),
              title: Text(image.isOwner ? 'この画像を削除' : 'この画像を報告'),
              onTap: () => Navigator.pop(
                sheetContext,
                image.isOwner ? 'delete' : 'report',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('キャンセル'),
              onTap: () => Navigator.pop(sheetContext),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(action == 'delete' ? '画像を削除しますか？' : '画像を報告しますか？'),
        content: Text(
          action == 'delete'
              ? '詳細画面とラベル照合用の参照画像から削除されます。'
              : '不適切な画像として運営に報告します。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(action == 'delete' ? '削除' : '報告'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      if (action == 'delete') {
        await repository.deleteImage(image.imageId);
      } else {
        await repository.reportImage(image.imageId, reason: '不適切な画像');
      }
      await _reload();
      if (mounted) {
        SnackBarUtils.showInfoSnackBar(
          context,
          message: action == 'delete' ? '画像を削除しました。' : '画像を報告しました。',
        );
      }
    } catch (_) {
      if (mounted) {
        SnackBarUtils.showWarningSnackBar(context, message: '操作を完了できませんでした。');
      }
    }
  }

  Future<void> _openReviewEditor(
    Sake sake,
    SakeCommunityReview? current,
  ) async {
    if (context.read<AuthRepository>().currentUser == null) {
      await GuestLimitDialog.show(
        context,
        title: '評価にはログインが必要です',
        message: '表示名とアイコン付きで、みんなの評価に投稿されます。',
      );
      return;
    }
    final draft = await showModalBottomSheet<_CommunityReviewDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CommunityReviewEditor(initial: current),
    );
    final sakeId = sake.sakeId;
    if (draft == null || sakeId == null || !mounted) return;
    try {
      if (draft.delete) {
        await context.read<SakeCommunityRepository>().deleteReview(sakeId);
      } else {
        await context.read<SakeCommunityRepository>().saveReview(
          sakeId: sakeId,
          overallRating: draft.overallRating,
          tasteRatings: draft.tasteRatings,
          comment: draft.comment,
          savedId: _findSavedSake(_savedSakeNotifier, sake)?.savedId,
        );
      }
      await _reload();
      if (mounted) {
        SnackBarUtils.showInfoSnackBar(
          context,
          message: draft.delete ? '公開評価を削除しました。' : 'みんなの評価に投稿しました。',
        );
      }
    } catch (_) {
      if (mounted) {
        SnackBarUtils.showWarningSnackBar(context, message: '評価を保存できませんでした。');
      }
    }
  }

  Future<void> _reportCommunityReview(int reviewId) async {
    if (context.read<AuthRepository>().currentUser == null) {
      await GuestLimitDialog.show(
        context,
        title: '報告にはログインが必要です',
        message: '同じ評価への重複報告を防ぐため、ログインしてください。',
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('この評価を報告しますか？'),
        content: const Text('不適切な投稿として運営に報告します。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('報告'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<SakeCommunityRepository>().reportReview(
        reviewId,
        reason: '不適切な投稿',
      );
      await _reload();
      if (mounted) {
        SnackBarUtils.showInfoSnackBar(context, message: '評価を報告しました。');
      }
    } catch (_) {
      if (mounted) {
        SnackBarUtils.showWarningSnackBar(context, message: '評価を報告できませんでした。');
      }
    }
  }

  Future<void> _selectHeaderPlace() async {
    final notifier = _savedSakeNotifier;
    final overviewSake = _headerOverview?.sake;
    final detailSake = overviewSake ?? _asSake(widget.venueSake);
    final record = _findSavedSake(notifier, detailSake);
    if (notifier == null || record == null) {
      SnackBarUtils.showInfoSnackBar(
        context,
        message: 'このお酒を保存すると、飲んだ場所・買った場所を登録できます。',
      );
      return;
    }
    final place = await PlacePickerSheet.show(
      context,
      initialPlace: record.drinkingPlace?.displayName ?? record.place,
    );
    if (!mounted || place == null || place.displayName.trim().isEmpty) return;
    final updated = record.copyWith(
      place: place.displayName.trim(),
      drinkingPlace: place,
    );
    await notifier.updateSavedSake(updated);
    if (updated.savedId != null &&
        updated.savedId!.isNotEmpty &&
        updated.syncStatus == SavedSakeSyncStatus.serverSynced) {
      final synced = await notifier.syncSavedSakeToServer(
        updated.savedId!,
        force: true,
      );
      if (synced == null || !mounted) return;
      final result = await context.read<PlaceMapRepository>().savePlace(
        savedId: updated.savedId!,
        place: place,
      );
      if (!mounted) return;
      if (result == null) {
        SnackBarUtils.showWarningSnackBar(
          context,
          message: '場所を地図へ登録できませんでした。',
        );
        return;
      }
      await notifier.updateSavedSake(
        updated.copyWith(
          place: result.drinkingPlace.displayName,
          drinkingPlace: result.drinkingPlace,
        ),
      );
      if (mounted) {
        SnackBarUtils.showInfoSnackBar(context, message: '場所を地図へ登録しました。');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPendingAiCandidate =
        _isAiSearchCandidate && (_headerOverview?.sake.sakeId ?? 0) <= 0;
    final overviewSake = _headerOverview?.sake;
    final detailSake = overviewSake ?? _asSake(widget.venueSake);
    final masterName = overviewSake?.name?.trim();
    final displayName = masterName == null || masterName.isEmpty
        ? widget.venueSake.name.trim()
        : masterName;
    final record = _findSavedSake(_savedSakeNotifier, detailSake);
    final profile = _headerOverview?.master.tasteProfile;
    final isProfileEnrichmentPending =
        _headerOverview?.masterEnrichmentPending == true && profile == null;
    final preference = Provider.of<MyPageState?>(context)?.tasteProfile;
    final matchPercent = profile == null || preference == null
        ? null
        : calculateTastePreferenceMatchPercent(
            sakeValues: [
              profile.fruity,
              profile.sweetness,
              profile.acidity,
              profile.body ?? profile.umami,
              profile.kire,
              profile.dryness,
            ],
            preferenceValues: [
              preference.fruity,
              preference.sweetness,
              preference.acidity,
              preference.umami,
              preference.kire,
              preference.spiciness,
            ],
          );
    final community =
        _headerOverview?.community ?? const SakeCommunitySummary();
    final headerImagePaths = detailImagePaths(
      personalRecord: record,
      overviewSake: overviewSake,
      fallback: widget.venueSake,
    );
    for (final image in community.images) {
      if (!headerImagePaths.contains(image.imageUrl)) {
        headerImagePaths.add(image.imageUrl);
      }
    }
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: isPendingAiCandidate
          ? null
          : _MasterRecordCta(sake: detailSake, notifier: _savedSakeNotifier),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: FocusManager.instance.primaryFocus?.unfocus,
        child: FutureBuilder<SakeOverview>(
          future: _future,
          builder: (context, snapshot) => Stack(
            children: [
              RefreshIndicator(
                onRefresh: _reload,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      stretch: true,
                      collapsedHeight: 98,
                      expandedHeight: 370,
                      backgroundColor: _navy,
                      elevation: 0,
                      iconTheme: const IconThemeData(color: Colors.white),
                      actions: [
                        if (!isPendingAiCandidate) ...[
                          _MasterSaveButton(
                            sake: detailSake,
                            notifier: _savedSakeNotifier,
                          ),
                          _MasterFavoriteButton(
                            sake: detailSake,
                            notifier: _favoriteNotifier,
                          ),
                        ],
                        if (_showCompactHeader)
                          IconButton(
                            tooltip: '飲んだ場所・買った場所を選ぶ',
                            icon: const Icon(Icons.location_on_outlined),
                            onPressed: _selectHeaderPlace,
                          ),
                      ],
                      flexibleSpace: _CollapsingSakeHero(
                        name: displayName,
                        imagePaths: headerImagePaths,
                        matchPercent: matchPercent,
                        community: community,
                        onImageAction: _handleCommunityImage,
                        isProfileEnrichmentPending: isProfileEnrichmentPending,
                        isFetchingDetails: _isFetchingDetails,
                      ),
                    ),
                    if (snapshot.hasError)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: const Text('詳細情報を取得できませんでした。'),
                        ),
                      ),
                    const SliverToBoxAdapter(child: _ShopPriceTitle()),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _ShopPriceHeaderDelegate(
                        yahooPrice: snapshot.data?.master.imagePrice,
                        yahooCurrency: snapshot.data?.master.imageCurrency,
                        yahooProductUrl: snapshot.data?.master.imageProductUrl,
                        rakutenOffer: (_headerOverview ?? snapshot.data)
                            ?.master
                            .rakutenOffer,
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                      sliver: SliverToBoxAdapter(
                        child: _Details(
                          overview: _headerOverview ?? snapshot.data,
                          fallback: widget.venueSake,
                          savedSakeNotifier: _savedSakeNotifier,
                          preferredName: displayName,
                          onReview: (current) =>
                              _openReviewEditor(detailSake, current),
                          onReportReview: _reportCommunityReview,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (snapshot.hasError)
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: FilledButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    label: const Text('再試行'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollapsingSakeHero extends StatefulWidget {
  const _CollapsingSakeHero({
    required this.name,
    required this.imagePaths,
    required this.matchPercent,
    required this.community,
    required this.onImageAction,
    required this.isProfileEnrichmentPending,
    required this.isFetchingDetails,
  });

  final String? name;
  final List<String> imagePaths;
  final int? matchPercent;
  final SakeCommunitySummary community;
  final ValueChanged<SakeCommunityImage> onImageAction;
  final bool isProfileEnrichmentPending;
  final bool isFetchingDetails;

  @override
  State<_CollapsingSakeHero> createState() => _CollapsingSakeHeroState();
}

class _CollapsingSakeHeroState extends State<_CollapsingSakeHero> {
  late final PageController _pageController;
  var _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final topInset = MediaQuery.paddingOf(context).top;
      final collapsedHeight = topInset + 98;
      final expandedHeight = topInset + 370;
      final expandedProgress =
          ((constraints.maxHeight - collapsedHeight) /
                  (expandedHeight - collapsedHeight))
              .clamp(0.0, 1.0);
      final collapsedProgress = 1 - expandedProgress;
      final imageWidth = lerpDouble(
        MediaQuery.sizeOf(context).width - 44,
        40,
        collapsedProgress,
      )!;
      final imageHeight = lerpDouble(240, 40, collapsedProgress)!;
      final imageLeft = lerpDouble(20, 64, collapsedProgress)!;
      final imageTop = lerpDouble(
        topInset +
            kToolbarHeight +
            (widget.matchPercent == null &&
                    widget.community.averageRating == null &&
                    !widget.isProfileEnrichmentPending &&
                    !widget.isFetchingDetails
                ? 18
                : 58),
        topInset + 8,
        collapsedProgress,
      )!;
      return Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: _navy),
          Positioned(
            left: imageLeft,
            top: imageTop,
            width: imageWidth,
            height: imageHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                lerpDouble(16, 9, collapsedProgress)!,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.imagePaths.isEmpty)
                    const _DetailSakeImage()
                  else
                    PageView.builder(
                      controller: _pageController,
                      itemCount: widget.imagePaths.length,
                      onPageChanged: (index) =>
                          setState(() => _currentPage = index),
                      itemBuilder: (context, index) =>
                          _DetailSakeImage(path: widget.imagePaths[index]),
                    ),
                  if (widget.imagePaths.length > 1)
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Opacity(
                        opacity: expandedProgress,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '${_currentPage + 1}/${widget.imagePaths.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (expandedProgress > .5 && widget.imagePaths.isNotEmpty)
                    Builder(
                      builder: (context) {
                        final currentPath =
                            widget.imagePaths[_currentPage.clamp(
                              0,
                              widget.imagePaths.length - 1,
                            )];
                        SakeCommunityImage? image;
                        for (final candidate in widget.community.images) {
                          if (candidate.imageUrl == currentPath) {
                            image = candidate;
                            break;
                          }
                        }
                        if (image == null) return const SizedBox.shrink();
                        final selectedImage = image;
                        return Positioned(
                          right: 8,
                          top: 8,
                          child: Material(
                            color: Colors.black54,
                            shape: const CircleBorder(),
                            child: IconButton(
                              tooltip: selectedImage.isOwner
                                  ? '画像を削除'
                                  : '画像を報告',
                              onPressed: () =>
                                  widget.onImageAction(selectedImage),
                              icon: Icon(
                                selectedImage.isOwner
                                    ? Icons.delete_outline
                                    : Icons.flag_outlined,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 56,
            right: 56,
            top: topInset + 18,
            child: Opacity(
              opacity: expandedProgress,
              child: const Text(
                '日本酒詳細',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (widget.isFetchingDetails)
            Positioned(
              left: 20,
              right: 20,
              top: topInset + 50,
              child: Opacity(
                opacity: expandedProgress,
                child: const _ProfileAnalysisProgress(label: '詳細情報を取得中'),
              ),
            ),
          if (!widget.isFetchingDetails &&
              (widget.matchPercent != null ||
                  widget.community.averageRating != null))
            Positioned(
              left: 20,
              right: 20,
              top: topInset + 50,
              child: Opacity(
                opacity: expandedProgress,
                child: _SakeScoreSummary(
                  matchPercent: widget.matchPercent,
                  averageRating: widget.community.averageRating,
                  reviewCount: widget.community.reviewCount,
                ),
              ),
            ),
          if (!widget.isFetchingDetails && widget.isProfileEnrichmentPending)
            Positioned(
              left: 20,
              right: 20,
              top: topInset + 50,
              child: Opacity(
                opacity: expandedProgress,
                child: const _ProfileAnalysisProgress(label: '味わいプロフィールを解析中'),
              ),
            ),
          Positioned(
            left: 120,
            right: 156,
            top: topInset + 15,
            child: collapsedProgress > .5
                ? widget.matchPercent == null || widget.isFetchingDetails
                      ? const SizedBox.shrink()
                      : Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFA13C), Color(0xFFE95C9A)],
                            ),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '${widget.matchPercent}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        )
                : const SizedBox.shrink(),
          ),
          Positioned(
            left: 20,
            right: 20,
            top: topInset + 62,
            child: collapsedProgress > .5
                ? KeyedSubtree(
                    key: const Key('compact-sake-header'),
                    child: Text(
                      widget.name?.trim().isNotEmpty == true
                          ? widget.name!
                          : '日本酒詳細',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      );
    },
  );
}

class _Details extends StatelessWidget {
  const _Details({
    required this.overview,
    required this.fallback,
    required this.savedSakeNotifier,
    this.preferredName,
    required this.onReview,
    required this.onReportReview,
  });
  final SakeOverview? overview;
  final VenueSake fallback;
  final SavedSakeNotifier? savedSakeNotifier;
  final String? preferredName;
  final ValueChanged<SakeCommunityReview?> onReview;
  final ValueChanged<int> onReportReview;

  @override
  Widget build(BuildContext context) {
    final sake = overview?.sake;
    final detailSake = sake ?? _asSake(fallback);
    final personalRecord = _findSavedSake(savedSakeNotifier, detailSake);
    final master = overview?.master ?? const SakeMasterDetails();
    final profile = master.tasteProfile;
    final preference = Provider.of<MyPageState?>(context)?.tasteProfile;
    final isLoggedIn = Provider.of<AuthState?>(context)?.user != null;
    final category =
        master.category ??
        master.specialDesignation ??
        sake?.type ??
        fallback.type;
    final sakeMeterValue =
        master.sakeMeterValue ??
        sake?.sakeMeterValue ??
        personalRecord?.sakeMeterValue;
    final specs = <String, String>{
      if (master.riceVariety != null)
        '原料米': [
          master.riceVariety!,
          if (master.riceOrigin != null) master.riceOrigin!,
        ].join(' / '),
      if (master.polishingRatio != null)
        '精米歩合': '${_number(master.polishingRatio!)}%',
      if (master.alcoholPercentage != null)
        'アルコール度数': '${_number(master.alcoholPercentage!)}%',
      if (sakeMeterValue != null)
        '日本酒度':
            '${sakeMeterValue > 0 ? '+' : ''}${_number(sakeMeterValue.toDouble())}',
      if (master.acidity != null) '酸度': _number(master.acidity!),
      if (master.aminoAcid != null) 'アミノ酸度': _number(master.aminoAcid!),
      if (master.pasteurizationType != null) '火入れ': master.pasteurizationType!,
      if (master.availabilityType != null) '流通区分': master.availabilityType!,
      if (master.releaseSeason != null) '販売時期': master.releaseSeason!,
    };
    final tasteAxes = profile == null
        ? const <_TasteAxis>[]
        : <_TasteAxis>[
            _TasteAxis('フルーティ', profile.fruity),
            _TasteAxis('甘み', profile.sweetness),
            _TasteAxis('酸味', profile.acidity),
            _TasteAxis('コク', profile.body ?? profile.umami),
            _TasteAxis('キレ', profile.kire),
            _TasteAxis('辛さ', profile.dryness),
          ];
    final preferenceAxes = profile == null || preference == null
        ? null
        : <_TasteAxis>[
            _TasteAxis('フルーティ', preference.fruity),
            _TasteAxis('甘み', preference.sweetness),
            _TasteAxis('酸味', preference.acidity),
            _TasteAxis('コク', preference.umami),
            _TasteAxis('キレ', preference.kire),
            _TasteAxis('辛さ', preference.spiciness),
          ];
    final pairings = _pairingsFor(
      profile: profile,
      category: category,
      styles: master.styles.map((style) => style.name),
    );
    final breweryName =
        overview?.brewery.name ?? sake?.brewery ?? fallback.brewery;
    final description = sake?.description;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Section(
              topPadding: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (category != null) ...[
                    _Tags(values: [category], accent: true),
                  ],
                  if (category != null) const SizedBox(height: 14),
                  Text(
                    preferredName ?? sake?.name ?? fallback.name,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 26,
                      height: 1.3,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (breweryName != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      breweryName,
                      style: const TextStyle(color: Color(0xFF647184)),
                    ),
                  ],
                  if (master.styles.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _Tags(
                      values: master.styles.map((style) => style.name).toList(),
                    ),
                  ],
                ],
              ),
            ),
            if (personalRecord != null)
              _Section(
                child: _PersonalRecordSection(
                  sake: detailSake,
                  notifier: savedSakeNotifier,
                ),
              ),
            if ((detailSake.sakeId ?? 0) > 0)
              _Section(
                title: 'みんなの評価',
                child: _CommunityReviewsSection(
                  community:
                      overview?.community ?? const SakeCommunitySummary(),
                  onReview: onReview,
                  onReportReview: onReportReview,
                ),
              ),
            if (preferenceAxes == null && !isLoggedIn)
              const _Section(
                title: 'あなたの好みマッチ度',
                child: _LoginRecommendationPrompt(),
              ),
            if (overview != null && detailSake.sakeId != null)
              _Section(
                child: _NearbyVenueButton(
                  sake: detailSake,
                  displayName: preferredName ?? sake?.name ?? fallback.name,
                ),
              ),
            if (tasteAxes.isNotEmpty ||
                master.tasteTags.isNotEmpty ||
                master.aromaTags.isNotEmpty)
              _Section(
                title: '味わいプロフィール',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (profile != null) ...[
                      _Tags(
                        values: [
                          switch (profile.sourceType) {
                            'ai' || 'ai_estimated' => 'AI推定',
                            'official' => '公式情報',
                            _ => '参考情報',
                          },
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (tasteAxes.isNotEmpty)
                      Center(
                        child: _SakeTasteRadarChart(
                          axes: tasteAxes,
                          preferenceAxes: preferenceAxes,
                        ),
                      ),
                    if (preferenceAxes != null) ...[
                      const SizedBox(height: 14),
                      const _TasteChartLegend(),
                    ],
                    _Tags(
                      values: {
                        ...master.tasteTags,
                        ...master.aromaTags,
                      }.toList(),
                    ),
                  ],
                ),
              ),
            if (description != null && description.trim().isNotEmpty)
              _Section(
                title: 'このお酒について',
                child: Text(
                  description,
                  style: const TextStyle(
                    height: 1.75,
                    color: Color(0xFF404A56),
                  ),
                ),
              ),
            if (pairings.isNotEmpty)
              _Section(
                title: 'この食事に合うかも！',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '味わいプロフィールから選んだ、今日のひと皿です。',
                      style: TextStyle(color: Color(0xFF647184), height: 1.5),
                    ),
                    const SizedBox(height: 10),
                    for (final pairing in pairings)
                      _PairingRow(pairing: pairing),
                  ],
                ),
              ),
            if (specs.isNotEmpty)
              _Section(
                title: '基本スペック',
                child: Column(
                  children: [
                    for (final item in specs.entries)
                      _DetailRow(label: item.key, value: item.value),
                  ],
                ),
              ),
            if (master.recommendedTemperatures.isNotEmpty)
              _Section(
                title: 'おすすめの温度',
                child: _Tags(
                  values: master.recommendedTemperatures,
                  accent: true,
                ),
              ),
            if (master.variants.isNotEmpty)
              _Section(
                title: '容量と参考価格',
                child: Column(
                  children: [
                    for (final variant in master.variants)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_drink_outlined,
                              color: _orange,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                variant.volumeMl == null
                                    ? '容量未登録'
                                    : '${variant.volumeMl} ml',
                              ),
                            ),
                            Flexible(
                              child: Text(
                                _price(variant),
                                style: const TextStyle(
                                  color: _navy,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Text(
                      '価格は登録時点の参考情報です。',
                      style: TextStyle(fontSize: 11, color: Color(0xFF647184)),
                    ),
                  ],
                ),
              ),
            if (breweryName != null || overview?.brand.name != null)
              _Section(
                title: '銘柄・蔵元',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (overview?.brand.name != null)
                      Text(
                        overview!.brand.name!,
                        style: const TextStyle(
                          color: _navy,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    if (breweryName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(breweryName),
                      ),
                    if (overview?.brewery.officialUrl != null)
                      _WebLink(
                        url: overview!.brewery.officialUrl!,
                        label: '蔵元の公式サイト',
                      ),
                  ],
                ),
              ),
            if (overview?.relatedProducts.isNotEmpty ?? false)
              _Section(
                title: '同じ銘柄の日本酒',
                child: Column(
                  children: [
                    for (final product in overview!.relatedProducts.where(
                      (p) => p.sakeId > 0,
                    ))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: SizedBox(
                          width: 42,
                          height: 54,
                          child: _BottleImage(url: product.imageUrl),
                        ),
                        title: Text(product.name),
                        subtitle: product.type == null
                            ? null
                            : Text(product.type!),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => Provider<SakeScanRepository>.value(
                              value: context.read<SakeScanRepository>(),
                              child: SakeMasterDetailPage(
                                venueSake: VenueSake(
                                  sakeId: product.sakeId,
                                  name: product.name,
                                  type: product.type,
                                  primaryImageUrl: product.imageUrl,
                                  recordCount: 0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            if (master.officialUrl != null || master.sourceUrl != null)
              _WebLink(
                url: master.officialUrl ?? master.sourceUrl!,
                label: '商品情報の出典を見る',
              ),
            if (master.verifiedAt != null)
              Text(
                '${DateFormat('yyyy年M月d日').format(master.verifiedAt!)}確認',
                style: const TextStyle(color: Color(0xFF647184), fontSize: 12),
              ),
            if (master.imageSource == 'yahoo_shopping') ...[
              if (master.imageProductUrl != null)
                _WebLink(
                  url: master.imageProductUrl!,
                  label: '画像の商品をYahoo!ショッピングで見る',
                ),
              const _WebLink(
                url: 'https://developer.yahoo.co.jp/sitemap/',
                label: 'Webサービス by Yahoo! JAPAN',
              ),
            ],
            if (master.rakutenOffer != null)
              const _WebLink(
                url: 'https://developers.rakuten.com/',
                label: 'Supported by Rakuten Developers',
              ),
          ],
        ),
      ),
    );
  }
}

class _NearbyVenueButton extends StatelessWidget {
  const _NearbyVenueButton({required this.sake, required this.displayName});

  final Sake sake;
  final String displayName;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    style: OutlinedButton.styleFrom(
      foregroundColor: _navy,
      side: const BorderSide(color: _navy),
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    icon: const Icon(Icons.location_on_outlined),
    label: const Text(
      '近くで飲める場所を探す',
      style: TextStyle(fontWeight: FontWeight.w800),
    ),
    onPressed: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SakeMapPage.wrapped(
          initialSake: SakeMapSearchResult(
            sakeId: sake.sakeId,
            name: displayName,
            brewery: sake.brewery,
            type: sake.type,
            primaryImageUrl: sake.primaryImageUrl,
            thumbnailImageUrl: sake.thumbnailImageUrl,
            isMaster: true,
          ),
        ),
      ),
    ),
  );
}

class _MasterSaveButton extends StatelessWidget {
  const _MasterSaveButton({required this.sake, required this.notifier});
  final Sake sake;
  final SavedSakeNotifier? notifier;

  @override
  Widget build(BuildContext context) {
    final savedNotifier = notifier;
    if (savedNotifier == null) return const SizedBox.shrink();
    final isSaved = _findSavedSake(savedNotifier, sake) != null;
    return IconButton(
      tooltip: isSaved ? context.l10n.removeSavedSake : context.l10n.saveSake,
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
        try {
          await savedNotifier.toggleSavedSake(sake);
          if (!isSaved && context.mounted) {
            SnackBarUtils.showInfoSnackBar(
              context,
              message: context.l10n.savedToMyPage,
            );
          }
        } on SavedSakeGuestLimitReachedException {
          if (!context.mounted) return;
          await GuestLimitDialog.showSavedSakeLimit(
            context,
            maxCount: SavedSakeNotifier.guestSavedLimit,
          );
        } on SavedSakeMemberLimitReachedException {
          if (!context.mounted) return;
          SnackBarUtils.showWarningSnackBar(
            context,
            message: context.l10n.savedSakeLimit(
              SavedSakeNotifier.memberSavedLimit,
            ),
          );
        }
      },
    );
  }
}

class _MasterFavoriteButton extends StatelessWidget {
  const _MasterFavoriteButton({required this.sake, required this.notifier});
  final Sake sake;
  final FavoriteNotifier? notifier;

  @override
  Widget build(BuildContext context) {
    final favoriteNotifier = notifier;
    if (favoriteNotifier == null) return const SizedBox.shrink();
    final isFavorite = favoriteNotifier.state.myFavoriteList.any(
      (item) => item.name == sake.name && item.type == sake.type,
    );
    return IconButton(
      tooltip: context.l10n.favoriteSake,
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite ? Colors.redAccent : Colors.white,
      ),
      onPressed: () async {
        if (!isFavorite && favoriteNotifier.hasReachedGuestLimit) {
          await GuestLimitDialog.showFavoriteLimit(
            context,
            maxCount: FavoriteNotifier.guestFavoriteLimit,
          );
          return;
        }
        try {
          await favoriteNotifier.addOrRemoveFavorite(
            FavoriteSake(name: sake.name ?? '', type: sake.type),
          );
        } on FavoriteGuestLimitReachedException {
          if (!context.mounted) return;
          await GuestLimitDialog.showFavoriteLimit(
            context,
            maxCount: FavoriteNotifier.guestFavoriteLimit,
          );
        }
      },
    );
  }
}

Sake _asSake(VenueSake venueSake) => Sake(
  sakeId: venueSake.sakeId,
  name: venueSake.name,
  brewery: venueSake.brewery,
  type: venueSake.type,
  primaryImageUrl: venueSake.primaryImageUrl,
  thumbnailImageUrl: venueSake.thumbnailImageUrl,
);

class _MasterRecordCta extends StatelessWidget {
  const _MasterRecordCta({required this.sake, required this.notifier});
  final Sake sake;
  final SavedSakeNotifier? notifier;

  @override
  Widget build(BuildContext context) {
    final savedNotifier = notifier;
    if (savedNotifier == null || _isSaved(savedNotifier, sake)) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: FilledButton.icon(
        onPressed: () => _addSakeRecord(context, savedNotifier, sake),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: const Color(0xFFFFC107),
          foregroundColor: _navy,
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
        icon: const Icon(Icons.bookmark_add_outlined),
        label: const Text('このお酒を保存する'),
      ),
    );
  }
}

bool _isSaved(SavedSakeNotifier notifier, Sake sake) => notifier
    .state
    .savedSakeList
    .any((candidate) => _isSameSakeIdentity(candidate, sake));

bool _isSameSakeIdentity(Sake candidate, Sake sake) {
  if (sake.sakeId != null && candidate.sakeId == sake.sakeId) return true;
  final candidateName = _normalizedSakeName(candidate.name);
  final sakeName = _normalizedSakeName(sake.name);
  if (candidateName.isEmpty || candidateName != sakeName) return false;
  final candidateType = candidate.type?.trim();
  final sakeType = sake.type?.trim();
  return candidateType == null ||
      candidateType.isEmpty ||
      sakeType == null ||
      sakeType.isEmpty ||
      candidateType == sakeType;
}

String _normalizedSakeName(String? name) =>
    (name ?? '').replaceAll(RegExp(r'\s+'), '');

Future<void> _addSakeRecord(
  BuildContext context,
  SavedSakeNotifier notifier,
  Sake sake,
) async {
  if (notifier.hasReachedGuestLimit) {
    await GuestLimitDialog.showSavedSakeLimit(
      context,
      maxCount: SavedSakeNotifier.guestSavedLimit,
    );
    return;
  }
  if (notifier.hasReachedMemberLimit) {
    SnackBarUtils.showWarningSnackBar(
      context,
      message: context.l10n.savedSakeLimit(SavedSakeNotifier.memberSavedLimit),
    );
    return;
  }
  try {
    await notifier.toggleSavedSake(sake);
    if (!context.mounted) return;
    SnackBarUtils.showInfoSnackBar(
      context,
      message: context.l10n.savedToMyPage,
    );
  } on SavedSakeGuestLimitReachedException {
    if (!context.mounted) return;
    await GuestLimitDialog.showSavedSakeLimit(
      context,
      maxCount: SavedSakeNotifier.guestSavedLimit,
    );
  } on SavedSakeMemberLimitReachedException {
    if (!context.mounted) return;
    SnackBarUtils.showWarningSnackBar(
      context,
      message: context.l10n.savedSakeLimit(SavedSakeNotifier.memberSavedLimit),
    );
  }
}

class _PersonalRecordSection extends StatelessWidget {
  const _PersonalRecordSection({required this.sake, required this.notifier});
  final Sake sake;
  final SavedSakeNotifier? notifier;

  @override
  Widget build(BuildContext context) {
    final savedNotifier = notifier;
    if (savedNotifier == null) return const SizedBox.shrink();
    final saved = _findSavedSake(savedNotifier, sake);
    if (saved == null) return const SizedBox.shrink();
    final Sake record = saved;

    final location = record.drinkingPlace?.displayName ?? record.place;
    final photoCount = (record.imagePaths ?? const <String>[]).length;
    final hasImpression = record.impression?.trim().isNotEmpty == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _SectionHeading(title: 'あなたの記録')),
            TextButton.icon(
              onPressed: () => _showRecordEditorSheet(
                context,
                notifier: savedNotifier,
                sake: record,
              ),
              icon: const Icon(Icons.edit_outlined, size: 17),
              label: const Text('編集'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Material(
          color: const Color(0xFFF8FAFD),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _showRecordEditorSheet(
              context,
              notifier: savedNotifier,
              sake: record,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.auto_stories_outlined, color: _navy),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location?.trim().isNotEmpty == true
                              ? location!
                              : '飲んだ場所・買った場所は未記録',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _navy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '写真 $photoCount枚 ・ ${hasImpression ? '感想あり' : '感想未入力'}',
                          style: const TextStyle(
                            color: Color(0xFF647184),
                            fontSize: 12,
                          ),
                        ),
                        if (hasImpression) ...[
                          const SizedBox(height: 5),
                          Text(
                            record.impression!.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF46566A),
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Color(0xFF647184)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _showRecordEditorSheet(
  BuildContext context, {
  required SavedSakeNotifier notifier,
  required Sake sake,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheetContext) => DraggableScrollableSheet(
      initialChildSize: .86,
      minChildSize: .55,
      maxChildSize: .96,
      expand: false,
      builder: (context, scrollController) => SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD3DAE4),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'あなたの記録を編集',
                      style: TextStyle(
                        color: _navy,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '閉じる',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(sheetContext).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5EAF0)),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: _InlineRecordEditor(notifier: notifier, sake: sake),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  if (saved == true && context.mounted) {
    SnackBarUtils.showInfoSnackBar(context, message: '記録を保存しました。');
  }
}

Sake? _findSavedSake(SavedSakeNotifier? notifier, Sake sake) {
  if (notifier == null) return null;
  for (final candidate in notifier.state.savedSakeList) {
    if (_isSameSakeIdentity(candidate, sake)) return candidate;
  }
  return null;
}

/// 保存したボトル・思い出写真を優先し、1枚もない場合だけ商品画像を使う。
List<String> detailImagePaths({
  required Sake? personalRecord,
  required Sake? overviewSake,
  required VenueSake fallback,
}) {
  final paths = <String>[];
  void add(String? value) {
    final path = value?.trim();
    if (path == null || path.isEmpty || paths.contains(path)) return;
    paths.add(path);
  }

  for (final path in personalRecord?.imagePaths ?? const <String>[]) {
    add(path);
  }
  if (paths.isEmpty) {
    add(overviewSake?.primaryImageUrl);
    if (paths.isEmpty) add(fallback.primaryImageUrl);
  }
  return paths;
}

/// 味わいプロフィールの近さを、表示用の30〜100%に換算する。
///
/// 線形換算では各軸が少し近いだけで90%台に集中するため、
/// わずかな差もマッチ度に反映するカーブを適用する。
int calculateTastePreferenceMatchPercent({
  required List<double> sakeValues,
  required List<double> preferenceValues,
}) {
  if (sakeValues.isEmpty || sakeValues.length != preferenceValues.length) {
    return 30;
  }
  final difference =
      List<double>.generate(
        sakeValues.length,
        (index) =>
            (sakeValues[index].clamp(0, 1).toDouble() -
                    preferenceValues[index].clamp(0, 1).toDouble())
                .abs(),
      ).reduce((sum, value) => sum + value) /
      sakeValues.length;
  final similarity = 1 - difference;
  return (30 + math.pow(similarity, 3.5) * 70).round().clamp(30, 100).toInt();
}

class _SakeScoreSummary extends StatelessWidget {
  const _SakeScoreSummary({
    required this.matchPercent,
    required this.averageRating,
    required this.reviewCount,
  });

  final int? matchPercent;
  final double? averageRating;
  final int reviewCount;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (matchPercent != null)
        Expanded(child: _PreferenceMatchSection(percent: matchPercent!)),
      if (matchPercent != null && averageRating != null)
        const SizedBox(width: 8),
      if (averageRating != null)
        Expanded(
          child: Semantics(
            label: 'みんなの評価 ${averageRating!.toStringAsFixed(1)}、$reviewCount件',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'みんなの評価',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFC247),
                        size: 22,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        averageRating!.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '($reviewCount件)',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}

class _PreferenceMatchSection extends StatefulWidget {
  const _PreferenceMatchSection({required this.percent});

  final int percent;

  @override
  State<_PreferenceMatchSection> createState() =>
      _PreferenceMatchSectionState();
}

class _ProfileAnalysisProgress extends StatelessWidget {
  const _ProfileAnalysisProgress({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const LinearProgressIndicator(
            minHeight: 5,
            color: Color(0xFFFFB347),
            backgroundColor: Color(0x336D8CB0),
            borderRadius: BorderRadius.all(Radius.circular(99)),
          ),
        ],
      ),
    ),
  );
}

class _LoginRecommendationPrompt extends StatelessWidget {
  const _LoginRecommendationPrompt();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7ED),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFFFD8B0)),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.auto_awesome_outlined, color: _orange),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ログインすると、あなたにおすすめかどうかが分かります！',
                style: TextStyle(color: _navy, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 4),
              Text(
                '好みの傾向とこのお酒を比べて、ぴったり度を表示します。',
                style: TextStyle(
                  color: Color(0xFF647184),
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PreferenceMatchSectionState extends State<_PreferenceMatchSection> {
  ScrollPosition? _scrollPosition;
  var _hasEnteredViewport = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextPosition = Scrollable.maybeOf(context)?.position;
    if (identical(_scrollPosition, nextPosition)) return;
    _scrollPosition?.removeListener(_checkViewport);
    _scrollPosition = nextPosition;
    _scrollPosition?.addListener(_checkViewport);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkViewport());
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_checkViewport);
    super.dispose();
  }

  void _checkViewport() {
    if (!mounted || _hasEnteredViewport) return;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;
    final top = renderObject.localToGlobal(Offset.zero).dy;
    final bottom = top + renderObject.size.height;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    if (top >= viewportHeight * 0.9 || bottom <= 0) return;
    setState(() => _hasEnteredViewport = true);
  }

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: const Key('taste-preference-match'),
    duration: const Duration(milliseconds: 900),
    curve: Curves.easeOutCubic,
    tween: Tween<double>(
      end: _hasEnteredViewport ? widget.percent.toDouble() : 0,
    ),
    builder: (context, value, _) {
      final shownPercent = value.round();
      return Semantics(
        label: 'あなたの好みマッチ度 $shownPercent%',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'あなたの好みマッチ度',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '$shownPercent%',
                    style: const TextStyle(
                      color: Color(0xFFFFB347),
                      fontSize: 20,
                      height: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              LayoutBuilder(
                builder: (context, constraints) => Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: constraints.maxWidth * value / 100,
                    height: 8,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFFA13C), Color(0xFFE95C9A)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(width: 3, height: 18, color: _orange),
      const SizedBox(width: 10),
      Text(
        title,
        style: const TextStyle(
          color: _navy,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
    ],
  );
}

class _InlineRecordEditor extends StatefulWidget {
  const _InlineRecordEditor({required this.notifier, required this.sake});
  final SavedSakeNotifier notifier;
  final Sake sake;

  @override
  State<_InlineRecordEditor> createState() => _InlineRecordEditorState();
}

class _InlineRecordEditorState extends State<_InlineRecordEditor> {
  late final TextEditingController _impressionController;
  late final TextEditingController _placeController;
  late Set<String> _tags;
  DrinkingPlace? _selectedPlace;
  bool _isSaving = false;
  String? _saveError;
  bool _isAddingImage = false;

  @override
  void initState() {
    super.initState();
    _impressionController = TextEditingController(
      text: widget.sake.impression ?? '',
    );
    _placeController = TextEditingController(
      text: widget.sake.drinkingPlace?.displayName ?? widget.sake.place ?? '',
    );
    _selectedPlace = widget.sake.drinkingPlace;
    _tags = {...(widget.sake.userTags ?? const <String>[])};
  }

  @override
  void dispose() {
    _impressionController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    final isLoggedIn = context.read<AuthState>().user != null;
    try {
      final place = _placeController.text.trim();
      var updated = widget.sake.copyWith(
        impression: _impressionController.text.trim(),
        place: place.isEmpty ? null : place,
        drinkingPlace: _selectedPlace,
        isPublic: false,
        userTags: _tags.toList(growable: false),
      );
      await widget.notifier.updateSavedSake(updated);
      final savedId = updated.savedId;
      if (isLoggedIn && savedId != null && savedId.isNotEmpty) {
        final synced = await widget.notifier.syncSavedSakeToServer(
          savedId,
          force: true,
        );
        if (synced == null) throw StateError('保存酒をサーバーへ同期できませんでした。');
        updated = synced;
        final selectedPlace = _selectedPlace;
        if (selectedPlace != null && selectedPlace.providerPlaceId != null) {
          if (!mounted) return;
          final result = await context.read<PlaceMapRepository>().savePlace(
            savedId: savedId,
            place: selectedPlace,
          );
          if (result == null) throw StateError('場所を地図へ登録できませんでした。');
          updated = updated.copyWith(
            place: result.drinkingPlace.displayName,
            drinkingPlace: result.drinkingPlace,
          );
          await widget.notifier.updateSavedSake(updated);
        }
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saveError = error is PlaceMapException
              ? error.message
              : '保存に失敗しました。通信状態を確認してもう一度お試しください。';
        });
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _selectPlace() async {
    FocusScope.of(context).unfocus();
    final place = await PlacePickerSheet.show(
      context,
      initialPlace: _placeController.text.trim(),
    );
    if (!mounted || place == null || place.displayName.trim().isEmpty) return;
    setState(() {
      _selectedPlace = place;
      _placeController.text = place.displayName.trim();
    });
  }

  Future<void> _showImageSourceSheet() async {
    if ((widget.sake.imagePaths ?? const <String>[]).length >= 3) {
      SnackBarUtils.showWarningSnackBar(context, message: '写真は3枚まで追加できます。');
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera, color: _navy),
              title: const Text('カメラで撮る'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: _navy),
              title: const Text('写真ライブラリから選ぶ'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (!mounted || source == null) return;
    await _pickMemoryImage(source);
  }

  Future<void> _pickMemoryImage(ImageSource source) async {
    final savedId = widget.sake.savedId;
    if (savedId == null || savedId.isEmpty) {
      SnackBarUtils.showWarningSnackBar(context, message: '先にこのお酒を記録してください。');
      return;
    }
    setState(() => _isAddingImage = true);
    try {
      final picked = await CustomImagePicker.pickImage(source: source);
      if (!mounted || picked == null) return;
      final cropped = await ImageCropperService.cropAndRotateImage(picked.path);
      final path = await ImageCropperService.saveImagePermanently(
        cropped ?? picked,
        'saved_sake',
      );
      if (!mounted || path == null) return;
      final updated = await widget.notifier.addImageToSavedSake(
        savedId: savedId,
        localPath: path,
      );
      if (!mounted) return;
      if (updated == null) {
        SnackBarUtils.showWarningSnackBar(context, message: '写真を追加できませんでした。');
      }
    } finally {
      if (mounted) setState(() => _isAddingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (_saveError != null) ...[
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _saveError!,
            style: const TextStyle(color: Color(0xFFB42318), fontSize: 13),
          ),
        ),
      ],
      const Text(
        '飲んだ場所・買った場所',
        style: TextStyle(color: _navy, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      Material(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: _selectPlace,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.near_me_outlined, color: _orange),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _placeController.text.trim().isEmpty
                        ? '現在地・店舗名から選ぶ'
                        : _placeController.text.trim(),
                    style: TextStyle(
                      color: _placeController.text.trim().isEmpty
                          ? const Color(0xFF647184)
                          : _navy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF647184)),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 18),
      const Text(
        'タグ',
        style: TextStyle(color: _navy, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: sake_master.Sake.userMemoTags
            .map(
              (tag) => FilterChip(
                label: Text(tag),
                selected: _tags.contains(tag),
                onSelected: (selected) => setState(() {
                  selected ? _tags.add(tag) : _tags.remove(tag);
                }),
              ),
            )
            .toList(growable: false),
      ),
      const Text(
        '思い出をのこそう',
        style: TextStyle(
          color: _navy,
          fontWeight: FontWeight.w700,
          fontSize: 17,
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          for (var index = 0; index < 3; index++) ...[
            Expanded(
              child: _MemoryPhotoTile(
                path:
                    index < (widget.sake.imagePaths ?? const <String>[]).length
                    ? widget.sake.imagePaths![index]
                    : null,
                isPrimary:
                    index ==
                    (widget.sake.imagePaths ?? const <String>[]).length,
                isAdding: _isAddingImage,
                onAdd: _showImageSourceSheet,
              ),
            ),
            if (index < 2) const SizedBox(width: 8),
          ],
        ],
      ),
      const SizedBox(height: 20),
      const Text(
        '感想メモ',
        style: TextStyle(color: _navy, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _impressionController,
        maxLength: 200,
        maxLines: 4,
        textAlign: TextAlign.start,
        style: const TextStyle(color: _navy, height: 1.5),
        decoration: InputDecoration(
          hintText: '香りや味、食事との相性を残す',
          hintStyle: const TextStyle(color: Color(0xFF8B96A6)),
          filled: true,
          fillColor: const Color(0xFFF7F8FA),
          contentPadding: const EdgeInsets.all(14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: _isSaving ? null : _save,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: _orange,
        ),
        child: Text(_isSaving ? '保存中…' : '記録を保存'),
      ),
    ],
  );
}

class _MemoryPhotoTile extends StatelessWidget {
  const _MemoryPhotoTile({
    required this.path,
    required this.isPrimary,
    required this.isAdding,
    required this.onAdd,
  });

  final String? path;
  final bool isPrimary;
  final bool isAdding;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);
    if (path == null) {
      final accent = isPrimary ? _orange : const Color(0xFF9AA5B5);
      return InkWell(
        onTap: isAdding ? null : onAdd,
        borderRadius: borderRadius,
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              color: const Color(0xFFF7F8FA),
              border: Border.all(
                color: isPrimary
                    ? const Color(0xFFFFC58F)
                    : const Color(0xFFDDE3EA),
                width: 1.5,
              ),
            ),
            child: Center(
              child: isAdding && isPrimary
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          color: accent,
                          size: 28,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '追加',
                          style: TextStyle(color: accent, fontSize: 13),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      );
    }

    final image = path!.startsWith('http://') || path!.startsWith('https://')
        ? Image.network(
            path!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const _MemoryImageError(),
          )
        : Image.file(
            File(path!),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const _MemoryImageError(),
          );
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            image,
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.zoom_in, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoryImageError extends StatelessWidget {
  const _MemoryImageError();

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFFF0F2F5),
    alignment: Alignment.center,
    child: const Icon(Icons.broken_image_outlined, color: Color(0xFF8B96A6)),
  );
}

class _CommunityReviewsSection extends StatelessWidget {
  const _CommunityReviewsSection({
    required this.community,
    required this.onReview,
    required this.onReportReview,
  });

  final SakeCommunitySummary community;
  final ValueChanged<SakeCommunityReview?> onReview;
  final ValueChanged<int> onReportReview;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFFFB02E)),
          const SizedBox(width: 5),
          Text(
            community.averageRating == null
                ? 'まだ評価はありません'
                : '${community.averageRating!.toStringAsFixed(1)} (${community.reviewCount}件)',
            style: const TextStyle(color: _navy, fontWeight: FontWeight.w800),
          ),
          const Spacer(),
          FilledButton.icon(
            key: const Key('sake-community-review-button'),
            onPressed: () => onReview(community.myReview),
            icon: Icon(
              community.myReview == null ? Icons.add : Icons.edit_outlined,
              size: 18,
            ),
            label: Text(community.myReview == null ? 'このお酒を評価' : '自分の評価を編集'),
            style: FilledButton.styleFrom(backgroundColor: _orange),
          ),
        ],
      ),
      if (community.reviews.isNotEmpty) ...[
        const SizedBox(height: 14),
        SizedBox(
          height: 270,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: community.reviews.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final review = community.reviews[index];
              return Container(
                width: 280,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE6EAF0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (review.imageUrl != null)
                      SizedBox(
                        height: 92,
                        width: double.infinity,
                        child: _DetailSakeImage(path: review.imageUrl),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 13,
                                backgroundColor: const Color(0xFFDDE6F0),
                                backgroundImage: review.iconUrl == null
                                    ? null
                                    : NetworkImage(review.iconUrl!),
                                child: review.iconUrl == null
                                    ? const Icon(
                                        Icons.person,
                                        size: 15,
                                        color: _navy,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  review.username,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.star_rounded,
                                size: 17,
                                color: Color(0xFFFFB02E),
                              ),
                              Text(
                                review.overallRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (!review.isOwner)
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  tooltip: 'この評価を報告',
                                  onPressed: () =>
                                      onReportReview(review.reviewId),
                                  icon: const Icon(
                                    Icons.flag_outlined,
                                    size: 18,
                                    color: Color(0xFF697386),
                                  ),
                                ),
                            ],
                          ),
                          if (review.comment != null) ...[
                            const SizedBox(height: 7),
                            Text(
                              review.comment!,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF404A56),
                                height: 1.4,
                              ),
                            ),
                          ],
                          if (review.tasteRatings.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 5,
                              runSpacing: 5,
                              children: review.tasteRatings.entries
                                  .map((entry) {
                                    const labels = <String, String>{
                                      'fruity': 'フルーティ',
                                      'sweetness': '甘み',
                                      'acidity': '酸味',
                                      'umami': 'コク',
                                      'kire': 'キレ',
                                      'spiciness': '辛さ',
                                    };
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFEEE0),
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                      child: Text(
                                        '${labels[entry.key] ?? entry.key} ${entry.value.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          color: _navy,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    );
                                  })
                                  .toList(growable: false),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ],
  );
}

class _CommunityReviewDraft {
  const _CommunityReviewDraft({
    required this.overallRating,
    required this.tasteRatings,
    this.comment,
    this.delete = false,
  });
  final int overallRating;
  final Map<String, int> tasteRatings;
  final String? comment;
  final bool delete;
}

class _CommunityReviewEditor extends StatefulWidget {
  const _CommunityReviewEditor({this.initial});
  final SakeCommunityReview? initial;

  @override
  State<_CommunityReviewEditor> createState() => _CommunityReviewEditorState();
}

class _CommunityReviewEditorState extends State<_CommunityReviewEditor> {
  static const axes = <(String, String)>[
    ('fruity', 'フルーティ'),
    ('sweetness', '甘み'),
    ('acidity', '酸味'),
    ('umami', 'コク'),
    ('kire', 'キレ'),
    ('spiciness', '辛さ'),
  ];
  late int overall;
  late Map<String, int> tastes;
  late final TextEditingController comment;

  @override
  void initState() {
    super.initState();
    overall = widget.initial?.overallRating.round() ?? 3;
    tastes = {
      for (final axis in axes)
        axis.$1: widget.initial?.tasteRatings[axis.$1]?.round() ?? 3,
    };
    comment = TextEditingController(text: widget.initial?.comment ?? '');
  }

  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'このお酒を評価',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _navy,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '評価・味わい・コメントは表示名とアイコン付きで公開されます。',
              style: TextStyle(color: Color(0xFF697386), fontSize: 12),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => IconButton(
                  onPressed: () => setState(() => overall = index + 1),
                  icon: Icon(
                    index < overall
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: const Color(0xFFFFB02E),
                    size: 34,
                  ),
                ),
              ),
            ),
            for (final axis in axes)
              Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      axis.$2,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: tastes[axis.$1]!.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: '${tastes[axis.$1]}',
                      activeColor: _orange,
                      onChanged: (value) =>
                          setState(() => tastes[axis.$1] = value.round()),
                    ),
                  ),
                  SizedBox(width: 16, child: Text('${tastes[axis.$1]}')),
                ],
              ),
            TextField(
              controller: comment,
              maxLength: 200,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'みんなに公開する感想（任意）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _orange,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => Navigator.pop(
                context,
                _CommunityReviewDraft(
                  overallRating: overall,
                  tasteRatings: Map<String, int>.from(tastes),
                  comment: comment.text.trim().isEmpty
                      ? null
                      : comment.text.trim(),
                ),
              ),
              child: const Text('公開して保存'),
            ),
            if (widget.initial != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(
                  context,
                  const _CommunityReviewDraft(
                    overallRating: 1,
                    tasteRatings: <String, int>{},
                    delete: true,
                  ),
                ),
                child: const Text(
                  '公開評価を削除',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.child, this.title, this.topPadding = 24});
  final Widget child;
  final String? title;
  final double topPadding;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: topPadding),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) ...[
          Row(
            children: [
              Container(width: 3, height: 18, color: _orange),
              const SizedBox(width: 10),
              Text(
                title!,
                style: const TextStyle(
                  color: _navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
        ],
        child,
        const Padding(
          padding: EdgeInsets.only(top: 24),
          child: Divider(height: 1, color: Color(0xFFE5EAF0)),
        ),
      ],
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 96,
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, color: Color(0xFF647184)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      const Divider(height: 1, color: Color(0xFFE5EAF0)),
    ],
  );
}

class _ShopPriceTitle extends StatelessWidget {
  const _ShopPriceTitle();

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFF111315),
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
    child: const Row(
      children: [
        Icon(Icons.shopping_bag_outlined, color: Color(0xFFFFB347), size: 18),
        SizedBox(width: 8),
        Text(
          'このお酒を買う',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        Spacer(),
        Text('参考価格', style: TextStyle(color: Color(0xFF9AA4B2), fontSize: 11)),
      ],
    ),
  );
}

class _ShopPriceHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _ShopPriceHeaderDelegate({
    this.yahooPrice,
    this.yahooCurrency,
    this.yahooProductUrl,
    this.rakutenOffer,
  });

  final double? yahooPrice;
  final String? yahooCurrency;
  final String? yahooProductUrl;
  final SakeShopOffer? rakutenOffer;

  @override
  double get minExtent => 62;

  @override
  double get maxExtent => 62;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => _ShopPriceBar(
    yahooPrice: yahooPrice,
    yahooCurrency: yahooCurrency,
    yahooProductUrl: yahooProductUrl,
    rakutenOffer: rakutenOffer,
  );

  @override
  bool shouldRebuild(covariant _ShopPriceHeaderDelegate oldDelegate) =>
      yahooPrice != oldDelegate.yahooPrice ||
      yahooCurrency != oldDelegate.yahooCurrency ||
      yahooProductUrl != oldDelegate.yahooProductUrl ||
      rakutenOffer != oldDelegate.rakutenOffer;
}

class _ShopPriceBar extends StatelessWidget {
  const _ShopPriceBar({
    this.yahooPrice,
    this.yahooCurrency,
    this.yahooProductUrl,
    this.rakutenOffer,
  });

  final double? yahooPrice;
  final String? yahooCurrency;
  final String? yahooProductUrl;
  final SakeShopOffer? rakutenOffer;

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFF111315),
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
    child: Row(
      children: [
        const Expanded(
          child: _ShopPrice(name: 'Amazon', price: '—'),
        ),
        const _ShopPriceDivider(),
        Expanded(
          child: _ShopPrice(
            name: '楽天市場',
            price: _formatShopPrice(
              rakutenOffer?.price,
              rakutenOffer?.currency,
            ),
            url: rakutenOffer?.affiliateUrl,
          ),
        ),
        const _ShopPriceDivider(),
        Expanded(
          child: _ShopPrice(
            name: 'Yahoo!',
            price: _formatShopPrice(yahooPrice, yahooCurrency),
            url: yahooProductUrl,
          ),
        ),
      ],
    ),
  );
}

String _formatShopPrice(double? price, String? currency) {
  if (price == null) return '—';
  final prefix = currency == null || currency == 'JPY' ? '¥' : '$currency ';
  return '$prefix${NumberFormat('#,##0').format(price)}';
}

class _ShopPrice extends StatelessWidget {
  const _ShopPrice({required this.name, required this.price, this.url});

  final String name;
  final String price;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFC2CAD4),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          price,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            height: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
    final uri = Uri.tryParse(url ?? '');
    if (uri == null || !['https', 'http'].contains(uri.scheme)) return content;
    return InkWell(
      key: Key('shop-price-link-$name'),
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        try {
          final opened = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          if (opened || !context.mounted) return;
        } catch (_) {
          if (!context.mounted) return;
        }
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('リンクを開けませんでした。')));
        }
      },
      child: content,
    );
  }
}

class _ShopPriceDivider extends StatelessWidget {
  const _ShopPriceDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 34, color: const Color(0xFF30363D));
}

class _Tags extends StatelessWidget {
  const _Tags({required this.values, this.accent = false});
  final List<String> values;
  final bool accent;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: values
        .where((v) => v.trim().isNotEmpty)
        .map(
          (value) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: accent ? const Color(0xFFFFEEE1) : const Color(0xFFF0F3F7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: accent ? _orange : _navy,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        )
        .toList(),
  );
}

class _BottleImage extends StatelessWidget {
  const _BottleImage({this.url});
  final String? url;
  @override
  Widget build(BuildContext context) {
    Widget placeholder() => Image.asset(
      'assets/images/sake_placeholder.png',
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.wine_bar_outlined, color: _navy),
    );
    return url == null || url!.trim().isEmpty
        ? placeholder()
        : Image.network(
            url!,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => placeholder(),
          );
  }
}

class _DetailSakeImage extends StatelessWidget {
  const _DetailSakeImage({this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    Widget placeholder() => Image.asset(
      'assets/images/sake_placeholder.png',
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.wine_bar_outlined, color: _navy),
    );
    final value = path?.trim();
    if (value == null || value.isEmpty) return placeholder();
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return Image.network(
        value,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => placeholder(),
      );
    }
    return Image.file(
      File(value),
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => placeholder(),
    );
  }
}

class _WebLink extends StatelessWidget {
  const _WebLink({required this.url, required this.label});
  final String url;
  final String label;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      icon: const Icon(Icons.open_in_new, size: 16),
      label: Text(label),
      onPressed: () async {
        final uri = Uri.tryParse(url);
        if (uri == null || !['https', 'http'].contains(uri.scheme)) return;
        try {
          final opened = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          if (opened || !context.mounted) return;
        } catch (_) {
          if (!context.mounted) return;
        }
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('リンクを開けませんでした。')));
        }
      },
    ),
  );
}

class _TasteAxis {
  const _TasteAxis(this.label, this.value);

  final String label;
  final double value;
}

class _TasteChartLegend extends StatelessWidget {
  const _TasteChartLegend();

  @override
  Widget build(BuildContext context) => const Wrap(
    spacing: 16,
    runSpacing: 8,
    children: [
      _TasteChartLegendItem(
        colors: [Color(0xFFFFA13C), Color(0xFFE95C9A)],
        label: '橙・紫：このお酒',
      ),
      _TasteChartLegendItem(
        colors: [Color(0xFF2E8BFF), Color(0xFF65C7FF)],
        label: '青：あなたの好きな傾向',
      ),
    ],
  );
}

class _TasteChartLegendItem extends StatelessWidget {
  const _TasteChartLegendItem({required this.colors, required this.label});

  final List<Color> colors;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 22,
        height: 8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          gradient: LinearGradient(colors: colors),
        ),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: const TextStyle(color: Color(0xFF647184), fontSize: 12),
      ),
    ],
  );
}

class _SakeTasteRadarChart extends StatelessWidget {
  const _SakeTasteRadarChart({required this.axes, this.preferenceAxes});

  final List<_TasteAxis> axes;
  final List<_TasteAxis>? preferenceAxes;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 700),
    curve: Curves.easeOutCubic,
    builder: (context, progress, _) => LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, 248.0);
        final radius = size * .31;
        return SizedBox(
          key: const Key('sake-taste-radar-chart'),
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(size),
                painter: _SakeTasteRadarPainter(
                  axes: axes,
                  preferenceAxes: preferenceAxes,
                  radius: radius,
                  progress: progress,
                ),
              ),
              for (var index = 0; index < axes.length; index++)
                _RadarLabel(
                  axis: axes[index],
                  index: index,
                  total: axes.length,
                  size: size,
                  radius: radius,
                ),
            ],
          ),
        );
      },
    ),
  );
}

class _RadarLabel extends StatelessWidget {
  const _RadarLabel({
    required this.axis,
    required this.index,
    required this.total,
    required this.size,
    required this.radius,
  });

  final _TasteAxis axis;
  final int index;
  final int total;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final angle = -math.pi / 2 + (2 * math.pi * index) / total;
    final labelRadius = radius + 34;
    const labelWidth = 62.0;
    final left = (size / 2 + math.cos(angle) * labelRadius - labelWidth / 2)
        .clamp(0.0, size - labelWidth);
    final top = (size / 2 + math.sin(angle) * labelRadius - 14).clamp(
      0.0,
      size - 28,
    );
    return Positioned(
      left: left,
      top: top,
      width: labelWidth,
      child: Text(
        axis.label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _navy,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SakeTasteRadarPainter extends CustomPainter {
  const _SakeTasteRadarPainter({
    required this.axes,
    required this.preferenceAxes,
    required this.radius,
    required this.progress,
  });

  final List<_TasteAxis> axes;
  final List<_TasteAxis>? preferenceAxes;
  final double radius;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final angleStep = 2 * math.pi / axes.length;
    final gridPaint = Paint()
      ..color = const Color(0xFFDCE5EF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = const Color(0xFFE8EDF4)
      ..strokeWidth = 1;

    for (var level = 1; level <= 4; level++) {
      canvas.drawPath(
        _polygonPath(
          center: center,
          count: axes.length,
          radius: radius * level / 4,
        ),
        gridPaint,
      );
    }
    for (var index = 0; index < axes.length; index++) {
      canvas.drawLine(
        center,
        _point(center, radius, index, angleStep),
        axisPaint,
      );
    }

    final bounds = Rect.fromCircle(center: center, radius: radius);
    final userAxes = preferenceAxes;
    if (userAxes != null && userAxes.length == axes.length) {
      final userPath = _tastePath(
        center: center,
        axes: userAxes,
        radius: radius,
        angleStep: angleStep,
      );
      final userFillPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF65C7FF).withValues(alpha: .42),
            const Color(0xFF2E8BFF).withValues(alpha: .16),
          ],
        ).createShader(bounds);
      final userStrokePaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF65C7FF), Color(0xFF2E8BFF)],
        ).createShader(bounds)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4;
      canvas.drawPath(userPath, userFillPaint);
      canvas.drawPath(userPath, userStrokePaint);
    }

    final path = _tastePath(
      center: center,
      axes: axes,
      radius: radius,
      angleStep: angleStep,
    );
    final fillPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD96A).withValues(alpha: .72),
          const Color(0xFFFF8B5A).withValues(alpha: .38),
          const Color(0xFFBE6DE0).withValues(alpha: .24),
        ],
      ).createShader(bounds);
    final strokePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFA13C), Color(0xFFE95C9A), Color(0xFF8D6CDB)],
      ).createShader(bounds)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  Path _tastePath({
    required Offset center,
    required List<_TasteAxis> axes,
    required double radius,
    required double angleStep,
  }) {
    final path = Path();
    for (var index = 0; index < axes.length; index++) {
      final value = axes[index].value.clamp(0.0, 1.0) * progress;
      final point = _point(center, radius * value, index, angleStep);
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  Path _polygonPath({
    required Offset center,
    required int count,
    required double radius,
  }) {
    final path = Path();
    final angleStep = 2 * math.pi / count;
    for (var index = 0; index < count; index++) {
      final point = _point(center, radius, index, angleStep);
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  Offset _point(Offset center, double radius, int index, double angleStep) {
    final angle = -math.pi / 2 + angleStep * index;
    return Offset(
      center.dx + math.cos(angle) * radius,
      center.dy + math.sin(angle) * radius,
    );
  }

  @override
  bool shouldRepaint(covariant _SakeTasteRadarPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.axes != axes ||
      oldDelegate.preferenceAxes != preferenceAxes;
}

class _Pairing {
  const _Pairing({
    required this.icon,
    required this.title,
    required this.reason,
  });

  final IconData icon;
  final String title;
  final String reason;
}

class _PairingRow extends StatelessWidget {
  const _PairingRow({required this.pairing});

  final _Pairing pairing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(pairing.icon, color: _orange, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pairing.title,
                style: const TextStyle(
                  color: _navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                pairing.reason,
                style: const TextStyle(color: Color(0xFF647184), height: 1.45),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

List<_Pairing> _pairingsFor({
  required SakeTasteProfileDetails? profile,
  required String? category,
  required Iterable<String> styles,
}) {
  if (profile == null) return const <_Pairing>[];

  final styleText = styles.join(' ');
  final pairings = <_Pairing>[];
  void add(_Pairing pairing) {
    if (pairings.every((item) => item.title != pairing.title)) {
      pairings.add(pairing);
    }
  }

  if (profile.kire >= .62 || profile.dryness >= .62) {
    add(
      const _Pairing(
        icon: Icons.set_meal_outlined,
        title: 'お刺身・白身魚の塩焼き',
        reason: 'すっきりしたキレが、魚の繊細な旨みを引き立てます。',
      ),
    );
    add(
      const _Pairing(
        icon: Icons.outdoor_grill_outlined,
        title: '焼き鳥（塩）',
        reason: '香ばしさを受け止めながら、後味を軽やかに整えます。',
      ),
    );
  }
  if (profile.umami >= .62 || (profile.body ?? 0) >= .62) {
    add(
      const _Pairing(
        icon: Icons.restaurant_outlined,
        title: 'ぶり大根・煮付け',
        reason: 'ふくらみのある旨みが、だしの効いた味付けによく合います。',
      ),
    );
    add(
      const _Pairing(
        icon: Icons.rice_bowl_outlined,
        title: 'きのこの炊き込みご飯',
        reason: '米由来のコクを、きのこの香りと一緒に楽しめます。',
      ),
    );
  }
  if (profile.fruity >= .62 || (profile.aroma ?? 0) >= .62) {
    add(
      const _Pairing(
        icon: Icons.spa_outlined,
        title: '生ハムとクリームチーズ',
        reason: '華やかな香りに、ほどよい塩味とミルキーなコクが寄り添います。',
      ),
    );
  }
  if (profile.sweetness >= .62) {
    add(
      const _Pairing(
        icon: Icons.lunch_dining_outlined,
        title: '鶏の照り焼き',
        reason: '甘辛いタレと重なり、やわらかな余韻を楽しめます。',
      ),
    );
  }
  if (profile.acidity >= .62 || styleText.contains('生')) {
    add(
      const _Pairing(
        icon: Icons.local_fire_department_outlined,
        title: '天ぷら',
        reason: '爽やかな酸味が、揚げ物の香ばしさを軽快にまとめます。',
      ),
    );
  }
  if (pairings.isEmpty) {
    add(
      _Pairing(
        icon: Icons.rice_bowl_outlined,
        title: category == null ? '和食の定食' : '$categoryのやさしい和食',
        reason: '主張しすぎない味わいなので、季節の小鉢やご飯と気軽にどうぞ。',
      ),
    );
  }
  return pairings.take(3).toList(growable: false);
}

String _number(double value) => value == value.truncateToDouble()
    ? value.toStringAsFixed(0)
    : value.toString();

String _price(SakeProductVariant variant) {
  if (variant.suggestedPrice == null) return '価格未登録';
  final currency = variant.currency ?? 'JPY';
  final amount = NumberFormat.currency(
    locale: 'ja_JP',
    name: currency,
    symbol: currency == 'JPY' ? '¥' : currency,
  ).format(variant.suggestedPrice);
  return '$amount${variant.taxIncluded == true
      ? '（税込）'
      : variant.taxIncluded == false
      ? '（税別）'
      : ''}';
}
