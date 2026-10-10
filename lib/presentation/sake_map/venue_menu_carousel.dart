import 'package:mola_gemini_flutter_template/common/analytics/app_analytics.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../common/utils/file_utils.dart';
import '../../domain/eintities/menu_analysis_history.dart';

/// Compact menu photos above the venue's vertically scrolling sake list.
class VenueMenuCarousel extends StatelessWidget {
  const VenueMenuCarousel({super.key, required this.menus});

  final List<MenuAnalysisHistoryItem> menus;

  void _openPhoto(BuildContext context, MenuAnalysisHistoryItem menu) {
    AppAnalytics.instance.event('map', 'history');
    showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  maxScale: 5,
                  child: Image(
                    image: FileUtils.safeLoadImage(
                      menu.imagePath,
                      base64Image: menu.base64Image,
                    ),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text(
                        '画像を読み込めませんでした。',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  tooltip: '閉じる',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (menus.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'メニュー',
            style: TextStyle(
              color: Color(0xFF143861),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          height: 118,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: menus.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final menu = menus[index];
              return SizedBox(
                width: 136,
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _openPhoto(context, menu),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Image(
                            image: ResizeImage.resizeIfNeeded(
                              408,
                              null,
                              FileUtils.safeLoadImage(
                                menu.imagePath,
                                base64Image: menu.base64Image,
                              ),
                            ),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.menu_book_outlined,
                              color: Color(0xFF647184),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text(
                            DateFormat('yyyy/M/d').format(menu.date),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF647184),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
