import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';

import '../../../common/utils/snack_bar_utils.dart';

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
    required this.recommendationScore,
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
  final num? recommendationScore;
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
  Widget build(BuildContext context) {
    final bool isRecommended =
        widget.recommendationScore != null && widget.recommendationScore! >= 7;

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
              controller: _expansionController,
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.hasDetails
                              ? (widget.detailedSake!.name ?? 'Unknown')
                              : (widget.sake.name ?? 'Unknown'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isRecommended)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.red.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.red.shade700,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            (widget.recommendationScore ?? 0) >= 8
                                ? '超おすすめ！'
                                : 'おすすめ！',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              subtitle: Text(
                widget.sake.type ?? '種類不明',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              trailing: widget.hasDetails
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: widget.isSaved ? '保存を解除' : '保存',
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
                                message: 'マイページに保存しました！',
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: widget.isFavorited ? 'お気に入り解除' : 'お気に入り',
                          icon: Icon(
                            widget.isFavorited
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color:
                                widget.isFavorited ? Colors.red : Colors.grey,
                            size: 22,
                          ),
                          onPressed: () {
                            unawaited(widget.onToggleFavorite());
                          },
                        ),
                      ],
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
                          : Icon(Icons.error_outline,
                              color: Colors.red.shade700),
              children: [
                if (widget.hasDetails)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.detailedSake!.brewery != null)
                          widget.buildInfoRow(
                            '蔵元',
                            widget.detailedSake!.brewery!,
                            Icons.home_work,
                          ),
                        if (widget.detailedSake!.taste != null)
                          widget.buildInfoRow(
                            '味わい',
                            widget.detailedSake!.taste!,
                            Icons.restaurant,
                          ),
                        if (widget.detailedSake!.sakeMeterValue != null)
                          widget.buildInfoRow(
                            '日本酒度',
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
                else
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
                                ? '詳細情報を取得中...'
                                : '詳細情報を取得できませんでした',
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
                    tooltip: '展開',
                    padding: const EdgeInsets.all(8),
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
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
}
