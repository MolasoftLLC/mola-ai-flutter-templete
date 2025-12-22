import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:provider/provider.dart';

import '../../common/utils/snack_bar_utils.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/notifier/saved_sake/saved_sake_notifier.dart';
import '../../domain/repository/auth_repository.dart';
import '../../domain/repository/saved_sake_sync_repository.dart';
import '../common/widgets/guest_limit_dialog.dart';
import '../common/widgets/primary_app_bar.dart';
import 'envy_result.dart';
import 'timeline_envy_ranking_notifier.dart';

class TimelineEnvyRankingPage extends StatelessWidget {
  const TimelineEnvyRankingPage._({super.key});

  static Widget wrapped() {
    return Builder(
      builder: (context) {
        final repository = context.read<SavedSakeSyncRepository>();
        final authRepository = context.read<AuthRepository>();
        return MultiProvider(
          providers: [
            StateNotifierProvider<TimelineEnvyRankingNotifier,
                TimelineEnvyRankingState>(
              create: (_) => TimelineEnvyRankingNotifier(
                repository,
                authRepository,
              ),
            ),
          ],
          child: const TimelineEnvyRankingPage._(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select(
      (TimelineEnvyRankingState state) => state.isLoading,
    );
    final isRefreshing = context.select(
      (TimelineEnvyRankingState state) => state.isRefreshing,
    );
    final sakes = context.select(
      (TimelineEnvyRankingState state) => state.sakes,
    );
    final errorMessage = context.select(
      (TimelineEnvyRankingState state) => state.errorMessage,
    );
    final enviedKeys = context.select(
      (TimelineEnvyRankingState state) => state.enviedKeys,
    );
    final pendingEnvies = context.select(
      (TimelineEnvyRankingState state) => state.pendingEnvyKeys,
    );
    final notifier = context.read<TimelineEnvyRankingNotifier>();
    final authRepository = context.read<AuthRepository>();
    final savedNotifier = context.read<SavedSakeNotifier>();
    final savedList =
        context.select((SavedSakeState state) => state.savedSakeList);

    Future<bool> ensureLoggedIn() async {
      if (authRepository.currentUser != null) {
        return true;
      }
      await GuestLimitDialog.show(
        context,
        title: 'ログインでさらに楽しもう',
        message: 'ランキングからうらやまを送るにはログインが必要です。',
      );
      return false;
    }

    bool isSakeSaved(Sake target, String normalizedName) {
      final savedId = target.savedId?.trim();
      return savedList.any((item) {
        final hasSameId =
            item.savedId != null && savedId != null && item.savedId == savedId;
        if (hasSameId) {
          return true;
        }
        final itemName =
            item.name?.trim().isNotEmpty == true ? item.name!.trim() : '名称不明';
        final itemType = item.type?.trim();
        final targetType = target.type?.trim();
        return itemName == normalizedName && itemType == targetType;
      });
    }

    Future<void> handleSaved(
      Sake sake,
      bool isSaved,
      String normalizedName,
    ) async {
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
        if (!context.mounted) {
          return;
        }
        if (shouldShowSavedToast) {
          SnackBarUtils.showInfoSnackBar(
            context,
            message: 'マイページに保存しました！',
          );
        }
      } on SavedSakeGuestLimitReachedException {
        if (!context.mounted) {
          return;
        }
        await GuestLimitDialog.showSavedSakeLimit(
          context,
          maxCount: SavedSakeNotifier.guestSavedLimit,
        );
      } on SavedSakeMemberLimitReachedException {
        if (!context.mounted) {
          return;
        }
        SnackBarUtils.showWarningSnackBar(
          context,
          message:
              '保存酒は${SavedSakeNotifier.memberSavedLimit}件まで保存できます。不要な保存酒を削除してください。',
        );
      }
    }

    Future<void> handleEnvy(Sake sake) async {
      if (!await ensureLoggedIn()) {
        return;
      }
      final result = await notifier.incrementEnvy(sake);
      if (!context.mounted) {
        return;
      }
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
    }

    final bool showInitialLoading = isLoading && sakes.isEmpty && !isRefreshing;
    final bool showError = errorMessage != null && sakes.isEmpty;
    final bool isEmpty = sakes.isEmpty;

    Widget buildBody() {
      if (showInitialLoading) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }
      if (showError) {
        return _RankingMessageView(
          message: errorMessage!,
          actionLabel: '再読み込み',
          onRetry: () => notifier.fetchRanking(isRefresh: false),
        );
      }
      if (isEmpty) {
        return const _RankingEmptyView();
      }

      return RefreshIndicator(
        color: Colors.white,
        backgroundColor: const Color(0xFF1D3567),
        onRefresh: notifier.refresh,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: sakes.length,
          itemBuilder: (context, index) {
            final sake = sakes[index];
            final normalizedName = sake.name?.trim().isNotEmpty == true
                ? sake.name!.trim()
                : '名称不明';
            final envyKey = TimelineEnvyRankingNotifier.envyKey(sake);
            final canSendEnvy = envyKey.isNotEmpty &&
                (sake.savedId?.trim().isNotEmpty ?? false);
            final isEnvied = envyKey.isNotEmpty && enviedKeys.contains(envyKey);
            final isPending =
                envyKey.isNotEmpty && pendingEnvies.contains(envyKey);
            final onEnvyTap = !canSendEnvy ? null : () => handleEnvy(sake);
            final isSaved = isSakeSaved(sake, normalizedName);
            final onSavedTap = () => handleSaved(
                  sake,
                  isSaved,
                  normalizedName,
                );
            return _RankingTile(
              rank: index + 1,
              sake: sake,
              showImage: index < 10,
              isEnvied: isEnvied,
              isEnvyPending: isPending,
              isSaved: isSaved,
              onToggleSaved: onSavedTap,
              onEnvyTap: onEnvyTap,
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 12),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1D3567),
      appBar: const PrimaryAppBar(
        title: '羨ましい日本酒ランキング',
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(child: buildBody()),
    );
  }
}

class _RankingTile extends StatelessWidget {
  const _RankingTile({
    required this.rank,
    required this.sake,
    required this.showImage,
    required this.isEnvied,
    required this.isEnvyPending,
    required this.isSaved,
    required this.onToggleSaved,
    this.onEnvyTap,
  });

  final int rank;
  final Sake sake;
  final bool showImage;
  final bool isEnvied;
  final bool isEnvyPending;
  final bool isSaved;
  final VoidCallback onToggleSaved;
  final VoidCallback? onEnvyTap;

  @override
  Widget build(BuildContext context) {
    final normalizedName =
        sake.name?.trim().isNotEmpty == true ? sake.name!.trim() : '名称不明';
    final typeText = sake.type ?? (sake.types?.join(' / '));
    final envyCount = sake.envyCount < 0 ? 0 : sake.envyCount;
    final Color accentColor = rank == 1
        ? const Color(0xFFFFD54F)
        : rank == 2
            ? const Color(0xFFE0E0E0)
            : rank == 3
                ? const Color(0xFFCD7F32)
                : Colors.white54;
    final imagePath =
        (sake.imagePaths?.isNotEmpty ?? false) ? sake.imagePaths!.first : null;

    Widget? buildPreview() {
      if (!showImage) {
        return null;
      }
      if (imagePath == null || imagePath.isEmpty) {
        return _RankingImagePlaceholder(accentColor: accentColor);
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 72,
          height: 72,
          child: _RankingImage(path: imagePath),
        ),
      );
    }

    final preview = buildPreview();

    final bool isInteractable =
        onEnvyTap != null && !isEnvied && !isEnvyPending;
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: accentColor.withOpacity(0.2),
            child: Text(
              '$rank',
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          if (preview != null) ...[
            preview,
            const SizedBox(width: 16),
          ],
          _RankingSaveButton(
            isSaved: isSaved,
            onTap: onToggleSaved,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  normalizedName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (typeText != null && typeText.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      typeText,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: isInteractable ? onEnvyTap : null,
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white70),
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
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$envyCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RankingSaveButton extends StatelessWidget {
  const _RankingSaveButton({
    required this.isSaved,
    required this.onTap,
  });

  final bool isSaved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = isSaved
        ? Colors.amberAccent.withOpacity(0.25)
        : Colors.black.withOpacity(0.45);
    final Color borderColor = isSaved
        ? Colors.amberAccent.withOpacity(0.6)
        : Colors.white.withOpacity(0.2);
    final Color iconColor = isSaved ? Colors.amberAccent : Colors.white70;

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
          ),
          child: Icon(
            isSaved ? Icons.bookmark : Icons.bookmark_outline,
            color: iconColor,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _RankingImage extends StatelessWidget {
  const _RankingImage({required this.path});

  final String path;

  bool get _isRemote =>
      path.startsWith('http://') || path.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    if (_isRemote) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _RankingImageFallback(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) {
            return child;
          }
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
              strokeWidth: 2,
            ),
          );
        },
      );
    }
    final file = File(path);
    if (!file.existsSync()) {
      return const _RankingImageFallback();
    }
    return Image.file(
      file,
      fit: BoxFit.cover,
    );
  }
}

class _RankingImagePlaceholder extends StatelessWidget {
  const _RankingImagePlaceholder({required this.accentColor});

  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.4)),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.emoji_events_outlined,
        color: accentColor,
      ),
    );
  }
}

class _RankingImageFallback extends StatelessWidget {
  const _RankingImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black26,
      alignment: Alignment.center,
      child: const Icon(
        Icons.broken_image,
        color: Colors.white54,
      ),
    );
  }
}

class _RankingEmptyView extends StatelessWidget {
  const _RankingEmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.emoji_events_outlined,
              color: Colors.white38,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'まだランキングを表示できる投稿がありません。',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankingMessageView extends StatelessWidget {
  const _RankingMessageView({
    required this.message,
    this.actionLabel,
    this.onRetry,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            if (actionLabel != null && onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD54F),
                  foregroundColor: const Color(0xFF1D3567),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onRetry,
                child: Text(
                  actionLabel!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
