import 'package:flutter/material.dart';

import '../../domain/repository/place_map_repository.dart';
import 'venue_favorites_controller.dart';

class VenueFavoriteButton extends StatelessWidget {
  const VenueFavoriteButton({
    super.key,
    required this.controller,
    required this.venue,
    this.compact = false,
  });

  final VenueFavoritesController controller;
  final MapVenue venue;
  final bool compact;

  Future<void> _toggle(BuildContext context) async {
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
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final selected = controller.isFavorite(venue.venueId);
      return Semantics(
        toggled: selected,
        child: Tooltip(
          message: selected ? 'お気に入りから外す' : 'お気に入りに登録',
          child: compact
              ? IconButton.filledTonal(
                  constraints: const BoxConstraints.tightFor(
                    width: 44,
                    height: 44,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF6D9),
                    foregroundColor: const Color(0xFFE8A600),
                    disabledBackgroundColor: const Color(0xFFF3F4F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    selected ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 23,
                  ),
                  onPressed: controller.isLoading || controller.isSaving
                      ? null
                      : () => _toggle(context),
                )
              : OutlinedButton.icon(
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
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
                      : () => _toggle(context),
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

  static const _navy = Color(0xFF143861);
  static const _background = Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) => Material(
    color: _background,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
    clipBehavior: Clip.antiAlias,
    child: SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .78,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 34,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD2D9E2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF2C5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFE8A600),
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'お気に入りのお店',
                      style: TextStyle(
                        color: _navy,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '閉じる',
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      foregroundColor: const Color(0xFF718094),
                    ),
                    icon: const Icon(Icons.close, size: 22),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  if (controller.isLoading)
                    return const SizedBox(
                      height: 180,
                      child: Center(
                        child: CircularProgressIndicator(color: _navy),
                      ),
                    );
                  if (controller.errorMessage != null) {
                    return SizedBox(
                      height: 200,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.refresh_rounded,
                                color: Color(0xFF718094),
                                size: 30,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                controller.errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: _navy,
                                  height: 1.6,
                                ),
                              ),
                              TextButton(
                                onPressed: controller.reload,
                                child: const Text('再試行'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  if (controller.venues.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.fromLTRB(28, 24, 28, 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_border_rounded,
                            color: Color(0xFF9AA8B8),
                            size: 42,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'お気に入りのお店はまだありません。',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _navy,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '地図でお店を選び、星を押すとここに保存できます。',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF718094),
                              fontSize: 13,
                              height: 1.7,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: controller.venues.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _venueCard(context, controller.venues[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _venueCard(BuildContext context, MapVenue venue) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE7ECF2)),
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InkWell(
                onTap: () => onShowVenue(venue),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Text(
                    venue.displayName,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            VenueFavoriteButton(
              controller: controller,
              venue: venue,
              compact: true,
            ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final primary = FilledButton.icon(
              onPressed: () => onShowVenue(venue),
              icon: const Icon(Icons.place_outlined, size: 18),
              label: const Text('日本酒マップで見る'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFD84D),
                foregroundColor: _navy,
                minimumSize: const Size(0, 46),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
                textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
            final secondary = OutlinedButton.icon(
              onPressed: () => onOpenMaps(venue),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Googleマップ'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _navy,
                minimumSize: const Size(0, 46),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                side: const BorderSide(color: Color(0xFFDEE5ED)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
                textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
            if (constraints.maxWidth < 310 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.2) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [primary, const SizedBox(height: 8), secondary],
              );
            }
            return Row(
              children: [
                Expanded(flex: 6, child: primary),
                const SizedBox(width: 8),
                Expanded(flex: 5, child: secondary),
              ],
            );
          },
        ),
      ],
    ),
  );
}
