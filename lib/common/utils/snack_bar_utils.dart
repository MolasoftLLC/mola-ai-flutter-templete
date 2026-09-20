import 'package:flutter/material.dart';

class SnackBarAvoidanceScope extends InheritedWidget {
  const SnackBarAvoidanceScope({
    super.key,
    required this.bottomObstacleHeight,
    required super.child,
  });

  final double bottomObstacleHeight;

  static double bottomObstacleHeightOf(BuildContext context) =>
      context
          .getInheritedWidgetOfExactType<SnackBarAvoidanceScope>()
          ?.bottomObstacleHeight ??
      0;

  @override
  bool updateShouldNotify(SnackBarAvoidanceScope oldWidget) =>
      bottomObstacleHeight != oldWidget.bottomObstacleHeight;
}

/// SnackBarを表示するためのユーティリティクラス
class SnackBarUtils {
  /// 画面下部にSnackBarを表示する
  static void showSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    Color backgroundColor = Colors.black87,
    Color textColor = Colors.white,
    SnackBarAction? action,
    IconData? leadingIcon,
  }) {
    // 既存のSnackBarを閉じる
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // 新しいSnackBarを表示
    final content = leadingIcon == null
        ? Text(message, style: TextStyle(color: textColor))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(leadingIcon, color: textColor, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(message, style: TextStyle(color: textColor)),
              ),
            ],
          );

    final bottomObstacleHeight = SnackBarAvoidanceScope.bottomObstacleHeightOf(
      context,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: content,
        duration: duration,
        backgroundColor: backgroundColor,
        action: action,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomObstacleHeight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// エラー表示用のSnackBar
  static void showErrorSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.red.shade800,
      duration: duration,
    );
  }

  /// 情報表示用のSnackBar
  static void showInfoSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    showSnackBar(
      context,
      message: message,
      backgroundColor: const Color(0xFF1D3567),
      leadingIcon: Icons.check_circle,
      duration: duration,
    );
  }

  /// 警告表示用のSnackBar
  static void showWarningSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.orange.shade800,
      duration: duration,
    );
  }
}
