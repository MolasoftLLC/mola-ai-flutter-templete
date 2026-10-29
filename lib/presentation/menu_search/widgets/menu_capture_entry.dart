import 'package:flutter/material.dart';
import '../../../common/localization/localization_extensions.dart';
import '../../../domain/eintities/menu_analysis_history.dart';
import 'menu_photo_style.dart';
import 'menu_history_tile.dart';

class MenuCaptureEntry extends StatelessWidget {
  const MenuCaptureEntry({
    super.key,
    required this.history,
    required this.onCamera,
    required this.onGallery,
    required this.onHistory,
    required this.onMore,
  });
  final List<MenuAnalysisHistoryItem> history;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final ValueChanged<String> onHistory;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.menuCaptureTagline,
          style: MenuPhotoStyle.text(23, bold: true).copyWith(height: 34 / 23),
        ),
        const SizedBox(height: 14),
        Semantics(
          button: true,
          label: context.l10n.menuCapturePhoto,
          onTap: onCamera,
          excludeSemantics: true,
          child: Material(
            key: const ValueKey('menu-capture-button'),
            color: Colors.white,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(
                color: MenuPhotoStyle.scanOrange,
                width: 3,
              ),
            ),
            child: InkWell(
              onTap: onCamera,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                constraints: const BoxConstraints(minHeight: 160),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/menu_capture_illustration.png',
                      width: 176,
                      height: 92,
                      fit: BoxFit.contain,
                      cacheWidth: 528,
                      excludeFromSemantics: true,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.menuCapturePhoto,
                      style: MenuPhotoStyle.text(
                        21,
                        bold: true,
                        color: MenuPhotoStyle.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextButton(
          onPressed: onGallery,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(44),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const MenuPhotoIcon('photo'),
              const SizedBox(width: 10),
              Text(
                context.l10n.menuChoosePhoto,
                style: MenuPhotoStyle.text(15, bold: true),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.menuRecentAnalyses,
                style: MenuPhotoStyle.text(16, bold: true),
              ),
            ),
            TextButton(
              onPressed: onMore,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 28),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                context.l10n.menuViewMore,
                style: MenuPhotoStyle.text(12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (history.isEmpty)
          Text(context.l10n.noMenuHistory, style: MenuPhotoStyle.text(13)),
        for (final item in history.take(5))
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: MenuHistoryTile(item: item, onTap: () => onHistory(item.id)),
          ),
      ],
    ),
  );
}
