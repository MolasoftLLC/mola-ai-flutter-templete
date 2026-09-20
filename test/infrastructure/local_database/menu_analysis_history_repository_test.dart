import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/menu_analysis_history.dart';
import 'package:mola_gemini_flutter_template/infrastructure/local_database/menu_analysis_history_repository.dart';

void main() {
  late Directory tempDirectory;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('menu_history_test_');
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  MenuAnalysisHistoryRepository repository({
    String? legacy,
    void Function()? onLegacyCleared,
    Future<void> Function()? legacyClearer,
    int maxItems = 20,
    MenuHistoryWriter? writer,
  }) => MenuAnalysisHistoryRepository(
    directoryProvider: () async => tempDirectory,
    legacyReader: () async => legacy,
    legacyClearer:
        legacyClearer ??
        () async {
          onLegacyCleared?.call();
        },
    maxItems: maxItems,
    writer: writer,
  );

  MenuAnalysisHistoryItem item(String id, DateTime date, {String? imagePath}) =>
      MenuAnalysisHistoryItem(
        id: id,
        date: date,
        imagePath: imagePath,
        sakes: [SavedSake(name: '天吹 純米大吟醸', extractedName: '天吹')],
      );

  test('マスター未解決でも抽出した全商品を履歴用データへ残す', () {
    final sakes = buildMenuHistorySakes(
      extracted: const [
        (name: '天吹 雄町', type: '純米大吟醸'),
        (name: '鍋島', type: null),
      ],
      resolved: const [],
      nameMapping: const {},
      matchPercents: const {},
    );

    expect(sakes.map((sake) => sake.name), ['天吹 雄町', '鍋島']);
    expect(sakes.every((sake) => sake.sakeId == null), isTrue);
    expect(sakes.map((sake) => sake.extractedName), ['天吹 雄町', '鍋島']);
  });

  test('詳細が一部だけ解決しても未解決の商品名と解決済みIDを同じ履歴へ残す', () {
    final sakes = buildMenuHistorySakes(
      extracted: const [
        (name: '天吹 雄町', type: '純米大吟醸'),
        (name: '鍋島', type: null),
      ],
      resolved: const [(sakeId: 41, name: '天吹 生酛純米大吟醸 雄町', type: '純米大吟醸')],
      nameMapping: const {'天吹 雄町': '天吹 生酛純米大吟醸 雄町'},
      matchPercents: const {'天吹 雄町': 82},
    );

    expect(sakes, hasLength(2));
    expect(sakes.first.sakeId, 41);
    expect(sakes.first.extractedName, '天吹 雄町');
    expect(sakes.last.name, '鍋島');
    expect(sakes.last.sakeId, isNull);
  });

  test('同じ酒名の別解析は別IDで保存し、同じ解析IDの再実行だけ更新する', () async {
    final store = repository();
    final first = item('analysis_1', DateTime.utc(2026, 9, 20, 1));
    final second = item('analysis_2', DateTime.utc(2026, 9, 20, 2));
    await store.upsert(first);
    await store.upsert(second);
    await store.upsert(
      first.copyWith(
        analysisStatus: 'complete',
        sakes: [SavedSake(name: '天吹')],
      ),
    );

    final loaded = await store.load();
    expect(loaded.map((entry) => entry.id), ['analysis_2', 'analysis_1']);
    expect(
      loaded.singleWhere((entry) => entry.id == 'analysis_1').sakes.single.name,
      '天吹',
    );
  });

  test('同じ解析IDのコールバックが重なっても最後の内容を壊さず保存する', () async {
    final store = repository();
    final date = DateTime.utc(2026, 9, 20);
    await Future.wait(
      List.generate(
        10,
        (index) => store.upsert(
          item('analysis_callback', date).copyWith(
            analysisStatus: index == 9 ? 'complete' : 'details_pending',
            sakes: [SavedSake(name: '天吹 $index')],
          ),
        ),
      ),
    );

    final loaded = await store.load();
    expect(loaded, hasLength(1));
    expect(loaded.single.analysisStatus, 'complete');
    expect(loaded.single.sakes.single.name, '天吹 9');
  });

  test('画像ファイル欠損や別レコード破損でも履歴を失わない', () async {
    final store = repository();
    await store.upsert(
      item(
        'missing_image',
        DateTime.utc(2026),
        imagePath: '${tempDirectory.path}/missing.webp',
      ),
    );
    final itemsDirectory = Directory(
      '${tempDirectory.path}/menu_analysis_history_v2/items',
    );
    await File('${itemsDirectory.path}/broken.json').writeAsString('{broken');

    final loaded = await store.load();
    expect(loaded, hasLength(1));
    expect(loaded.single.id, 'missing_image');
    expect(loaded.single.imagePath, isNull);
  });

  test('再起動後も履歴と永続画像の参照を復元する', () async {
    final image = File('${tempDirectory.path}/menu.webp');
    await image.writeAsBytes([1, 2, 3]);
    await repository().upsert(
      item('restart_restore', DateTime.utc(2026, 9, 20), imagePath: image.path),
    );

    final restartedRepository = repository();
    final loaded = await restartedRepository.load();
    expect(loaded, hasLength(1));
    expect(loaded.single.id, 'restart_restore');
    expect(loaded.single.imagePath, image.path);
    expect(await File(loaded.single.imagePath!).readAsBytes(), [1, 2, 3]);
  });

  test('旧SharedPreferences履歴のbase64画像をファイルへ移行する', () async {
    var cleared = false;
    final legacyItem = MenuAnalysisHistoryItem(
      id: 'legacy_1',
      date: DateTime.utc(2026, 9, 1),
      sakes: [SavedSake(name: '鍋島')],
      base64Image: base64Encode([1, 2, 3, 4]),
    );
    final store = repository(
      legacy: jsonEncode([legacyItem.toJson()]),
      onLegacyCleared: () => cleared = true,
    );

    final loaded = await store.load();
    expect(cleared, isTrue);
    expect(loaded, hasLength(1));
    expect(loaded.single.base64Image, isNull);
    expect(loaded.single.imagePath, isNotNull);
    expect(await File(loaded.single.imagePath!).readAsBytes(), [1, 2, 3, 4]);
  });

  test('容量が増えても新しい20件だけを1件単位で保持する', () async {
    final store = repository(maxItems: 20);
    for (var index = 0; index < 25; index++) {
      await store.upsert(
        item('analysis_$index', DateTime.utc(2026, 1, 1, 0, index)),
      );
    }
    final loaded = await store.load();
    expect(loaded, hasLength(20));
    expect(loaded.first.id, 'analysis_24');
    expect(loaded.last.id, 'analysis_5');
  });

  test('書き込み失敗を成功扱いせず呼び出し元へ返す', () async {
    final store = repository(
      writer: (_, __) async => throw const FileSystemException('disk full'),
    );
    await expectLater(
      store.upsert(item('failure', DateTime.utc(2026))),
      throwsA(isA<FileSystemException>()),
    );
  });

  test('旧履歴の移行書き込みに失敗したら移行元を消さない', () async {
    var cleared = false;
    final legacy = jsonEncode([
      item('legacy_failure', DateTime.utc(2026)).toJson(),
    ]);
    final store = repository(
      legacy: legacy,
      onLegacyCleared: () => cleared = true,
      writer: (_, __) async => throw const FileSystemException('disk full'),
    );

    await expectLater(store.load(), throwsA(isA<FileSystemException>()));
    expect(cleared, isFalse);
    expect(
      File(
        '${tempDirectory.path}/menu_analysis_history_v2/.legacy_migrated',
      ).existsSync(),
      isFalse,
    );
  });

  test('旧履歴を消せなければ移行完了扱いにしない', () async {
    final legacy = jsonEncode([
      item('legacy_clear_failure', DateTime.utc(2026)).toJson(),
    ]);
    final store = repository(
      legacy: legacy,
      legacyClearer: () async => throw StateError('clear failed'),
    );

    await expectLater(store.load(), throwsA(isA<StateError>()));
    expect(
      File(
        '${tempDirectory.path}/menu_analysis_history_v2/.legacy_migrated',
      ).existsSync(),
      isFalse,
    );
  });
}
