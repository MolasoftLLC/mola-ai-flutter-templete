import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:provider/provider.dart';

import '../../common/utils/snack_bar_utils.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/notifier/favorite/favorite_notifier.dart';
import '../../domain/notifier/saved_sake/saved_sake_notifier.dart';
import '../common/widgets/guest_limit_dialog.dart';
import '../common/widgets/primary_app_bar.dart';
import 'timeline_page_notifier.dart';

class TimelinePage extends StatelessWidget {
  const TimelinePage._({
    super.key,
    required this.feedType,
    required this.title,
    required this.emptyMessage,
  });

  final TimelineFeedType feedType;
  final String title;
  final String emptyMessage;

  static Widget wrapped() {
    return _build(
      feedType: TimelineFeedType.public,
      title: 'みんなの日本酒',
      emptyMessage: 'まだタイムラインには保存酒がありません。\nほかのユーザーが保存するとここに表示されます。',
    );
  }

  static Widget myPosts() {
    return _build(
      feedType: TimelineFeedType.mine,
      title: '自分の投稿',
      emptyMessage: 'まだタイムラインに公開した投稿がありません。\nお気に入りのお酒をシェアしてみましょう。',
    );
  }

  static Widget _build({
    required TimelineFeedType feedType,
    required String title,
    required String emptyMessage,
  }) {
    return MultiProvider(
      providers: [
        StateNotifierProvider<TimelinePageNotifier, TimelinePageState>(
          create: (_) => TimelinePageNotifier(feedType: feedType),
        ),
      ],
      child: TimelinePage._(
        feedType: feedType,
        title: title,
        emptyMessage: emptyMessage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<TimelinePageNotifier>();
    final isLoading =
        context.select((TimelinePageState state) => state.isLoading);
    final isRefreshing =
        context.select((TimelinePageState state) => state.isRefreshing);
    final sakes = context.select((TimelinePageState state) => state.sakes);
    final errorMessage =
        context.select((TimelinePageState state) => state.errorMessage);

    final savedNotifier = context.read<SavedSakeNotifier>();
    final favoriteNotifier = context.read<FavoriteNotifier>();
    final savedList =
        context.select((SavedSakeState state) => state.savedSakeList);
    final favoriteList =
        context.select((FavoriteState state) => state.myFavoriteList);
    final enviedIds =
        context.select((TimelinePageState state) => state.enviedIds);
    final pendingEnvies =
        context.select((TimelinePageState state) => state.pendingEnvyIds);
    final pendingReports =
        context.select((TimelinePageState state) => state.pendingReportIds);
    final hasMore = context.select((TimelinePageState state) => state.hasMore);
    final isLoadingMore =
        context.select((TimelinePageState state) => state.isLoadingMore);

    Future<bool> ensureLoggedIn() async {
      if (notifier.isLoggedIn) {
        return true;
      }
      await GuestLimitDialog.show(
        context,
        title: 'ログインでさらに楽しもう',
        message: 'タイムラインから保存・お気に入り・うらやま・報告するにはログインが必要です。',
      );
      return false;
    }

    final bool showInitialLoading = isLoading && sakes.isEmpty && !isRefreshing;
    final bool showErrorState = errorMessage != null && sakes.isEmpty;
    final bool showFallback = sakes.isEmpty;
    final bool showLoadingIndicator = !showFallback && isLoadingMore;
    final int itemCount =
        showFallback ? 1 : sakes.length + (showLoadingIndicator ? 1 : 0);

    Widget buildFallbackItem() {
      if (showInitialLoading) {
        return const Padding(
          padding: EdgeInsets.only(top: 80),
          child: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        );
      }
      if (showErrorState) {
        return _TimelineMessageView(
          message: errorMessage ?? 'データの取得に失敗しました。通信環境をご確認ください。',
          actionLabel: '再読み込み',
          onPressed: () => notifier.fetchTimeline(isRefresh: false),
        );
      }
      return _TimelineMessageView(message: emptyMessage);
    }

    Widget buildCard(int index) {
      final sake = sakes[index];
      final normalizedName =
          sake.name?.trim().isNotEmpty == true ? sake.name!.trim() : '名称不明';
      final envyKey = TimelinePageNotifier.envyKey(sake);
      final savedId = sake.savedId?.trim();
      final isSaved = savedList.any((item) {
        final hasSameId = item.savedId != null &&
            sake.savedId != null &&
            item.savedId == sake.savedId;
        if (hasSameId) {
          return true;
        }
        final itemName =
            item.name?.trim().isNotEmpty == true ? item.name!.trim() : '名称不明';
        final itemType = item.type?.trim();
        final targetType = sake.type?.trim();
        return itemName == normalizedName && itemType == targetType;
      });
      final isFavorite = favoriteList.any(
        (item) => item.name.trim() == normalizedName && item.type == sake.type,
      );
      final isEnvied = envyKey.isNotEmpty && enviedIds.contains(envyKey);
      final isEnvyPending =
          envyKey.isNotEmpty && pendingEnvies.contains(envyKey);
      final envyCount = sake.envyCount;
      final isReportPending =
          savedId != null && pendingReports.contains(savedId);

      return _TimelineSakeCard(
        sake: sake,
        isSaved: isSaved,
        isFavorite: isFavorite,
        isEnvied: isEnvied,
        isEnvyPending: isEnvyPending,
        envyCount: envyCount,
        isReportPending: isReportPending,
        onToggleSaved: () async {
          if (!await ensureLoggedIn()) {
            return;
          }
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
              message:
                  '保存酒は${SavedSakeNotifier.memberSavedLimit}件まで保存できます。不要な保存酒を削除してください。',
            );
            return;
          }

          final normalized = sake.copyWith(
            savedId: null,
            name: normalizedName,
            impression: null,
            userTags: null,
          );
          final shouldShowSavedToast = !isSaved;
          try {
            await savedNotifier.toggleSavedSake(normalized);
            if (shouldShowSavedToast) {
              SnackBarUtils.showInfoSnackBar(
                context,
                message: 'マイページに保存しました！',
              );
            }
          } on SavedSakeGuestLimitReachedException {
            await GuestLimitDialog.showSavedSakeLimit(
              context,
              maxCount: SavedSakeNotifier.guestSavedLimit,
            );
          } on SavedSakeMemberLimitReachedException {
            SnackBarUtils.showWarningSnackBar(
              context,
              message:
                  '保存酒は${SavedSakeNotifier.memberSavedLimit}件まで保存できます。不要な保存酒を削除してください。',
            );
          }
        },
        onToggleFavorite: () async {
          if (!await ensureLoggedIn()) {
            return;
          }
          final favoriteSake = FavoriteSake(
            name: normalizedName,
            type: sake.type,
          );

          if (!isFavorite && favoriteNotifier.hasReachedGuestLimit) {
            await GuestLimitDialog.showFavoriteLimit(
              context,
              maxCount: FavoriteNotifier.guestFavoriteLimit,
            );
            return;
          }

          try {
            await favoriteNotifier.addOrRemoveFavorite(favoriteSake);
          } on FavoriteGuestLimitReachedException {
            await GuestLimitDialog.showFavoriteLimit(
              context,
              maxCount: FavoriteNotifier.guestFavoriteLimit,
            );
          }
        },
        onToggleEnvy: envyKey.isEmpty
            ? null
            : () async {
                final result = await notifier.incrementEnvy(sake);
                switch (result) {
                  case EnvyResult.success:
                    SnackBarUtils.showInfoSnackBar(
                      context,
                      message: 'うらやまを送信しました！',
                    );
                    break;
                  case EnvyResult.failed:
                    SnackBarUtils.showWarningSnackBar(
                      context,
                      message: 'うらやまの送信に失敗しました。通信環境をご確認ください。',
                    );
                    break;
                  case EnvyResult.already:
                    SnackBarUtils.showInfoSnackBar(
                      context,
                      message: 'すでにうらやま済みです！',
                    );
                    break;
                  case EnvyResult.pending:
                    break;
                }
              },
        onReport: savedId == null
            ? null
            : () async {
                if (!await ensureLoggedIn()) {
                  return;
                }
                final result = await notifier.reportSavedSake(sake);
                if (!context.mounted) {
                  return;
                }
                switch (result) {
                  case ReportResult.success:
                    SnackBarUtils.showInfoSnackBar(
                      context,
                      message: 'ありがとうございました。報告を受け付けました。',
                    );
                    break;
                  case ReportResult.already:
                    SnackBarUtils.showInfoSnackBar(
                      context,
                      message: 'この投稿は既に報告済みです。',
                    );
                    break;
                  case ReportResult.pending:
                    break;
                  case ReportResult.unauthenticated:
                    await ensureLoggedIn();
                    break;
                  case ReportResult.failed:
                    SnackBarUtils.showWarningSnackBar(
                      context,
                      message: '報告に失敗しました。通信環境をご確認ください。',
                    );
                    break;
                }
              },
      );
    }

    final listView = ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (showFallback) {
          return buildFallbackItem();
        }
        if (showLoadingIndicator && index >= sakes.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
          );
        }
        return buildCard(index);
      },
      separatorBuilder: (_, __) => const SizedBox(height: 16),
    );

    final scrollable = NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.axis == Axis.vertical &&
            (notification is ScrollUpdateNotification ||
                notification is OverscrollNotification)) {
          final bool shouldLoadMore = !showFallback &&
              hasMore &&
              !isLoading &&
              !isRefreshing &&
              !isLoadingMore &&
              notification.metrics.extentAfter < 200;
          if (shouldLoadMore) {
            notifier.loadMore();
          }
        }
        return false;
      },
      child: listView,
    );

    final bool showBackButton = feedType == TimelineFeedType.mine;
    final bool showShortcutButton = feedType == TimelineFeedType.public;
    final navigator = Navigator.of(context);

    Widget? leadingButton;
    double? leadingWidth;
    if (showShortcutButton) {
      leadingButton = _TimelineHeaderShortcutButton(
        icon: Icons.person_outline,
        label: '自分の投稿',
        color: const Color(0xFFFFD54F),
        onTap: () async {
          if (!await ensureLoggedIn()) {
            return;
          }
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TimelinePage.myPosts(),
            ),
          );
        },
      );
      leadingWidth = 90;
    } else if (showBackButton) {
      leadingButton = _TimelineHeaderShortcutButton(
        icon: Icons.arrow_back_ios_new,
        label: 'みんなの日本酒',
        color: const Color(0xFFFFD54F),
        onTap: () {
          if (navigator.canPop()) {
            navigator.pop();
          }
        },
      );
      leadingWidth = 90;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1D3567),
      appBar: PrimaryAppBar(
        title: title,
        automaticallyImplyLeading: leadingButton == null && showBackButton,
        leadingWidth: leadingWidth,
        leading: leadingButton,
        actions: [
          IconButton(
            tooltip: '更新',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => notifier.fetchTimeline(isRefresh: true),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: Colors.white,
          backgroundColor: const Color(0xFF1D3567),
          onRefresh: notifier.refresh,
          child: scrollable,
        ),
      ),
    );
  }
}

