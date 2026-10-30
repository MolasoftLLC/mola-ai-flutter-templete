import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/domain/repository/sake_scan_repository.dart';

void main() {
  test('daily allowance keeps server explanation', () {
    final error = SakeScanException.fromResponse(
      429,
      '{"code":"daily_analysis_limit","limit":25,"error":"本日のラベル解析は25回までです。明日またお試しください。"}',
    );
    expect(error.kind, SakeScanErrorKind.dailyLimit);
    expect(error.statusCode, 429);
    expect(error.message, contains('25回'));
    expect(error.message, contains('明日'));
  });
  test('busy and short-term throttles are not daily allowance', () {
    expect(
      SakeScanException.fromResponse(429, {
        'code': 'analysis_busy',
        'error': '解析中です。',
      }).kind,
      SakeScanErrorKind.analysisBusy,
    );
    expect(
      SakeScanException.fromResponse(429, {'error': '少し待ってください'}).kind,
      SakeScanErrorKind.rateLimited,
    );
    expect(
      SakeScanException.fromResponse(429, '').kind,
      SakeScanErrorKind.rateLimited,
    );
    expect(
      SakeScanException.fromResponse(503, 'unavailable').kind,
      SakeScanErrorKind.server,
    );
  });
}
