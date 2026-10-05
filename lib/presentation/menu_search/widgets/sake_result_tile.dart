import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/menu_sake_resolution.dart';

import '../../../common/utils/snack_bar_utils.dart';
import '../../../common/utils/sake_image_utils.dart';
import '../../../common/localization/localization_extensions.dart';
import 'package:provider/provider.dart';
import '../../../domain/eintities/sake_label_scan.dart';
import '../../../domain/notifier/my_page/my_page_notifier.dart';
import '../../../common/sake/taste_match.dart';
import '../../common/widgets/sake_taste_widgets.dart';

/// 検出された日本酒1件分の表示タイルを構築するWidget
class SakeResultTile extends StatefulWidget {
  const SakeResultTile({
    super.key,
    required this.sake,
    required this.detailedSake,
    required this.hasDetails,
    required this.isItemLoading,
    required this.hasFailed,
    required this.isFavorited,
    required this.isSaved,
    required this.isLoading,
    required this.matchPercent,
    this.tasteProfile,
    required this.isUnverified,
    required this.candidates,
    required this.onCandidateSelected,
    required this.onOpenDetails,
    required this.onToggleFavorite,
    required this.onSave,
    required this.buildInfoRow,
    required this.buildTypesRow,
  });

  final Sake sake;
  final Sake? detailedSake;
  final bool hasDetails;
  final bool isItemLoading;
  final bool hasFailed;
  final bool isFavorited;
  final bool isSaved;
  final bool isLoading;
  final int? matchPercent;
  final SakeTasteProfileDetails? tasteProfile;
  final bool isUnverified;
  final List<MenuSakeCandidate> candidates;
  final ValueChanged<MenuSakeCandidate> onCandidateSelected;
  final VoidCallback? onOpenDetails;
  final Future<void> Function() onToggleFavorite;

  /// 保存ボタンタップ時に呼び出されるコールバック。成功した場合は`true`を返す。
  final Future<bool> Function() onSave;
  final Widget Function(String key, String value, IconData icon) buildInfoRow;
  final Widget Function(List<String> types) buildTypesRow;

  @override
  State<SakeResultTile> createState() => _SakeResultTileState();
}

class _SakeResultTileState extends State<SakeResultTile> {
  late final ExpansionTileController _expansionController;

  @override
  void initState() {
    super.initState();
    _expansionController = ExpansionTileController();
  }

