import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart' as flutter;

/// バックグラウンド処理を行うサービス
class BackgroundService {
  /// バックグラウンドで処理を実行する
  /// 
  /// [computation] バックグラウンドで実行する処理
  /// [input] 処理に渡す入力データ
  static Future<T> compute<Q, T>(
    FutureOr<T> Function(Q) computation,
    Q input,
  ) {
    return flutter.compute(computation, input);
  }
}

/// メニュー解析のバックグラウンド処理用のデータクラス
class MenuAnalysisData {
  final File file;
  final String baseUrl;
  final String apiKey;
  
  MenuAnalysisData({
    required this.file,
    required this.baseUrl,
    required this.apiKey,
  });
}

/// メニュー解析のバックグラウンド処理の結果クラス
class MenuAnalysisResult {
  final Map<String, dynamic>? data;
  final String? error;
  
  MenuAnalysisResult({
    this.data,
    this.error,
  });
  
  bool get isSuccess => error == null && data != null;
}
