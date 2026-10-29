import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common/localization/localization_extensions.dart';
import '../../../domain/eintities/menu_analysis_history.dart';
import '../../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../../domain/notifier/favorite/favorite_notifier.dart';
import '../../../domain/notifier/saved_sake/saved_sake_notifier.dart';
import '../../../domain/repository/place_map_repository.dart';
import '../../sake_map/sake_master_detail_page.dart';
import '../../common/widgets/guest_limit_dialog.dart';
import 'sake_result_tile.dart';
import 'menu_sake_detail_rows.dart';

class MenuHistorySakeTile extends StatelessWidget {
  const MenuHistorySakeTile({
    super.key,
    required this.sake,
    required this.historyId,
  });
  final String historyId;
  final SavedSake sake;

  @override
  Widget build(BuildContext context) {
    final details = sake.details;
    final displaySake =
        details ?? Sake(sakeId: sake.sakeId, name: sake.name, type: sake.type);
    final favorites = context.watch<FavoriteState>().myFavoriteList;
    final saved = context.watch<SavedSakeState>().bookmarkedSakes;
    final favoriteNotifier = context.read<FavoriteNotifier>();
    final savedNotifier = context.read<SavedSakeNotifier>();
    final isFavorited = favorites.any(
      (item) => item.name == displaySake.name && item.type == displaySake.type,
    );
    final isSaved = saved.any(
      (item) => item.name == displaySake.name && item.type == displaySake.type,
    );
    final hasDetails =
        details != null || sake.tasteProfile != null || (sake.sakeId ?? 0) > 0;
    return SakeResultTile(
      key: ValueKey(
        'history-sake-$historyId-${sake.extractedName ?? sake.name}-${sake.sakeId}',
      ),
      dark: true,
      sake: displaySake,
      detailedSake: displaySake,
      hasDetails: hasDetails,
      isItemLoading: false,
      hasFailed: !hasDetails,
      isFavorited: isFavorited,
      isSaved: isSaved,
      isLoading: false,
      matchPercent: sake.matchPercent,
      tasteProfile: sake.tasteProfile,
      isUnverified: false,
      candidates: const [],
      onCandidateSelected: (_) {},
      onOpenDetails: (displaySake.sakeId ?? 0) > 0
          ? () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SakeMasterDetailPage(
                  venueSake: VenueSake(
                    sakeId: displaySake.sakeId,
                    name: displaySake.name ?? sake.name,
                    brewery: displaySake.brewery,
                    type: displaySake.type,
                    recordCount: 0,
                    primaryImageUrl: displaySake.primaryImageUrl,
                    thumbnailImageUrl: displaySake.thumbnailImageUrl,
                  ),
                ),
              ),
            )
          : null,
      onToggleFavorite: () async {
        try {
          await favoriteNotifier.addOrRemoveFavorite(
            FavoriteSake(
              sakeId: displaySake.sakeId,
              name: displaySake.name ?? sake.name,
              type: displaySake.type,
            ),
          );
        } on FavoriteGuestLimitReachedException {
          if (!context.mounted) return;
          await GuestLimitDialog.showFavoriteLimit(
            context,
            maxCount: FavoriteNotifier.guestFavoriteLimit,
          );
        }
      },
      onSave: () async {
        try {
          final changed = await savedNotifier.toggleSavedSake(displaySake);
          if (!context.mounted) {
            return isSaved;
          }
          if (!changed) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('保存状態を変更できませんでした。もう一度お試しください。')),
            );
            return isSaved;
          }
          return !isSaved;
        } on SavedSakeGuestLimitReachedException {
          if (!context.mounted) return false;
          await GuestLimitDialog.showSavedSakeLimit(
            context,
            maxCount: SavedSakeNotifier.guestSavedLimit,
          );
        } on SavedSakeMemberLimitReachedException {
          if (!context.mounted) return false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.savedSakeLimit(SavedSakeNotifier.memberSavedLimit),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return false;
      },
      buildInfoRow: (key, value, icon) =>
          buildMenuSakeInfoRow(key, value, icon, dark: true),
      buildTypesRow: (types) =>
          buildMenuSakeTypesRow(context, types, dark: true),
    );
  }
}