  @override
  void didUpdateWidget(covariant SakeResultTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tasteProfile == null && widget.tasteProfile != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_expansionController.isExpanded) {
          _expansionController.expand();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.tasteProfile;
    final imagePath = preferredSakeImagePath(
      thumbnailImageUrl: widget.detailedSake?.thumbnailImageUrl,
      primaryImageUrl: widget.detailedSake?.primaryImageUrl,
    );
    final imageUri = imagePath == null || isSakePlaceholderImagePath(imagePath)
        ? null
        : Uri.tryParse(
            imagePath.startsWith('/')
                ? Uri.parse(sakeNoImageUrl).resolve(imagePath).toString()
                : imagePath,
          );
    final hasPhoto =
        imageUri != null &&
        (imageUri.scheme == 'https' || imageUri.scheme == 'http');
    final preference = Provider.of<MyPageState?>(context)?.tasteProfile;
    final matchPercent = profile == null
        ? widget.matchPercent
        : calculateOptionalSakeTasteMatchPercent(
            profile: profile,
            preference: preference,
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 0),
      child: Stack(
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              initiallyExpanded: profile != null,
              controller: _expansionController,
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (hasPhoto) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            imageUri.toString(),
                            width: 44,
                            height: 56,
                            fit: BoxFit.contain,
                            excludeFromSemantics: true,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          widget.hasDetails
                              ? (widget.detailedSake!.name ??
                                    context.l10n.unknown)
                              : (widget.sake.name ?? context.l10n.unknown),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (matchPercent != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFF143861),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SakePreferenceMatchSection(
                          percent: matchPercent,
                          fullWidth: true,
                        ),
                      ),
                    ),
                  if (widget.isUnverified)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'AI補完（未確認）',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.sake.type ?? context.l10n.unknownType,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  if (!widget.hasDetails && widget.candidates.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: InkWell(
                        onTap: () => _showCandidatePicker(context),
                        borderRadius: BorderRadius.circular(4),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            '候補が複数あります。商品を選択してください。',
                            style: TextStyle(
                              color: Color(0xFF1D3567),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              trailing: widget.hasDetails
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: '商品詳細を開く',
                          icon: const Icon(Icons.open_in_new, size: 21),
                          onPressed: widget.onOpenDetails,
                        ),
                        IconButton(
                          tooltip: widget.isSaved
                              ? context.l10n.removeSavedSake
                              : context.l10n.saveSake,
                          icon: Icon(
                            widget.isSaved
                                ? Icons.bookmark
                                : Icons.bookmark_outline,
                            color: widget.isSaved
                                ? const Color(0xFF1D3567)
                                : Colors.grey,
                            size: 22,
                          ),
                          onPressed: () async {
                            final wasSaved = widget.isSaved;
                            final success = await widget.onSave();
                            if (success && !wasSaved) {
                              SnackBarUtils.showInfoSnackBar(
                                context,
                                message: context.l10n.savedToMyPage,
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: widget.isFavorited
                              ? context.l10n.removeFavorite
                              : context.l10n.favorite,
                          icon: Icon(
                            widget.isFavorited
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: widget.isFavorited
                                ? Colors.red
                                : Colors.grey,
                            size: 22,
                          ),
                          onPressed: () {
                            unawaited(widget.onToggleFavorite());
                          },
                        ),
                      ],
                    )
                  : widget.candidates.isNotEmpty
                  ? IconButton(
                      tooltip: '候補を選択',
                      icon: const Icon(Icons.rule, color: Color(0xFF1D3567)),
                      onPressed: () => _showCandidatePicker(context),
                    )
                  : !widget.hasFailed
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF1D3567),
                      ),
                    )
                  : widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF1D3567),
                      ),
                    )
                  : Icon(Icons.error_outline, color: Colors.red.shade700),
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
                      preferenceAxes: preference == null
                          ? null
                          : [
                              SakeTasteAxis('フルーティ', preference.fruity),
                              SakeTasteAxis('甘み', preference.sweetness),
                              SakeTasteAxis('酸味', preference.acidity),
                              SakeTasteAxis('コク', preference.umami),
                              SakeTasteAxis('キレ', preference.kire),
                              SakeTasteAxis('辛さ', preference.spiciness),
                            ],
                    ),
                  ),
                  if (preference != null) ...[
                    const SizedBox(height: 8),
                    const SakeTasteChartLegend(),
                  ],
                  const SizedBox(height: 12),
                ],

                if (widget.hasDetails)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.detailedSake!.description
                                ?.trim()
                                .isNotEmpty ==
                            true) ...[
                          const Text(
                            'このお酒について',
                            style: TextStyle(
                              color: Color(0xFF143861),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.detailedSake!.description!.trim(),
                            style: const TextStyle(
                              height: 1.75,
                              color: Color(0xFF404A56),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (widget.detailedSake!.brewery != null)
                          widget.buildInfoRow(
                            context.l10n.brewery,
                            widget.detailedSake!.brewery!,
                            Icons.home_work,
                          ),
                        if (widget.detailedSake!.sakeMeterValue != null)
                          widget.buildInfoRow(
                            context.l10n.sakeMeterValue,
                            '${widget.detailedSake!.sakeMeterValue}',
                            Icons.science,
                          ),
                        if (widget.detailedSake!.types != null &&
                            widget.detailedSake!.types!.isNotEmpty)
                          widget.buildTypesRow(widget.detailedSake!.types!),
                        const SizedBox(height: 4),
                      ],
                    ),
                  )
                else if (widget.candidates.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          widget.isItemLoading
                              ? Icons.hourglass_top
                              : Icons.error_outline,
                          color: widget.isItemLoading
                              ? const Color(0xFF1D3567)
                              : Colors.red.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.isItemLoading
                                ? context.l10n.loadingDetails
                                : context.l10n.detailsUnavailable,
                            style: TextStyle(
                              color: widget.isItemLoading
                                  ? const Color(0xFF1D3567)
                                  : Colors.red.shade700,
                              fontStyle: widget.isItemLoading
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                              fontWeight: widget.isItemLoading
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (widget.hasDetails)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: IconButton(
                    tooltip: context.l10n.expand,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    icon: const Icon(
                      Icons.expand_more,
                      color: Color(0xFF1D3567),
                      size: 28,
                    ),
                    onPressed: () {
                      if (_expansionController.isExpanded) {
                        _expansionController.collapse();
                      } else {
                        _expansionController.expand();
                      }
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showCandidatePicker(BuildContext context) async {
    final selected = await showModalBottomSheet<MenuSakeCandidate>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text('該当する商品を選択'),
              subtitle: Text('米・製法・生酒などを確認して選んでください'),
            ),
            for (final candidate in widget.candidates)
              ListTile(
                title: Text(candidate.sake.name ?? '名称不明'),
                subtitle: Text(
                  [candidate.sake.brewery, candidate.sake.type]
                      .whereType<String>()
                      .where((value) => value.isNotEmpty)
                      .join(' / '),
                ),
                onTap: () => Navigator.of(context).pop(candidate),
              ),
          ],
        ),
      ),
    );
    if (selected != null) widget.onCandidateSelected(selected);
  }
}
