import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mola_gemini_flutter_template/domain/repository/menu_extraction_stream.dart';

void main() {
  test(
    'shows complete entries before final result, including split UTF8',
    () async {
      final chunks = StreamController<List<int>>();
      final seen = <MenuReadingProgress>[];
      final future = readMenuExtractionStream(
        http.StreamedResponse(chunks.stream, 200),
        seen.add,
      );
      final text =
          '${jsonEncode({'event': 'started'})}\n${jsonEncode({
            'event': 'entry',
            'index': 0,
            'sake': {'name': '仙禽'},
          })}\n';
      for (final byte in utf8.encode(text)) {
        chunks.add([byte]);
      }
      await Future<void>.delayed(Duration.zero);
      expect(seen.last.names, ['仙禽']);
      chunks.add(
        utf8.encode(
          '${jsonEncode({
            'event': 'complete',
            'result': {
              'sakes': [
                {'name': '仙禽'},
              ],
              'analysisId': 'ticket',
            },
          })}\n',
        ),
      );
      await chunks.close();
      expect((await future)['analysisId'], 'ticket');
    },
  );
  test('cached complete works without intermediate events', () async {
    final data = jsonEncode({
      'event': 'complete',
      'result': {
        'sakes': [
          {'name': '仙禽'},
        ],
        'analysisId': 'cached',
      },
    });
    final result = await readMenuExtractionStream(
      http.StreamedResponse(Stream.value(utf8.encode('$data\n')), 200),
      (_) {},
    );
    expect(result['analysisId'], 'cached');
  });
  test(
    'disconnect does not turn partial entries into a successful result',
    () async {
      final data = jsonEncode({
        'event': 'entry',
        'index': 0,
        'sake': {'name': '仙禽'},
      });
      await expectLater(
        readMenuExtractionStream(
          http.StreamedResponse(Stream.value(utf8.encode('$data\n')), 200),
          (_) {},
        ),
        throwsA(isA<MenuExtractionException>()),
      );
    },
  );
  test('daily limit keeps the server message and status', () async {
    await expectLater(
      readMenuExtractionStream(
        http.StreamedResponse(
          Stream.value(utf8.encode('{"error":"本日のメニュー解析は5回までです。"}')),
          429,
        ),
        (_) {},
      ),
      throwsA(
        isA<MenuExtractionException>()
            .having((e) => e.statusCode, 'status', 429)
            .having((e) => e.message, 'message', contains('5回')),
      ),
    );
  });
  test('stream error and duplicate index are rejected', () async {
    for (final event in [
      {'event': 'error', 'error': '失敗'},
      {
        'event': 'entry',
        'index': 1,
        'sake': {'name': '仙禽'},
      },
    ]) {
      await expectLater(
        readMenuExtractionStream(
          http.StreamedResponse(
            Stream.value(utf8.encode('${jsonEncode(event)}\n')),
            200,
          ),
          (_) {},
        ),
        throwsA(isA<MenuExtractionException>()),
      );
    }
  });
}
