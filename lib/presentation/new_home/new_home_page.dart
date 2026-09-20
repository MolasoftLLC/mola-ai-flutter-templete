import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../common/localization/localization_extensions.dart';
import '../../common/utils/sake_image_utils.dart';
import '../../common/utils/snack_bar_utils.dart';
import '../../domain/eintities/app_content.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/eintities/sake_label_scan.dart';
import '../../domain/notifier/favorite/favorite_notifier.dart';
import '../../domain/notifier/my_page/my_page_notifier.dart';
import '../../domain/notifier/saved_sake/saved_sake_notifier.dart';
import '../../domain/repository/mola_api_repository.dart';
import '../../domain/repository/place_map_repository.dart';
import '../../domain/repository/sake_scan_repository.dart';
import '../app_page_notifier.dart';
import '../common/widgets/guest_limit_dialog.dart';
import '../main_search/main_search_page.dart';
import '../my_page/my_page.dart';
import '../my_page/saved_sake_detail_page.dart';
import '../sake_scan/sake_scan_entry.dart';
import '../sake_map/sake_master_detail_page.dart';
import '../timeline/envy_result.dart';
import '../timeline/timeline_page_notifier.dart';
import 'new_home_page_notifier.dart';
import 'recent_sake_list_page.dart';

const _brandColor = Color(0xFF143861);
const _scanColor = Color(0xFFFF7A1A);
const _bodyTextColor = Color(0xFF404040);
const _sakeCardRailHeight = 275.0;

/// 一覧カードの味わいプロフィールをレール単位でまとめて取得する。
/// 詳細APIを使わないため、AI・EC検索・コミュニティ取得は発生しない。
class SakeMatchProfileCache {
  final Map<String, Future<Map<int, SakeTasteProfileDetails>>> _futures = {};
  Future<Map<int, SakeTasteProfileDetails>> fetch(
    Iterable<int> sakeIds,
    Future<Map<int, SakeTasteProfileDetails>> Function(List<int>) loader,
  ) {
    final ids = sakeIds.where((id) => id > 0).toSet().toList()..sort();
    if (ids.isEmpty) return Future.value(<int, SakeTasteProfileDetails>{});
    return _futures.putIfAbsent(ids.join(','), () => loader(ids));
  }

  void clear() => _futures.clear();
}

class NewHomePage extends StatefulWidget {
  const NewHomePage._();

  static Widget wrapped() {
    return StateNotifierProvider<NewHomePageNotifier, TimelinePageState>(
      create: (_) => NewHomePageNotifier(),
      child: const NewHomePage._(),
    );
  }

  @override
  State<NewHomePage> createState() => _NewHomePageState();
}

class _NewHomePageState extends State<NewHomePage> {
  final SakeMatchProfileCache _profileCache = SakeMatchProfileCache();

