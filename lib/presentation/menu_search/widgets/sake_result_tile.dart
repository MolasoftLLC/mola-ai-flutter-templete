import 'package:flutter/material.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';

/// 検出された日本酒1件分の表示タイルを構築するWidget
class SakeResultTile extends StatelessWidget {
  const SakeResultTile({
    super.key,
    required this.sake,
    required this.detailedSake,
    required this.hasDetails,
    required this.isItemLoading,
    required this.hasFailed,
    required this.isFavorited,
    required this.isLoading,
    required this.recommendationScore,
    required this.onToggleFavorite,
    required this.buildInfoRow,
    required this.buildTypesRow,
  });

  final Sake sake;
  final Sake? detailedSake;
  final bool hasDetails;
  final bool isItemLoading;
  final bool hasFailed;
  final bool isFavorited;
  final bool isLoading;
  final num? recommendationScore;
  final VoidCallback onToggleFavorite;
  final Widget Function(String key, String value, IconData icon) buildInfoRow;
  final Widget Function(List<String> types) buildTypesRow;

  @override
  Widget build(BuildContext context) {
    final bool isRecommended = recommendationScore != null && recommendationScore! >= 7;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ExpansionTile(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      hasDetails ? (detailedSake!.name ?? 'Unknown') : (sake.name ?? 'Unknown'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: IconButton(
                      icon: Icon(
                        isFavorited ? Icons.favorite : Icons.favorite_border,
                        color: isFavorited ? Colors.red : Colors.grey,
                        size: 24,
                      ),
                      onPressed: onToggleFavorite,
                    ),
                  ),
                ],
              ),
              if (isRecommended)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                        (recommendationScore ?? 0) >= 8 ? '超おすすめ！' : 'おすすめ！',
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
            sake.type ?? '種類不明',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          trailing: hasDetails
              ? const Icon(size: 30, Icons.expand_circle_down, color: Color(0xFF1D3567))
              : !hasFailed
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF1D3567),
                      ),
                    )
                  : isLoading
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
            if (hasDetails)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (detailedSake!.brewery != null)
                      buildInfoRow('蔵元', detailedSake!.brewery!, Icons.home_work),
                    if (detailedSake!.taste != null)
                      buildInfoRow('味わい', detailedSake!.taste!, Icons.restaurant),
                    if (detailedSake!.sakeMeterValue != null)
                      buildInfoRow('日本酒度', '${detailedSake!.sakeMeterValue}', Icons.science),
                    if (detailedSake!.types != null && detailedSake!.types!.isNotEmpty)
                      buildTypesRow(detailedSake!.types!),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      isItemLoading ? Icons.hourglass_top : Icons.error_outline,
                      color: isItemLoading ? const Color(0xFF1D3567) : Colors.red.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isItemLoading ? '詳細情報を取得中...' : '詳細情報を取得できませんでした',
                        style: TextStyle(
                          color: isItemLoading ? const Color(0xFF1D3567) : Colors.red.shade700,
                          fontStyle: isItemLoading ? FontStyle.italic : FontStyle.normal,
                          fontWeight: isItemLoading ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
} 