class _TimelineHeaderShortcutButton extends StatelessWidget {
  const _TimelineHeaderShortcutButton({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.color,
  });

  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: 72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineSakeCard extends StatefulWidget {
  const _TimelineSakeCard({
    required this.sake,
    required this.isSaved,
    required this.isFavorite,
    required this.envyCount,
    required this.isEnvied,
    required this.isEnvyPending,
    this.isReportPending = false,
    required this.onToggleSaved,
    required this.onToggleFavorite,
    this.onToggleEnvy,
    this.onReport,
  });

  final Sake sake;
  final bool isSaved;
  final bool isFavorite;
  final int envyCount;
  final bool isEnvied;
  final bool isEnvyPending;
  final bool isReportPending;
  final VoidCallback onToggleSaved;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onToggleEnvy;
  final VoidCallback? onReport;

  @override
  State<_TimelineSakeCard> createState() => _TimelineSakeCardState();
}

class _TimelineSakeCardState extends State<_TimelineSakeCard> {
  bool _isTasteExpanded = false;
  bool _isTasteDetailVisible = false;

  @override
  Widget build(BuildContext context) {
    final sake = widget.sake;
    final imagePath =
        (sake.imagePaths?.isNotEmpty ?? false) ? sake.imagePaths!.first : null;
    final typeText = sake.type ?? (sake.types?.join(' / '));
    final tasteText = sake.taste?.trim();
    final hasTaste = tasteText != null && tasteText.isNotEmpty;
    final place = sake.place?.trim();
    final hasPlace = place != null && place.isNotEmpty;
    final impression = sake.impression?.trim();
    final hasImpression = impression != null && impression.isNotEmpty;
    final tags = sake.userTags
            ?.map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList() ??
        const <String>[];
    final hasTags = tags.isNotEmpty;
    const bodyStyle = TextStyle(
      color: Colors.white,
      fontSize: 13,
      height: 1.4,
    );
    final displayedEnvyCount = widget.envyCount < 0 ? 0 : widget.envyCount;
    final isEnvied = widget.isEnvied;
    final isEnvyPending = widget.isEnvyPending;
    final bool isInteractable =
        widget.onToggleEnvy != null && !isEnvied && !isEnvyPending;
    final Color envyButtonColor;
    if (isEnvyPending) {
      envyButtonColor = Colors.black45;
    } else if (isEnvied) {
      envyButtonColor = Colors.pinkAccent;
    } else if (!isInteractable) {
      envyButtonColor = Colors.black26;
    } else {
      envyButtonColor = Colors.black.withOpacity(0.45);
    }
    final Color envyIconColor;
    if (isEnvyPending) {
      envyIconColor = Colors.white70;
    } else if (isEnvied) {
      envyIconColor = Colors.white;
    } else if (!isInteractable) {
      envyIconColor = Colors.white38;
    } else {
      envyIconColor = Colors.white70;
    }

    final userName = _resolveUserName(sake);
    final userIconUrl = sake.iconUrl?.trim();
    final hasUserIcon = userIconUrl != null && userIconUrl.isNotEmpty;
    final shouldShowUserInfo = userName.isNotEmpty || hasUserIcon;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: (imagePath == null || imagePath.isEmpty)
                    ? null
                    : () => _showImagePreview(context, imagePath),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 3 / 2,
                    child: _buildImage(imagePath),
                  ),
                ),
              ),
              if (widget.onReport != null)
                Positioned(
                  right: -6,
                  top: -8,
                  child: _TimelineReportButton(
                    isPending: widget.isReportPending,
                    onPressed: widget.isReportPending ? null : widget.onReport,
                  ),
                ),
              if (shouldShowUserInfo)
                Positioned(
                  left: -6,
                  top: -8,
                  child: _TimelineUserInfoBadge(
                    username: userName,
                    iconUrl: userIconUrl,
                  ),
                ),
              Positioned(
                left: 12,
                bottom: 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TimelineCircleIconButton(
                      icon: widget.isSaved
                          ? Icons.bookmark
                          : Icons.bookmark_outline,
                      isActive: widget.isSaved,
                      activeColor: Colors.amberAccent,
                      onTap: widget.onToggleSaved,
                    ),
                    const SizedBox(height: 10),
                    _TimelineCircleIconButton(
                      icon: widget.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      isActive: widget.isFavorite,
                      activeColor: Colors.pinkAccent,
                      onTap: widget.onToggleFavorite,
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: isInteractable ? widget.onToggleEnvy : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: envyButtonColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: isEnvyPending
                            ? const Padding(
                                padding: EdgeInsets.all(11),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white70),
                                  strokeWidth: 2.4,
                                ),
                              )
                            : Icon(
                                Icons.thumb_up_alt_rounded,
                                color: envyIconColor,
                                size: 22,
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 44,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '$displayedEnvyCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            sake.name?.trim().isNotEmpty == true ? sake.name!.trim() : '名称不明',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (typeText != null && typeText.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                typeText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          if (sake.brewery != null && sake.brewery!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                sake.brewery!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          if (hasPlace)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.place,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      place!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          if (hasTaste && !hasImpression)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final tasteContent = '味わい: $tasteText';
                  final painter = TextPainter(
                    text: TextSpan(text: tasteContent, style: bodyStyle),
                    maxLines: 2,
                    textDirection: Directionality.of(context),
                  )..layout(maxWidth: constraints.maxWidth);
                  final shouldShowToggle = painter.didExceedMaxLines;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tasteContent,
                        maxLines: _isTasteExpanded ? null : 2,
                        overflow: _isTasteExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: bodyStyle,
                      ),
                      if (shouldShowToggle)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _isTasteExpanded = !_isTasteExpanded;
                              });
                            },
                            icon: Icon(
                              _isTasteExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Colors.white,
                            ),
                            label: Text(
                              _isTasteExpanded ? '閉じる' : '続きを読む',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: const Size(0, 32),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          if (hasImpression)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                impression!,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: bodyStyle,
              ),
            ),
          if (hasImpression && hasTaste)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          final nextValue = !_isTasteDetailVisible;
                          _isTasteDetailVisible = nextValue;
                          if (!nextValue) {
                            _isTasteExpanded = false;
                          }
                        });
                      },
                      icon: Icon(
                        _isTasteDetailVisible
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.white,
                      ),
                      label: Text(
                        _isTasteDetailVisible ? '閉じる' : '詳細を見る',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                  ),
                  if (_isTasteDetailVisible)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '味わい: $tasteText',
                        style: bodyStyle,
                      ),
                    ),
                ],
              ),
            ),
          if (hasTags)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  String _resolveUserName(Sake sake) {
    final username = sake.username?.trim();
    if (username != null && username.isNotEmpty) {
      return username;
    }
    final displayName = sake.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }
    return '名無しユーザー';
  }

  Widget _buildImage(String? path) {
    const backgroundColor = Colors.black;

    Widget buildFallbackIcon(IconData icon) {
      return Icon(
        icon,
        color: Colors.white38,
        size: 40,
      );
    }

    if (path == null || path.isEmpty) {
      return Container(
        color: backgroundColor,
        alignment: Alignment.center,
        child: buildFallbackIcon(Icons.image_not_supported),
      );
    }

    if (_isRemotePath(path)) {
      return Container(
        color: backgroundColor,
        alignment: Alignment.center,
        child: Image.network(
          path,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) {
              return child;
            }
            return const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
            );
          },
          errorBuilder: (_, __, ___) => buildFallbackIcon(Icons.broken_image),
        ),
      );
    }

    final file = File(path);
    if (!file.existsSync()) {
      return Container(
        color: backgroundColor,
        alignment: Alignment.center,
        child: buildFallbackIcon(Icons.broken_image),
      );
    }

    return Container(
      color: backgroundColor,
      alignment: Alignment.center,
      child: Image.file(
        file,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.low,
      ),
    );
  }

  bool _isRemotePath(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  void _showImagePreview(BuildContext context, String path) {
    showDialog<void>(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.black87,
          insetPadding: const EdgeInsets.all(16),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _isRemotePath(path)
                    ? Image.network(
                        path,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) {
                            return child;
                          }
                          return const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        },
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.white54,
                            size: 48,
                          ),
                        ),
                      )
                    : _buildPreviewFile(path),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewFile(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return const Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.white54,
          size: 48,
        ),
      );
    }
    return Image.file(
      file,
      fit: BoxFit.contain,
    );
  }
}

