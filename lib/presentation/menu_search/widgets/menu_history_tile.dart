import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../common/localization/localization_extensions.dart';
import '../../../common/utils/file_utils.dart';
import '../../../domain/eintities/menu_analysis_history.dart';
import 'menu_photo_style.dart';

/// One shared row for the latest five and the complete history.
class MenuHistoryTile extends StatelessWidget {
  const MenuHistoryTile({super.key, required this.item, required this.onTap});
  final MenuAnalysisHistoryItem item;
  final VoidCallback onTap;
  static String title(BuildContext context, MenuAnalysisHistoryItem item) =>
      item.storeName?.isNotEmpty == true
      ? item.storeName!
      : context.l10n.menuDatedHistory(
          DateFormat.Md(
            Localizations.localeOf(context).toLanguageTag(),
          ).format(item.date.toLocal()),
        );
  @override
  Widget build(BuildContext context) => Material(
    color: MenuPhotoStyle.deep,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                              Localizations.localeOf(context).toLanguageTag(),
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
  );
}
