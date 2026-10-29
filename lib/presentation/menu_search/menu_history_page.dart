import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:provider/provider.dart';
import '../../common/analytics/app_analytics.dart';
import '../../common/localization/localization_extensions.dart';
import '../../common/utils/file_utils.dart';
import '../../domain/eintities/menu_analysis_history.dart';
import 'menu_search_page_notifier.dart';
import 'widgets/menu_history_list.dart';
import 'widgets/menu_history_tile.dart';
import 'widgets/menu_history_sake_tile.dart';
import 'widgets/menu_photo_style.dart';
import 'widgets/menu_result_place_field.dart';

class MenuHistoryPage extends StatefulWidget {
  const MenuHistoryPage({super.key, this.historyId});
  final String? historyId;

  static Future<void> open(
    BuildContext context,
    MenuSearchPageNotifier notifier, {
    String? historyId,
  }) {
    if (historyId != null) unawaited(notifier.restoreHistoryDetails(historyId));
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            StateNotifierProvider<
              MenuSearchPageNotifier,
              MenuSearchPageState
            >.value(
              value: notifier,
              child: AnalyticsScreen(
                name: 'menu',
                child: MenuHistoryPage(historyId: historyId),
              ),
            ),
      ),
    );
  }

  @override
  State<MenuHistoryPage> createState() => _MenuHistoryPageState();
}

class _MenuHistoryPageState extends State<MenuHistoryPage> {
  String? _cursor;
  Future<bool> _loadMore() async {
    final next = await context
        .read<MenuSearchPageNotifier>()
        .loadMoreMenuHistory(cursor: _cursor);
    _cursor = next;
    return next != null;
  }

  @override
  Widget build(BuildContext context) {
    final history = context.select(
      (MenuSearchPageState state) => state.menuAnalysisHistory,
    );
    final id = widget.historyId;
    final item = id == null
        ? null
        : history.where((item) => item.id == id).firstOrNull;
    return Scaffold(
      backgroundColor: MenuPhotoStyle.blue,
      appBar: MenuPhotoStyle.appBar(
        context.l10n.menuRecentAnalyses,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        top: false,
        child: id == null
            ? MenuHistoryList(
                history: history,
                loadMore: _loadMore,
                onOpen: (id) => MenuHistoryPage.open(
                  context,
                  context.read<MenuSearchPageNotifier>(),
                  historyId: id,
                ),
              )
            : item == null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  context.l10n.noMenuHistory,
                  style: MenuPhotoStyle.text(14),
                ),
              )
            : _MenuHistoryDetail(item: item),
      ),
    );
  }
}

class _MenuHistoryDetail extends StatelessWidget {
  const _MenuHistoryDetail({required this.item});
  final MenuAnalysisHistoryItem item;

  Future<void> _delete(BuildContext context) async {
    final notifier = context.read<MenuSearchPageNotifier>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteConfirmation),
        content: Text(context.l10n.deleteMenuHistoryConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await notifier.deleteHistoryItem(item.id);
      if (context.mounted) Navigator.of(context).pop();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.errorSaveToServer)));
      }
    }
  }

  void _showPhoto(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: MenuPhotoStyle.deep,
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: Image(
              image: FileUtils.safeLoadImage(
                item.imagePath,
                base64Image: item.base64Image,
              ),
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              MenuHistoryTile.title(context, item),
              style: MenuPhotoStyle.text(20, bold: true),
            ),
          ),
          IconButton(
            tooltip: context.l10n.delete,
            onPressed: () => _delete(context),
            icon: const Icon(Icons.delete_outline, color: Colors.white70),
          ),
        ],
      ),
      Text(
        DateFormat.yMd(
          Localizations.localeOf(context).toLanguageTag(),
        ).add_Hm().format(item.date.toLocal()),
        style: MenuPhotoStyle.text(12, color: Colors.white70),
      ),
      const SizedBox(height: 12),
      if (item.imagePath != null || item.base64Image?.isNotEmpty == true) ...[
        Semantics(
          button: true,
          label: context.l10n.menuZoomPhoto,
          child: InkWell(
            onTap: () => _showPhoto(context),
            borderRadius: BorderRadius.circular(14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                color: MenuPhotoStyle.deep,
                width: double.infinity,
                height: 220,
                child: Image(
                  image: FileUtils.safeLoadImage(
                    item.imagePath,
                    base64Image: item.base64Image,
                  ),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
      MenuResultPlaceField(
        history: item,
        onSave: (place) => context
            .read<MenuSearchPageNotifier>()
            .setHistoryPlace(item.id, place),
      ),
      if (item.drinkingPlace?.formattedAddress != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            item.drinkingPlace!.formattedAddress!,
            style: MenuPhotoStyle.text(12, color: Colors.white70),
          ),
        ),
      if (item.drinkingPlace != null)
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              tooltip: context.l10n.navigationMap,
              icon: const Icon(Icons.map_outlined, color: Colors.white70),
              onPressed: () {
                final place = item.drinkingPlace!;
                launchUrl(
                  Uri.https('www.google.com', '/maps/search/', {
                    'api': '1',
                    'query': place.latitude != null && place.longitude != null
                        ? '${place.latitude},${place.longitude}'
                        : place.displayName,
                    if (place.providerPlaceId != null)
                      'query_place_id': place.providerPlaceId!,
                  }),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
            IconButton(
              tooltip: context.l10n.menuRemovePlace,
              icon: const Icon(
                Icons.location_off_outlined,
                color: Colors.white70,
              ),
              onPressed: () async {
                try {
                  await context.read<MenuSearchPageNotifier>().setHistoryPlace(
                    item.id,
                    null,
                  );
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.l10n.errorSaveToServer)),
                    );
                  }
                }
              },
            ),
          ],
        ),
      const SizedBox(height: 24),
      Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.sakeCount(item.sakes.length),
              style: MenuPhotoStyle.text(16, bold: true),
            ),
          ),
          if (item.analysisStatus == 'partial' ||
              item.analysisStatus == 'pending')
            Text(
              item.analysisStatus == 'partial'
                  ? context.l10n.menuHistoryPartial
                  : context.l10n.menuHistoryPending,
              style: MenuPhotoStyle.text(12, color: MenuPhotoStyle.yellow),
            ),
        ],
      ),
      const SizedBox(height: 14),
      for (final sake in item.sakes)
        MenuHistorySakeTile(sake: sake, historyId: item.id),
    ],
  );
}
