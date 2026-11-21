import 'package:flutter/material.dart';

/// お店のお気に入り一覧。保存操作の星と区別できる星＋リスト。
class VenueFavoritesAction extends StatelessWidget {
  const VenueFavoritesAction({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'お気に入りのお店一覧',
    onPressed: onPressed,
    icon: const SizedBox(
      width: 36,
      height: 24,
      child: Row(
        children: [
          Icon(Icons.star_outline_rounded, size: 21, color: Color(0xFFFFCC32)),
          Icon(
            Icons.format_list_bulleted_rounded,
            size: 15,
            color: Color(0xFFFFCC32),
          ),
        ],
      ),
    ),
  );
}
