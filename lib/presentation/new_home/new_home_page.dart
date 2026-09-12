import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../common/localization/localization_extensions.dart';
import '../../common/utils/snack_bar_utils.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/notifier/favorite/favorite_notifier.dart';
import '../../domain/notifier/saved_sake/saved_sake_notifier.dart';
import '../app_page_notifier.dart';
import '../common/widgets/guest_limit_dialog.dart';
import '../main_search/main_search_page.dart';
import '../my_page/my_page.dart';
import '../my_page/saved_sake_detail_page.dart';
import '../sake_scan/sake_scan_page.dart';
import '../timeline/envy_result.dart';
import '../timeline/timeline_page_notifier.dart';
import 'new_home_page_notifier.dart';

const _brandColor = Color(0xFF143861);
const _scanColor = Color(0xFFFF7A1A);
const _bodyTextColor = Color(0xFF404040);
const _sakeCardRailHeight = 275.0;

class NewHomePage extends StatelessWidget {
  const NewHomePage._();

  static Widget wrapped() {
    return StateNotifierProvider<NewHomePageNotifier, TimelinePageState>(
      create: (_) => NewHomePageNotifier(),
      child: const NewHomePage._(),
    );
  }

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
                  _SectionTitle(title: context.l10n.newHomeRecentSakes),
                  const SizedBox(height: 10),
                  if (savedSakes.isEmpty)
                    _EmptySection(message: context.l10n.savedSakeEmpty)
                  else
                    _SakeCardRail(
                      sakes: savedSakes.take(10).toList(),
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
                  _SectionTitle(title: context.l10n.newHomeTimeline),
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
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => MainSearchPage.wrapped()));
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

/// ヘッダーと下部ナビから共通利用する高速ラベルスキャン導線。
Future<void> openNewHomeScanner(BuildContext context) async {
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
  if (result == null || !context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SavedSakeDetailPage.forSake(result),
    ),
  );
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(width: 4, height: 14, color: const Color(0xFF494949)),
          const SizedBox(width: 7),
          Text(
            title,
            style: const TextStyle(
              color: _bodyTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
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
    required this.subtitleBuilder,
    required this.actionBuilder,
    required this.onTap,
    this.footerBuilder,
  });

  final List<Sake> sakes;
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
    required this.subtitle,
    required this.action,
    required this.onTap,
    this.footer,
  });

  final Sake sake;
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

/// 一覧カードはユーザー写真、マスターのサムネイル、詳細画像の順で表示する。
String? preferredSakeCardImagePath(Sake sake) {
  if (sake.imagePaths?.isNotEmpty ?? false) return sake.imagePaths!.first;
  final thumbnail = sake.thumbnailImageUrl?.trim();
  if (thumbnail?.isNotEmpty == true) return thumbnail;
  final primary = sake.primaryImageUrl?.trim();
  return primary?.isNotEmpty == true ? primary : null;
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