class _TimelineCircleIconButton extends StatelessWidget {
  const _TimelineCircleIconButton({
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = isActive
        ? activeColor.withOpacity(0.28)
        : Colors.black.withOpacity(0.45);
    final Color borderColor = isActive
        ? activeColor.withOpacity(0.65)
        : Colors.white.withOpacity(0.2);
    final Color iconColor = isActive ? activeColor : Colors.white70;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _TimelineUserInfoBadge extends StatelessWidget {
  const _TimelineUserInfoBadge({
    required this.username,
    this.iconUrl,
  });

  final String username;
  final String? iconUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TimelineUserAvatar(iconUrl: iconUrl),
          const SizedBox(width: 8),
          Text(
            username,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineUserAvatar extends StatelessWidget {
  const _TimelineUserAvatar({this.iconUrl});

  final String? iconUrl;

  @override
  Widget build(BuildContext context) {
    const double size = 28;
    final resolved = iconUrl?.trim();
    if (resolved != null && resolved.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          resolved,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(size),
          loadingBuilder: (context, child, progress) {
            if (progress == null) {
              return child;
            }
            return _placeholder(size);
          },
        ),
      );
    }
    return _placeholder(size);
  }

  Widget _placeholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF9E9E9E),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 18,
      ),
    );
  }
}

class _TimelineReportButton extends StatelessWidget {
  const _TimelineReportButton({
    required this.isPending,
    this.onPressed,
  });

  final bool isPending;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null && !isPending;
    final Widget child;
    if (isPending) {
      child = const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
        ),
      );
    } else {
      child = const Icon(
        Icons.flag_outlined,
        color: Colors.white,
        size: 18,
      );
    }

    return GestureDetector(
      onTap: isEnabled ? onPressed : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: isEnabled ? 1.0 : 0.7,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.redAccent.withOpacity(0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

class _TimelineMessageView extends StatelessWidget {
  const _TimelineMessageView({
    required this.message,
    this.actionLabel,
    this.onPressed,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.receipt_long,
          color: Colors.white54,
          size: 48,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        if (actionLabel != null && onPressed != null) ...[
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withOpacity(0.6)),
            ),
            child: Text(actionLabel!),
          ),
        ],
      ],
    );
  }
}
