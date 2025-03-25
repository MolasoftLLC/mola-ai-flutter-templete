import 'package:flutter/material.dart';

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
  }) {
    // 既存のSnackBarを閉じる
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    // 新しいSnackBarを表示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: textColor),
        ),
        duration: duration,
        backgroundColor: backgroundColor,
        action: action,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
      backgroundColor: Colors.blue.shade800,
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