  Future<Map<int, SakeTasteProfileDetails>> _profilesFor(List<Sake> sakes) =>
      _profileCache.fetch(
        sakes.map((sake) => sake.sakeId ?? 0),
        context.read<SakeScanRepository>().fetchTasteProfiles,
      );

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<NewHomePageNotifier>();
    final savedNotifier = context.read<SavedSakeNotifier>();
    final favoriteNotifier = context.read<FavoriteNotifier>();
    final savedSakes = context.select(
      (SavedSakeState state) => state.savedSakeList,
    );
    final favorites = context.select(
      (FavoriteState state) => state.myFavoriteList,
    );
    final timelineSakes = context.select(
      (TimelinePageState state) => state.sakes,
    );
    final isTimelineLoading = context.select(
      (TimelinePageState state) => state.isLoading,
    );
    final timelineError = context.select(
      (TimelinePageState state) => state.errorMessage,
    );
    final enviedIds = context.select(
      (TimelinePageState state) => state.enviedIds,
    );
    final pendingEnvyIds = context.select(
      (TimelinePageState state) => state.pendingEnvyIds,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _HomeHeader(
            onSearchTap: () => _openSearch(context),
            onScanTap: () => openNewHomeScanner(context),
            onMyPageTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => MyPage.wrapped())),
          ),
          Expanded(
            child: RefreshIndicator(
              color: _brandColor,
              onRefresh: () async {
                _profileCache.clear();
                await Future.wait([
                  notifier.refresh(),
                  savedNotifier.reloadLocal(),
                ]);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.only(top: 34, bottom: 34),
                children: [
                  const _HomePromotionBanners(),
                  const _ObiDivider(),
                  _SectionTitle(
                    title: context.l10n.newHomeRecentSakes,
                    onMoreTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const RecentSakeListPage(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (savedSakes.isEmpty)
                    _EmptySection(message: context.l10n.savedSakeEmpty)
                  else
                    _SakeCardRail(
                      sakes: savedSakes.take(10).toList(),
                      profilesFuture: _profilesFor(
                        savedSakes.take(10).toList(),
                      ),
                      actionBuilder: (sake) {
                        final name = _displayName(context, sake);
                        final isFavorite = favorites.any(
                          (favorite) =>
                              favorite.name == name &&
                              favorite.type == sake.type,
                        );
                        return _RoundCardAction(
                          icon: isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: isFavorite
                              ? const Color(0xFFFF5F87)
                              : const Color(0xFFAAAAAA),
                          onTap: () async {
                            try {
                              await favoriteNotifier.addOrRemoveFavorite(
                                FavoriteSake(name: name, type: sake.type),
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
                      },
                      subtitleBuilder: (sake) {
                        final place =
                            (sake.drinkingPlace?.displayName ?? sake.place)
                                ?.trim();
                        return place?.isNotEmpty == true ? place : null;
                      },
                      footerBuilder: (sake) => _formatSavedDate(context, sake),
                      onTap: (sake) async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => SavedSakeDetailPage.forSake(sake),
                          ),
                        );
                        if (context.mounted) {
                          await savedNotifier.refreshFromServer();
                        }
                      },
                    ),
                  const SizedBox(height: 28),
                  _HomeRecommendations(profilesFor: _profilesFor),
                  const SizedBox(height: 28),
                  const _ObiDivider(),
                  _SectionTitle(
                    title: context.l10n.newHomeTimeline,
                    onMoreTap: () =>
                        context.read<AppPageNotifier>().onTabTapped(3),
                  ),
                  const SizedBox(height: 10),
                  if (isTimelineLoading && timelineSakes.isEmpty)
                    const SizedBox(
                      height: 228,
                      child: Center(
                        child: CircularProgressIndicator(color: _brandColor),
                      ),
                    )
                  else if (timelineError != null && timelineSakes.isEmpty)
                    _TimelineError(
                      message: context.l10n.dataFetchFailed,
                      onRetry: notifier.refresh,
                    )
                  else if (timelineSakes.isEmpty)
                    _EmptySection(message: context.l10n.publicTimelineEmpty)
                  else
                    _SakeCardRail(
                      sakes: timelineSakes.take(10).toList(),
                      profilesFuture: _profilesFor(
                        timelineSakes.take(10).toList(),
                      ),
                      actionBuilder: (sake) {
                        final key = TimelinePageNotifier.envyKey(sake);
                        final isEnvied = enviedIds.contains(key);
                        final isPending = pendingEnvyIds.contains(key);
                        return _RoundCardAction(
                          icon: Icons.thumb_up_alt_outlined,
                          color: isEnvied
                              ? _scanColor
                              : const Color(0xFFAAAAAA),
                          showProgress: isPending,
                          onTap: isPending
                              ? null
                              : () => _sendEnvy(context, notifier, sake),
                        );
                      },
                      subtitleBuilder: (sake) =>
                          _displayUserName(context, sake),
                      onTap: (_) =>
                          context.read<AppPageNotifier>().onTabTapped(3),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSearch(BuildContext context) {
    final appPageNotifier = context.read<AppPageNotifier>();
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MainSearchPage.wrapped(
          onPreferenceSearchTap: () => appPageNotifier.onTabTapped(2),
        ),
      ),
    );
  }

  Future<void> _sendEnvy(
    BuildContext context,
    NewHomePageNotifier notifier,
    Sake sake,
  ) async {
    if (!notifier.isLoggedIn) {
      await GuestLimitDialog.show(
        context,
        title: context.l10n.timelineLoginTitle,
        message: context.l10n.timelineLoginMessage,
      );
      return;
    }

    final result = await notifier.incrementEnvy(sake);
    if (!context.mounted) return;
    if (result == EnvyResult.success) {
      SnackBarUtils.showInfoSnackBar(context, message: context.l10n.envySent);
    } else if (result == EnvyResult.failed) {
      SnackBarUtils.showWarningSnackBar(
        context,
        message: context.l10n.envySendFailed,
      );
    }
  }
}

class _HomePromotionBanners extends StatefulWidget {
  const _HomePromotionBanners();

  @override
  State<_HomePromotionBanners> createState() => _HomePromotionBannersState();
}

class _HomePromotionBannersState extends State<_HomePromotionBanners> {
  int _page = 0;
  final _controller = PageController(viewportFraction: 0.9);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = context.select((AppPageState state) => state.homeBanners);
    if (banners.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        children: [
          SizedBox(
            height: 126,
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (value) => setState(() => _page = value),
              itemCount: banners.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _PromotionBanner(banner: banners[index]),
              ),
            ),
          ),
          if (banners.length > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                banners.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: index == _page ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: index == _page
                        ? _brandColor
                        : const Color(0xFFD0D5DB),
                    borderRadius: BorderRadius.circular(99),
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

class _PromotionBanner extends StatelessWidget {
  const _PromotionBanner({required this.banner});

  final AppPromotion banner;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFF2F2F2),
    borderRadius: BorderRadius.circular(14),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: banner.linkTarget == null
          ? null
          : () => context.read<AppPageNotifier>().openPromotion(banner),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            banner.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Center(child: Icon(Icons.campaign_outlined, size: 44)),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 18, 12, 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                ),
              ),
              child: Text(
                banner.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _HomeRecommendations extends StatefulWidget {
  const _HomeRecommendations({required this.profilesFor});

  final Future<Map<int, SakeTasteProfileDetails>> Function(List<Sake>)
  profilesFor;

  @override
  State<_HomeRecommendations> createState() => _HomeRecommendationsState();
}

class _HomeRecommendationsState extends State<_HomeRecommendations> {
  Future<List<HomeSakeRecommendation>>? _future;
  bool _isRefreshing = false;
  Object? _lastTasteProfile;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tasteProfile = Provider.of<MyPageState?>(context)?.tasteProfile;
    if (!_initialized || tasteProfile != _lastTasteProfile) {
      _initialized = true;
      _lastTasteProfile = tasteProfile;
      _future = context.read<MolaApiRepository>().fetchHomeSakeRecommendations(
        limit: 10,
      );
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      final recommendations = await context
          .read<MolaApiRepository>()
          .refreshHomeSakeRecommendations();
      if (!mounted) return;
      setState(() => _future = Future.value(recommendations));
    } on MonthlyRecommendationLimitException {
      if (mounted) {
        SnackBarUtils.showWarningSnackBar(
          context,
          message: '今月の再選定は済んでいます。次回は来月お試しください。',
        );
      }
    } on MissingTasteProfileException {
      if (mounted) {
        SnackBarUtils.showWarningSnackBar(
          context,
          message: '先に「好きなお酒の傾向」を登録してください。',
        );
      }
    } catch (_) {
      if (mounted) {
        SnackBarUtils.showWarningSnackBar(context, message: 'おすすめの再選定に失敗しました。');
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<HomeSakeRecommendation>>(
        future: _future,
        builder: (context, snapshot) {
          final recommendations = snapshot.data ?? const [];
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 110,
              child: Center(
                child: CircularProgressIndicator(color: _brandColor),
              ),
            );
          }
          final sakes = recommendations
              .map(
                (item) => Sake(
                  sakeId: item.sakeId,
                  name: item.name,
                  brewery: item.brewery,
                  type: item.type,
                  primaryImageUrl: item.imageUrl,
                ),
              )
              .toList(growable: false);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _ObiDivider(),
              _SectionTitle(
                title: 'あなたが好きそうな日本酒',
                onMoreTap: sakes.isEmpty ? null : _refresh,
                actionLabel: _isRefreshing ? '更新中…' : '再選定',
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(29, 4, 20, 0),
                child: Text(
                  '「好きなお酒の傾向」を登録すると表示されます。おすすめは月1回入れ替えられます。',
                  style: TextStyle(color: Color(0xFF777777), fontSize: 13),
                ),
              ),
              if (sakes.isNotEmpty) ...[
                const SizedBox(height: 10),
                _SakeCardRail(
                  sakes: sakes,
                  profilesFuture: widget.profilesFor(sakes),
                  subtitleBuilder: (sake) => sake.brewery,
                  actionBuilder: (_) => const SizedBox.shrink(),
                  onTap: (sake) => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SakeMasterDetailPage(
                        venueSake: VenueSake(
                          sakeId: sake.sakeId,
                          name: sake.name ?? '',
                          brewery: sake.brewery,
                          type: sake.type,
                          recordCount: 0,
                          primaryImageUrl: sake.primaryImageUrl,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      );
}

/// ヘッダーと下部ナビから共通利用する高速ラベルスキャン導線。
Future<void> openNewHomeScanner(BuildContext context) async {
  final result = await openSakeLabelScanner(context);
  if (result == null || !context.mounted) return;
  if (result is String && result.trim().isNotEmpty) {
    final appPageNotifier = context.read<AppPageNotifier>();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MainSearchPage.wrapped(
          initialQuery: result,
          onPreferenceSearchTap: () => appPageNotifier.onTabTapped(2),
        ),
      ),
    );
  } else if (result is Sake) {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SavedSakeDetailPage.forSake(result),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.onSearchTap,
    required this.onScanTap,
    required this.onMyPageTap,
  });

  final VoidCallback onSearchTap;
  final VoidCallback onScanTap;
  final VoidCallback onMyPageTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF272727),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: MediaQuery.paddingOf(context).top + 68,
            width: double.infinity,
            padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
            color: _brandColor,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/images/sake_logo.png',
                  width: 66,
                  height: 66,
                  fit: BoxFit.contain,
                ),
                Positioned(
                  right: 10,
                  child: Semantics(
                    button: true,
                    label: context.l10n.navigationMyPage,
                    child: IconButton(
                      tooltip: context.l10n.navigationMyPage,
                      onPressed: onMyPageTap,
                      icon: const Icon(
                        Icons.account_circle_outlined,
                        color: Colors.white,
                        size: 35,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 88,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 9, 18),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: context.l10n.newHomeSearchHint,
                      child: InkWell(
                        onTap: onSearchTap,
                        borderRadius: BorderRadius.circular(14),
                        child: Ink(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF454545),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.search,
                                size: 32,
                                color: Color(0xFF606060),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  context.l10n.newHomeSearchHint,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFA0A0A0),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _ScanCircleButton(size: 60, iconSize: 34, onTap: onScanTap),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ObiDivider extends StatelessWidget {
  const _ObiDivider();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
    child: SizedBox(
      key: const Key('home-obi-divider'),
      height: 42,
      width: double.infinity,
      child: Image.asset(
        'assets/images/obi.png',
        fit: BoxFit.cover,
        alignment: Alignment.center,
        excludeFromSemantics: true,
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.onMoreTap,
    this.actionLabel = 'もっとみる',
  });

  final String title;
  final VoidCallback? onMoreTap;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(width: 5, height: 17, color: const Color(0xFF494949)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: _bodyTextColor,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (onMoreTap != null)
            TextButton(
              onPressed: onMoreTap,
              style: TextButton.styleFrom(
                foregroundColor: _brandColor,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: const Size(60, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SakeCardRail extends StatelessWidget {
  const _SakeCardRail({
    required this.sakes,
    required this.profilesFuture,
    required this.subtitleBuilder,
    required this.actionBuilder,
    required this.onTap,
    this.footerBuilder,
  });

  final List<Sake> sakes;
  final Future<Map<int, SakeTasteProfileDetails>> profilesFuture;
  final String? Function(Sake sake) subtitleBuilder;
  final String? Function(Sake sake)? footerBuilder;
  final Widget Function(Sake sake) actionBuilder;
  final ValueChanged<Sake> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _sakeCardRailHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: sakes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 30),
        itemBuilder: (context, index) {
          final sake = sakes[index];
          return _SakeCard(
            sake: sake,
            profileFuture: sake.sakeId == null
                ? null
                : profilesFuture.then((profiles) => profiles[sake.sakeId!]),
            subtitle: subtitleBuilder(sake),
            footer: footerBuilder?.call(sake),
            action: actionBuilder(sake),
            onTap: () => onTap(sake),
          );
        },
      ),
    );
  }
}

class _SakeCard extends StatelessWidget {
  const _SakeCard({
    required this.sake,
    required this.profileFuture,
    required this.subtitle,
    required this.action,
    required this.onTap,
    this.footer,
  });

  final Sake sake;
  final Future<SakeTasteProfileDetails?>? profileFuture;
  final String? subtitle;
  final String? footer;
  final Widget action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 137,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  width: 137,
                  height: 203,
                  child: _SakeImage(sake: sake),
                ),
                if (profileFuture != null)
                  Positioned(
                    left: 6,
                    top: 6,
                    child: _SakeMatchBadge(profileFuture: profileFuture!),
                  ),
                Positioned(right: 2, bottom: 4, child: action),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _displayName(context, sake),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _bodyTextColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _bodyTextColor, fontSize: 12),
              ),
            if (footer != null)
              Text(
                footer!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _bodyTextColor, fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }
}

class _SakeImage extends StatelessWidget {
  const _SakeImage({required this.sake});

  final Sake sake;

  @override
  Widget build(BuildContext context) {
    final imagePath = preferredSakeCardImagePath(sake);
    if (imagePath == null || imagePath.trim().isEmpty) {
      return _placeholder();
    }
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Container(
                color: const Color(0xFFF2F2F2),
                alignment: Alignment.center,
                child: const CircularProgressIndicator(
                  color: _brandColor,
                  strokeWidth: 2,
                ),
              ),
      );
    }
    final file = File(imagePath);
    if (!file.existsSync()) return _placeholder();
    return Image.file(
      file,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.low,
      cacheWidth: 360,
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFF2F2F2),
      alignment: Alignment.center,
      child: Image.asset(
        'assets/images/sake_placeholder.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class _SakeMatchBadge extends StatelessWidget {
  const _SakeMatchBadge({required this.profileFuture});

  final Future<SakeTasteProfileDetails?> profileFuture;

  @override
  Widget build(BuildContext context) {
    final preference = Provider.of<MyPageState?>(context)?.tasteProfile;
    if (preference == null) return const SizedBox.shrink();
    return FutureBuilder<SakeTasteProfileDetails?>(
      future: profileFuture,
      builder: (context, snapshot) {
        final profile = snapshot.data;
        if (profile == null) return const SizedBox.shrink();
        final percent = calculateSakeTastePreferenceMatchPercent(
          profile: profile,
          preference: preference,
        );
        return _MatchPercentBadge(percent: percent);
      },
    );
  }
}

class _MatchPercentBadge extends StatelessWidget {
  const _MatchPercentBadge({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFFA13C), Color(0xFFE95C9A)],
      ),
      borderRadius: BorderRadius.circular(99),
      boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 5)],
    ),
    child: Text(
      '$percent%',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        height: 1,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

/// 一覧カードはユーザー写真、マスターのサムネイル、詳細画像の順で表示する。
String? preferredSakeCardImagePath(Sake sake) {
  return preferredSakeImagePath(
    personalImagePaths: sake.imagePaths,
    thumbnailImageUrl: sake.thumbnailImageUrl,
    primaryImageUrl: sake.primaryImageUrl,
  );
}

class _RoundCardAction extends StatelessWidget {
  const _RoundCardAction({
    required this.icon,
    required this.color,
    required this.onTap,
    this.showProgress = false,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: CircleBorder(
        side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 37,
          height: 37,
          child: Center(
            child: showProgress
                ? const SizedBox.square(
                    dimension: 19,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _scanColor,
                    ),
                  )
                : Icon(icon, color: color, size: 25),
          ),
        ),
      ),
    );
  }
}

class _ScanCircleButton extends StatelessWidget {
  const _ScanCircleButton({
    required this.size,
    required this.iconSize,
    required this.onTap,
  });

  final double size;
  final double iconSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(side: BorderSide(color: _scanColor, width: 4)),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox.square(
          dimension: size,
          child: Icon(Icons.camera_alt, size: iconSize, color: _scanColor),
        ),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF777777), fontSize: 13),
          ),
        ),
      ),
    );
  }
}

class _TimelineError extends StatelessWidget {
  const _TimelineError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF777777), fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: Text(context.l10n.reload)),
        ],
      ),
    );
  }
}

String _displayName(BuildContext context, Sake sake) {
  final name = sake.name?.trim();
  return name == null || name.isEmpty ? context.l10n.unknownName : name;
}

String _displayUserName(BuildContext context, Sake sake) {
  final displayName = sake.displayName?.trim();
  if (displayName != null && displayName.isNotEmpty) return displayName;
  final username = sake.username?.trim();
  if (username != null && username.isNotEmpty) return username;
  return context.l10n.anonymousUser;
}

String? _formatSavedDate(BuildContext context, Sake sake) {
  final savedId = sake.savedId;
  if (savedId == null) return null;
  final parts = savedId.split('_');
  if (parts.length < 3) return null;
  final millis = int.tryParse(parts[1]);
  if (millis == null) return null;
  return DateFormat.yMd(
    Localizations.localeOf(context).toLanguageTag(),
  ).format(DateTime.fromMillisecondsSinceEpoch(millis));
}
