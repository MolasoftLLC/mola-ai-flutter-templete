import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/sake_label_scan.dart';
import 'package:mola_gemini_flutter_template/domain/repository/place_map_repository.dart';
import 'package:mola_gemini_flutter_template/presentation/sake_comparison/live_sake_search.dart';

SakeMapSearchResult sake(int id, String name) =>
    SakeMapSearchResult(sakeId: id, name: name, isMaster: true);
Future<Map<int, SakeTasteProfileDetails>> noProfiles(List<int> _) async => {};
void main() {
  test(
    'OCR queries keep names and classification, remove prices and generic headings',
    () {
      expect(liveSakeQueries('メニュー\n阿櫻\n特純\n￥1,200円'), ['阿櫻 特純', '阿櫻']);
      expect(liveSakeQueries('七賢 純米 180ml 800円'), ['七賢 純米', '七賢']);
      expect(liveSakeQueries('純米\n180ml\n価格'), isEmpty);
      expect(liveSakeQueries('作'), ['作']);
      expect(liveSakeQueries('七賢純米'), ['七賢純米', '七賢']);
      expect(liveSakeQueries('阿櫻特別純米'), ['阿櫻特別純米', '阿櫻']);
      expect(liveSakeQueries('あべ 野田 2024 720ml ￥2,420'), ['あべ 野田 2024', 'あべ']);
    },
  );
  test('two stable readings search; repeated frames reuse results', () async {
    final calls = <String>[];
    final model = LiveSakeSearch(
      search: (q) async {
        calls.add(q);
        return [sake(1, '七賢')];
      },
      loadProfiles: noProfiles,
    );
    addTearDown(model.dispose);
    model.observe('七賢');
    expect(calls, isEmpty);
    model.observe('七賢');
    await Future<void>.delayed(Duration.zero);
    expect(calls, ['七賢']);
    for (var i = 0; i < 10; i++) {
      model.observe('七賢');
    }
    expect(calls, hasLength(1));
    await model.find('七賢');
    expect(calls, hasLength(1));
  });
  test(
    'first response displays without waiting for other query or taste profile',
    () async {
      final precise = Completer<List<SakeMapSearchResult>>();
      final broad = Completer<List<SakeMapSearchResult>>();
      final taste = Completer<Map<int, SakeTasteProfileDetails>>();
      final model = LiveSakeSearch(
        search: (q) => q == '七賢 純米' ? precise.future : broad.future,
        loadProfiles: (_) => taste.future,
      );
      addTearDown(model.dispose);
      final done = model.find('七賢 純米');
      precise.complete([sake(1, '七賢 純米')]);
      await Future<void>.delayed(Duration.zero);
      expect(model.candidates.map((s) => s.sakeId), [1]);
      expect(model.searching, isTrue);
      broad.complete([sake(1, '七賢 純米'), sake(2, '七賢 生')]);
      await done;
      expect(model.candidates.map((s) => s.sakeId), [1, 2]);
      expect(model.searching, isFalse);
      taste.complete({
        1: const SakeTasteProfileDetails(
          fruity: .5,
          sweetness: .5,
          acidity: .5,
          umami: .5,
          kire: .5,
          dryness: .5,
        ),
      });
      await Future<void>.delayed(Duration.zero);
      expect(model.profiles[1]?.sweetness, .5);
    },
  );
  test(
    'slow previous reading never replaces next product candidates',
    () async {
      final old = Completer<List<SakeMapSearchResult>>();
      final model = LiveSakeSearch(
        search: (q) => q == '阿櫻' ? old.future : Future.value([sake(2, '七賢')]),
        loadProfiles: noProfiles,
      );
      addTearDown(model.dispose);
      final previous = model.find('阿櫻');
      await model.find('七賢');
      old.complete([sake(1, '阿櫻')]);
      await previous;
      expect(model.candidates.single.sakeId, 2);
    },
  );
  test('network failure is distinguished from no matching master', () async {
    final model = LiveSakeSearch(
      search: (_) async => throw StateError('offline'),
      loadProfiles: noProfiles,
    );
    addTearDown(model.dispose);
    await model.find('七賢');
    expect(model.candidates, isEmpty);
    expect(model.error, isNotNull);
    expect(model.searching, isFalse);
  });
  test(
    'closing the scanner during a request does not notify disposed state',
    () async {
      final response = Completer<List<SakeMapSearchResult>>();
      final model = LiveSakeSearch(
        search: (_) => response.future,
        loadProfiles: noProfiles,
      );
      final pending = model.find('阿櫻');
      model.dispose();
      response.complete([sake(1, '阿櫻')]);
      await pending;
    },
  );
  test(
    'specific matches move ahead of a broad brand response that arrived first',
    () async {
      final specific = Completer<List<SakeMapSearchResult>>();
      final broad = Completer<List<SakeMapSearchResult>>();
      final model = LiveSakeSearch(
        search: (q) => q == '七賢純米' ? specific.future : broad.future,
        loadProfiles: noProfiles,
      );
      addTearDown(model.dispose);
      final done = model.find('七賢純米');
      broad.complete([sake(2, '七賢 生')]);
      await Future<void>.delayed(Duration.zero);
      expect(model.candidates.single.sakeId, 2);
      specific.complete([sake(1, '七賢 純米')]);
      await done;
      expect(model.candidates.map((s) => s.sakeId), [1, 2]);
    },
  );
  test('only existing master IDs can become selectable candidates', () async {
    final model = LiveSakeSearch(
      search: (_) async => [
        const SakeMapSearchResult(name: '未登録', isMaster: false),
        const SakeMapSearchResult(sakeId: 99, name: '外部候補', isMaster: false),
        sake(1, '七賢'),
      ],
      loadProfiles: noProfiles,
    );
    addTearDown(model.dispose);
    await model.find('七賢');
    expect(model.candidates.map((s) => s.sakeId), [1]);
  });
  test(
    'standalone classification including 酒 is joined to the brand and displayed',
    () async {
      final model = LiveSakeSearch(
        search: (_) async => [],
        loadProfiles: noProfiles,
      );
      addTearDown(model.dispose);
      expect(liveSakeQueries('酔鯨\n特別純米酒\n720ml\n1,353円'), ['酔鯨 特別純米酒', '酔鯨']);
      await model.find('酔鯨\n特別純米酒\n720ml\n1,353円');
      expect(model.displayText, '酔鯨 特別純米酒');
    },
  );
  test(
    'classification changes only order; more than 20 brand candidates survive',
    () async {
      final products = [
        sake(1, '酔鯨 純米大吟醸'),
        sake(2, '酔鯨 特別純米酒'),
        sake(3, '酔鯨 特別純米酒 しぼりたて 生酒'),
        ...List.generate(25, (i) => sake(i + 4, '酔鯨 純米吟醸 シリーズ$i')),
      ];
      final model = LiveSakeSearch(
        search: (q) async => q == '酔鯨' ? products : [],
        loadProfiles: noProfiles,
      );
      addTearDown(model.dispose);
      await model.find('酔鯨\n特別純米酒');
      expect(model.candidates.map((s) => s.sakeId).take(2), [2, 3]);
      expect(model.candidates, hasLength(products.length));
      expect(
        model.candidates.map((s) => s.sakeId).toSet(),
        products.map((s) => s.sakeId).toSet(),
      );
    },
  );
  test(
    'resume ignores the closed label but recognizes another reading',
    () async {
      final model = LiveSakeSearch(
        search: (_) async => [sake(1, '酔鯨')],
        loadProfiles: noProfiles,
      );
      addTearDown(model.dispose);
      await model.find('酔鯨 特別純米酒');
      model.resumeScanning();
      model.observe('酔鯨 特別純米酒');
      model.observe('酔鯨 特別純米酒');
      await Future<void>.delayed(Duration.zero);
      expect(model.candidates, isEmpty);
      model.observe('七賢');
      model.observe('七賢');
      await Future<void>.delayed(Duration.zero);
      expect(model.candidates, isNotEmpty);
      expect(model.displayText, '七賢');
    },
  );
  test('closing a sheet invalidates its pending search response', () async {
    final pending = Completer<List<SakeMapSearchResult>>();
    final model = LiveSakeSearch(
      search: (q) =>
          q == '酔鯨' ? pending.future : Future.value([sake(1, '酔鯨 特別純米酒')]),
      loadProfiles: noProfiles,
    );
    addTearDown(model.dispose);
    final done = model.find('酔鯨 特別純米酒');
    await Future<void>.delayed(Duration.zero);
    expect(model.candidates, isNotEmpty);
    model.resumeScanning();
    pending.complete([sake(2, '酔鯨 吟醸')]);
    await done;
    expect(model.candidates, isEmpty);
  });
  test(
    'shelf metadata and classification-first labels retain the complete name',
    () {
      expect(liveSakeQueries('高知県\n酔鯨酒造\n酔鯨\n特別純米酒').first, '酔鯨 特別純米酒');
      expect(liveSakeQueries('特別純米酒 酔鯨'), ['特別純米酒 酔鯨', '酔鯨']);
      expect(liveSakeQueries('七賢\n純米 風凛美山').first, '七賢 純米 風凛美山');
    },
  );
}
