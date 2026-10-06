import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:mola_gemini_flutter_template/common/utils/file_utils.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/menu_analysis_history.dart';
import 'package:mola_gemini_flutter_template/presentation/menu_search/menu_search_page_notifier.dart';

import '../../../common/localization/localization_extensions.dart';
import '../../../common/sake/menu_taste_summary.dart';
import '../../../domain/repository/place_map_repository.dart';
import '../../my_page/widgets/place_picker_sheet.dart';
import '../../sake_map/sake_master_detail_page.dart';
import '../../common/widgets/sake_taste_widgets.dart';

class MenuHistorySection extends StatelessWidget {
  const MenuHistorySection({
    super.key,
    this.historyId,
    this.showHeading = true,
  });

  final String? historyId;
  final bool showHeading;

  // 削除確認ダイアログを表示する
  void showDeleteConfirmationDialog({
    required BuildContext context,
    required String historyId,
    required Function onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.l10n.deleteConfirmation),
          content: Text(context.l10n.deleteMenuHistoryConfirmation),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ダイアログを閉じる
              },
              child: Text(context.l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                onConfirm(); // 削除を実行
                Navigator.of(context).pop(); // ダイアログを閉じる
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(context.l10n.delete),
            ),
          ],
        );
      },
    );
  }

  // 画像を拡大表示するダイアログを表示する
  void _showEnlargedImage(
    BuildContext context,
    MenuAnalysisHistoryItem historyItem,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pop(); // タップでダイアログを閉じる
            },
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: Image(
                image: FileUtils.safeLoadImage(
                  historyItem.imagePath,
                  base64Image: historyItem.base64Image,
                ),
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<MenuSearchPageNotifier>();
    final histories = context.select(
      (MenuSearchPageState state) => state.menuAnalysisHistory,
    );
    final menuAnalysisHistory = historyId == null
        ? histories
        : histories.where((item) => item.id == historyId).toList();

    return Container(
      padding: EdgeInsets.only(
        top: showHeading ? 42 : 12,
        left: 12,
        right: 12,
        bottom: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeading)
            Center(
              child: Text(
                context.l10n.pastMenuAnalysis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          if (showHeading) const SizedBox(height: 16),
          // 履歴がない場合のメッセージ
          if (menuAnalysisHistory.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  context.l10n.noMenuHistory,
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: menuAnalysisHistory.length,
              itemBuilder: (context, index) {
                final historyItem = menuAnalysisHistory[index];

                // 日付をフォーマット
                final dateFormat = DateFormat.yMd(
                  Localizations.localeOf(context).toLanguageTag(),
                ).add_Hm();
                final formattedDate = dateFormat.format(
                  historyItem.date.toLocal(),
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ExpansionTile(
                      key: PageStorageKey(historyItem.id),
                      initiallyExpanded: historyId != null,
                      onExpansionChanged: (expanded) {
                        if (expanded)
                          notifier.restoreHistoryDetails(historyItem.id);
                      },
                      leading:
                          (historyItem.imagePath != null ||
                              (historyItem.base64Image != null &&
                                  historyItem.base64Image!.isNotEmpty))
                          ? GestureDetector(
                              onTap: () {
                                _showEnlargedImage(context, historyItem);
                              },
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: FileUtils.safeLoadImage(
                                      historyItem.imagePath,
                                      base64Image: historyItem.base64Image,
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            )
                          : null,
                      title: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (historyItem.storeName != null)
                                  Text(
                                    historyItem.storeName!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    fontSize: historyItem.storeName != null
                                        ? 12
                                        : 14,
                                    color: Colors.grey,
                                    fontWeight: historyItem.storeName != null
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 飲んだ場所の登録ボタン
                          IconButton(
                            tooltip: context.l10n.placeConsumed,
                            icon: const Icon(
                              Icons.location_on_outlined,
                              size: 20,
                              color: Color(0xFF1D3567),
                            ),
                            onPressed: () async {
                              final place = await PlacePickerSheet.show(
                                context,
                                initialPlace:
                                    historyItem.drinkingPlace?.displayName ??
                                    historyItem.storeName,
                              );
                              if (place != null) {
                                await notifier.setHistoryPlace(
                                  historyItem.id,
                                  place,
                                );
                              }
                            },
                          ),
                          // 削除ボタン
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              size: 20,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              showDeleteConfirmationDialog(
                                context: context,
                                historyId: historyItem.id,
                                onConfirm: () {
                                  notifier.deleteHistoryItem(historyItem.id);
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      subtitle: Row(
                        children: [
                          Text(
                            context.l10n.sakeCount(historyItem.sakes.length),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          if (historyItem.analysisStatus != 'complete') ...[
                            const SizedBox(width: 8),
                            Text(
                              historyItem.analysisStatus == 'details_pending'
                                  ? context.l10n.menuHistoryPending
                                  : context.l10n.menuHistoryPartial,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (historyItem.drinkingPlace != null) ...[
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(
                                    Icons.location_on_outlined,
                                  ),
                                  title: Text(
                                    historyItem.drinkingPlace!.displayName,
                                  ),
                                  onTap: () {
                                    final place = historyItem.drinkingPlace!;
                                    final uri = Uri.https(
                                      'www.google.com',
                                      '/maps/search/',
                                      {
                                        'api': '1',
                                        'query': place.displayName,
                                        if (place.providerPlaceId != null)
                                          'query_place_id':
                                              place.providerPlaceId!,
                                      },
                                    );
                                    launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  },
                                  subtitle:
                                      historyItem
                                              .drinkingPlace!
                                              .formattedAddress ==
                                          null
                                      ? null
                                      : Text(
                                          historyItem
                                              .drinkingPlace!
                                              .formattedAddress!,
                                        ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () => notifier.setHistoryPlace(
                                      historyItem.id,
                                      null,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              ...historyItem.sakes.map(
                                (sake) => _HistorySakeTile(
                                  sake: sake,
                                  historyId: historyItem.id,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _HistorySakeTile extends StatelessWidget {
  const _HistorySakeTile({required this.sake, required this.historyId});
  final String historyId;
  final SavedSake sake;

  @override
  Widget build(BuildContext context) {
    final details = sake.details;
    final profile = sake.tasteProfile;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: ExpansionTile(
          key: PageStorageKey(
            'history-sake-$historyId-${sake.extractedName ?? sake.name}-${sake.sakeId}',
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sake.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (profile != null)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final tag in menuTasteTags(profile))
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Chip(
                            label: Text(tag),
                            visualDensity: VisualDensity.compact,
                            side: BorderSide.none,
                          ),
                        ),
                    ],
                  ),
                ),
              if (sake.matchPercent != null) ...[
                const SizedBox(height: 8),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF143861),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SakePreferenceMatchSection(
                    percent: sake.matchPercent!,
                    fullWidth: true,
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(sake.type ?? context.l10n.unknownType),
          childrenPadding: const EdgeInsets.all(16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (profile != null) ...[
              Center(
                child: SakeTasteRadarChart(
                  axes: [
                    SakeTasteAxis('フルーティ', profile.fruity),
                    SakeTasteAxis('甘み', profile.sweetness),
                    SakeTasteAxis('酸味', profile.acidity),
                    SakeTasteAxis('コク', profile.body ?? profile.umami),
                    SakeTasteAxis('キレ', profile.kire),
                    SakeTasteAxis('辛さ', profile.dryness),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (details?.description?.isNotEmpty == true)
              Text(details!.description!),
            if (details?.brewery?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(details!.brewery!),
            ],
            if (sake.sakeId != null && sake.sakeId! > 0)
              TextButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: Text(sake.name),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SakeMasterDetailPage(
                      venueSake: VenueSake(
                        sakeId: sake.sakeId!,
                        name: sake.name,
                        brewery: details?.brewery,
                        type: sake.type,
                        recordCount: 0,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
