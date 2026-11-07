import 'package:flutter/material.dart';

import '../../domain/repository/place_map_repository.dart';
import 'venue_favorites_controller.dart';

class VenueFavoriteButton extends StatelessWidget {
  const VenueFavoriteButton({
    super.key,
    required this.controller,
    required this.venue,
  });

  final VenueFavoritesController controller;
  final MapVenue venue;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final selected = controller.isFavorite(venue.venueId);
      return Semantics(
        toggled: selected,
        child: Tooltip(
          message: selected ? 'お気に入りから外す' : 'お気に入りに登録',
          child: OutlinedButton.icon(
            icon: Icon(
              selected ? Icons.star_rounded : Icons.star_border_rounded,
            ),
            label: Text(selected ? '解除' : 'お気に入りに登録'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF143861),
              iconColor: selected
                  ? const Color(0xFFE8A600)
                  : const Color(0xFF143861),
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              side: const BorderSide(color: Color(0xFFCBD2DC)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: controller.isLoading || controller.isSaving
                ? null
                : () async {
                    if (controller.errorMessage != null) {
                      await controller.reload();
                      return;
                    }
                    final saved = await controller.toggle(venue);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          saved
                              ? (controller.isFavorite(venue.venueId)
                                    ? 'お気に入りに追加しました'
                                    : 'お気に入りから外しました')
                              : 'お気に入りを保存できませんでした。もう一度お試しください。',
                        ),
                      ),
                    );
                  },
          ),
        ),
      );
    },
  );
}

class VenueHeaderActions extends StatelessWidget {
  const VenueHeaderActions({
    super.key,
    required this.controller,
    required this.venue,
    required this.onOpenMaps,
  });

  final VenueFavoritesController controller;
  final MapVenue venue;
  final VoidCallback onOpenMaps;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      VenueFavoriteButton(controller: controller, venue: venue),
      FilledButton.icon(
        onPressed: onOpenMaps,
        icon: const Icon(Icons.open_in_new, size: 17),
        label: const Text('マップで開く'),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF143861),
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ],
  );
}

class VenueFavoritesSheet extends StatelessWidget {
  const VenueFavoritesSheet({
    super.key,
    required this.controller,
    required this.onShowVenue,
    required this.onOpenMaps,
  });

  final VenueFavoritesController controller;
  final ValueChanged<MapVenue> onShowVenue;
  final ValueChanged<MapVenue> onOpenMaps;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: FractionallySizedBox(
      heightFactor: .75,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.star_rounded, color: Color(0xFFE8A600)),
            title: const Text('お気に入りのお店'),
            trailing: IconButton(
              tooltip: '閉じる',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                if (controller.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          controller.errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        TextButton(
                          onPressed: controller.reload,
                          child: const Text('再試行'),
                        ),
                      ],
                    ),
                  );
                }
                if (controller.venues.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'お気に入りのお店はまだありません。\n地図でお店を選び、星を押すとここに保存できます。',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: controller.venues.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final venue = controller.venues[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(venue.displayName),
                          onTap: () => onShowVenue(venue),
                          trailing: VenueFavoriteButton(
                            controller: controller,
                            venue: venue,
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            TextButton.icon(
                              onPressed: () => onShowVenue(venue),
                              icon: const Icon(Icons.place_outlined),
                              label: const Text('日本酒マップで見る'),
                            ),
                            TextButton.icon(
                              onPressed: () => onOpenMaps(venue),
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Googleマップ'),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
