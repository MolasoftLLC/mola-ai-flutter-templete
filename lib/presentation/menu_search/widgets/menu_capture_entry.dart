import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../common/localization/localization_extensions.dart';
import '../../../common/utils/file_utils.dart';
import '../../../domain/eintities/menu_analysis_history.dart';
import 'menu_photo_style.dart';

class MenuCaptureEntry extends StatelessWidget {
  const MenuCaptureEntry({
    super.key,
    required this.history,
    required this.onCamera,
    required this.onGallery,
    required this.onHistory,
    required this.onMore,
    this.onResume,
  });
  final List<MenuAnalysisHistoryItem> history;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final ValueChanged<String> onHistory;
  final VoidCallback onMore;
  final VoidCallback? onResume;

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
        Material(
          color: MenuPhotoStyle.yellow,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onCamera,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              constraints: const BoxConstraints(minHeight: 140),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MenuPhotoIcon('camera', size: 40),
                  const SizedBox(height: 10),
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
        if (onResume != null)
          TextButton(
            onPressed: onResume,
            child: Text(
              context.l10n.menuResumePhoto,
              style: MenuPhotoStyle.text(13),
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
        for (final item in history.take(2))
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Material(
              color: MenuPhotoStyle.deep,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => onHistory(item.id),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image(
                          image: FileUtils.safeLoadImage(
                            item.imagePath,
                            base64Image: item.base64Image,
                          ),
                          width: 38,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.storeName?.isNotEmpty == true
                                  ? item.storeName!
                                  : context.l10n.menuDatedHistory(
                                      DateFormat.Md(
                                        Localizations.localeOf(
                                          context,
                                        ).toLanguageTag(),
                                      ).format(item.date.toLocal()),
                                    ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: MenuPhotoStyle.text(14, bold: true),
                            ),
                            Text(
                              '${DateFormat.Md(Localizations.localeOf(context).toLanguageTag()).format(item.date.toLocal())}  |  ${context.l10n.sakeCount(item.sakes.length)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: MenuPhotoStyle.text(11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('›', style: MenuPhotoStyle.text(23)),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
