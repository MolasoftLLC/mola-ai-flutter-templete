import 'package:mola_gemini_flutter_template/common/analytics/app_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../common/localization/localization_extensions.dart';
import '../../../common/utils/file_utils.dart';
import '../../common/widgets/primary_app_bar.dart';
import '../../menu_search/menu_search_page_notifier.dart';
import '../../menu_search/widgets/menu_history_section.dart';

class MenuHistoryPreview extends StatelessWidget {
  const MenuHistoryPreview._();

  static Widget wrapped({String? ownerKey}) =>
      StateNotifierProvider<MenuSearchPageNotifier, MenuSearchPageState>(
        key: ValueKey('my-page-menu-history-${ownerKey ?? 'guest'}'),
        create: (context) => MenuSearchPageNotifier(context: context),
        child: const MenuHistoryPreview._(),
      );

  Future<void> _openHistory(BuildContext context, {String? historyId}) async {
    AppAnalytics.instance.event(
      'my_page',
      historyId == null ? 'more' : 'history',
    );
    final notifier = context.read<MenuSearchPageNotifier>();
    if (historyId != null) {
      // Populate missing details in older histories without another AI analysis.
      notifier.restoreHistoryDetails(historyId);
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            StateNotifierProvider<
              MenuSearchPageNotifier,
              MenuSearchPageState
            >.value(
              value: notifier,
              child: AnalyticsScreen(
                name: 'menu',
                child: Scaffold(
                  backgroundColor: const Color(0xFF1D3567),
                  appBar: PrimaryAppBar(title: context.l10n.pastMenuAnalysis),
                  body: SingleChildScrollView(
                    child: MenuHistorySection(
                      historyId: historyId,
                      showHeading: false,
                    ),
                  ),
                ),
              ),
            ),
      ),
    );
    if (context.mounted) await notifier.loadMenuAnalysisHistory();
  }

  @override
  Widget build(BuildContext context) {
    final histories = context.select(
      (MenuSearchPageState state) => state.menuAnalysisHistory,
    );
    final latest = histories.toList()..sort((a, b) => b.date.compareTo(a.date));
    final locale = Localizations.localeOf(context);
    final dateFormat = DateFormat.yMd(locale.toLanguageTag()).add_Hm();
    return VisibilityDetector(
      key: const Key('my-page-menu-history-visibility'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0 && context.mounted) {
          context.read<MenuSearchPageNotifier>().loadMenuAnalysisHistory();
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  const Icon(Icons.menu_book, color: Colors.amber, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      locale.languageCode == 'ja' ? 'メニュー解析履歴' : 'Menu history',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (histories.isNotEmpty)
                    TextButton(
                      onPressed: () => _openHistory(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.amber,
                      ),
                      child: Text(
                        locale.languageCode == 'ja' ? 'もっと見る' : 'View more',
                      ),
                    ),
                ],
              ),
            ),
            if (latest.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                child: Text(
                  context.l10n.noMenuHistory,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            for (final item in latest.take(3))
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Material(
                  color: Colors.white.withValues(alpha: .07),
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image(
                        image: FileUtils.safeLoadImage(
                          item.imagePath,
                          base64Image: item.base64Image,
                        ),
                        width: 48,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(
                          width: 48,
                          height: 56,
                          child: Icon(Icons.menu_book, color: Colors.white54),
                        ),
                      ),
                    ),
                    title: Text(
                      item.storeName?.trim().isNotEmpty == true
                          ? item.storeName!
                          : dateFormat.format(item.date.toLocal()),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      [
                        if (item.storeName?.trim().isNotEmpty == true)
                          dateFormat.format(item.date.toLocal()),
                        context.l10n.sakeCount(item.sakes.length),
                      ].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.white54,
                      size: 20,
                    ),
                    onTap: () => _openHistory(context, historyId: item.id),
                  ),
                ),
              ),
            if (latest.isNotEmpty) const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
