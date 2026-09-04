import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('日英の豆知識が同数で英語版に日本語が混在していない', () async {
    final japanese =
        jsonDecode(await File('assets/data/sake_facts.json').readAsString())
            as List<dynamic>;
    final english =
        jsonDecode(await File('assets/data/sake_facts_en.json').readAsString())
            as List<dynamic>;

    expect(japanese, hasLength(110));
    expect(english, hasLength(japanese.length));

    final japaneseCharacters = RegExp(r'[ぁ-んァ-ヶ一-龠々ー]');
    for (final entry in english.cast<Map<String, dynamic>>()) {
      expect(entry['title'], isA<String>());
      expect(entry['body'], isA<String>());
      expect(japaneseCharacters.hasMatch(entry['title'] as String), isFalse);
      expect(japaneseCharacters.hasMatch(entry['body'] as String), isFalse);
    }
  });
}
