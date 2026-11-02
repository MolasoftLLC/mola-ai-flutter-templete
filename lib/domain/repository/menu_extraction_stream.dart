import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MenuReadingProgress {
  const MenuReadingProgress({this.started = false, this.names = const []});
  final bool started;
  final List<String> names;
}

/// Completed NDJSON objects only; partial output is never a saved analysis.
Future<Map<String, dynamic>> readMenuExtractionStream(
  http.StreamedResponse response,
  void Function(MenuReadingProgress) onProgress,
) async {
  if (response.statusCode != 200) {
    final text = await response.stream.bytesToString();
    String? message;
    try {
      message = (jsonDecode(text) as Map)['error'] as String?;
    } catch (_) {}
    throw MenuExtractionException(
      message ?? 'メニュー解析を開始できませんでした。',
      response.statusCode,
    );
  }
  final names = <String>[];
  await for (final line
      in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
    if (line.trim().isEmpty) continue;
    final event = jsonDecode(line) as Map<String, dynamic>;
    switch (event['event']) {
      case 'started':
        onProgress(const MenuReadingProgress(started: true));
      case 'entry':
        if (event['index'] != names.length ||
            event['sake'] is! Map ||
            event['sake']['name'] is! String) {
          throw const MenuExtractionException('解析結果の受信に失敗しました。');
        }
        names.add(event['sake']['name'] as String);
        onProgress(
          MenuReadingProgress(started: true, names: List.unmodifiable(names)),
        );
      case 'complete':
        final result = event['result'];
        if (result is! Map ||
            result['sakes'] is! List ||
            (result['sakes'] as List).isEmpty ||
            result['analysisId'] is! String) {
          throw const MenuExtractionException('解析結果を確認できませんでした。');
        }
        return Map<String, dynamic>.from(result);
      case 'error':
        throw MenuExtractionException(
          event['error']?.toString() ?? 'メニュー解析に失敗しました。',
        );
    }
  }
  throw const MenuExtractionException('解析の接続が切れました。同じ画像でもう一度お試しください。');
}

class MenuExtractionException implements Exception {
  const MenuExtractionException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}
