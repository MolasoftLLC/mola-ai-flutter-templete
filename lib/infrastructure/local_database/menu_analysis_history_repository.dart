import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../domain/eintities/menu_analysis_history.dart';
import '../api_client/api_client.dart';
import '../../common/utils/image_utils.dart';
import '../../common/logger.dart';
import 'shared_key.dart';
import 'shared_preference.dart';

typedef MenuHistoryDirectoryProvider = Future<Directory> Function();
typedef LegacyMenuHistoryReader = Future<String?> Function();
typedef LegacyMenuHistoryClearer = Future<void> Function();
typedef MenuHistoryWriter = Future<void> Function(File target, String value);

class MenuAnalysisHistoryRepository {
  MenuAnalysisHistoryRepository({
    MenuHistoryDirectoryProvider? directoryProvider,
    LegacyMenuHistoryReader? legacyReader,
    LegacyMenuHistoryClearer? legacyClearer,
    MenuHistoryWriter? writer,
    this.maxItems = 20,
    this.ownerId,
  }) : _directoryProvider =
           directoryProvider ?? getApplicationDocumentsDirectory,
       _legacyReader =
           legacyReader ??
           (() => SharedPreference.staticGetString(key: MENU_ANALYSIS_HISTORY)),
       _legacyClearer =
           legacyClearer ??
           (() => SharedPreference.staticSetString(
             key: MENU_ANALYSIS_HISTORY,
             value: '',
           )),
       _writer = writer ?? _writeAtomically;

  final MenuHistoryDirectoryProvider _directoryProvider;
  final LegacyMenuHistoryReader _legacyReader;
  final LegacyMenuHistoryClearer _legacyClearer;
  final MenuHistoryWriter _writer;
  final int maxItems;
  final String? ownerId;
  bool _syncing = false;
  Future<void> _mutationQueue = Future<void>.value();

  Future<void> _serialize(Future<void> Function() action) {
    final completer = Completer<void>();
    _mutationQueue = _mutationQueue.then((_) async {
      try {
        await action();
        completer.complete();
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<Directory> _root() async {
    final documents = await _directoryProvider();
    final base = Directory(
      path.join(documents.path, 'menu_analysis_history_v2'),
    );
    if (!await base.exists()) await base.create(recursive: true);
    final root = ownerId == null
        ? (await File(path.join(base.path, '.account_claim')).exists()
              ? Directory(path.join(base.path, 'accounts', 'guest'))
              : base)
        : Directory(path.join(base.path, 'accounts', _safeId(ownerId!)));
    if (ownerId != null) {
      await root.create(recursive: true);
      final marker = File(path.join(root.path, '.account_migrated'));
      if (!await marker.exists()) {
        final claim = File(path.join(base.path, '.account_claim'));
        if (!await claim.exists() || await claim.readAsString() == ownerId) {
          final oldItems = Directory(path.join(base.path, 'items'));
          if (await oldItems.exists()) {
            final dest = Directory(path.join(root.path, 'items'));
            await dest.create(recursive: true);
            for (final item in await oldItems.list().toList()) {
              if (item is File && item.path.endsWith('.json')) {
                final target = File(
                  path.join(dest.path, path.basename(item.path)),
                );
                if (!await target.exists()) await item.copy(target.path);
              }
            }
          }
          await _writeAtomically(claim, ownerId!);
        }
        await _writeAtomically(marker, 'complete');
      }
    }
    if (!await root.exists()) await root.create(recursive: true);
    return root;
  }

  Future<Directory> _items() async {
    final directory = Directory(path.join((await _root()).path, 'items'));
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  Future<Directory> _images() async {
    final directory = Directory(path.join((await _root()).path, 'images'));
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  String _safeId(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

  Future<File> _itemFile(String id) async =>
      File(path.join((await _items()).path, '${_safeId(id)}.json'));

  static Future<void> _writeAtomically(File target, String value) async {
    final temporary = File('${target.path}.tmp');
    await temporary.writeAsString(value, flush: true);
    try {
      await temporary.rename(target.path);
    } on FileSystemException {
      final backup = File('${target.path}.bak');
      if (await target.exists()) await target.copy(backup.path);
      try {
        if (await target.exists()) await target.delete();
        await temporary.rename(target.path);
        if (await backup.exists()) await backup.delete();
      } catch (_) {
        if (!await target.exists() && await backup.exists()) {
          await backup.rename(target.path);
        }
        rethrow;
      }
    }
  }

  Future<List<MenuAnalysisHistoryItem>> load() async {
    await migrateLegacy();
    final entries = await (await _items())
        .list()
        .where((entry) => entry is File && entry.path.endsWith('.json'))
        .toList();
    final history = <MenuAnalysisHistoryItem>[];
    for (final entry in entries.whereType<File>()) {
      try {
        final decoded = jsonDecode(await entry.readAsString());
        if (decoded is! Map) continue;
        var item = MenuAnalysisHistoryItem.fromJson(
          Map<String, dynamic>.from(decoded),
        );
        if (item.imagePath != null && !await File(item.imagePath!).exists()) {
          item = item.copyWith(clearImagePath: true, clearBase64Image: true);
        }
        history.add(item);
      } catch (_) {
        // One damaged record must not make the remaining history unavailable.
      }
    }
    history.sort((a, b) => b.date.compareTo(a.date));
    return history.take(maxItems).toList(growable: false);
  }

  Future<void> upsert(MenuAnalysisHistoryItem item) =>
      _serialize(() => _upsert(item));

  Future<void> _upsert(MenuAnalysisHistoryItem item) async {
    final stored = item.copyWith(clearBase64Image: true);
    await _writer(await _itemFile(item.id), jsonEncode(stored.toJson()));
    if (ownerId != null) await _queueCloud(item.id, stored.toJson());
    await _prune();
  }

  Future<void> delete(String id) => _serialize(() => _delete(id));

  Future<void> _delete(String id) async {
    final file = await _itemFile(id);
    if (ownerId != null) await _queueCloud(id, null);
    if (await file.exists()) await file.delete();
  }

  Future<void> replaceAll(List<MenuAnalysisHistoryItem> items) =>
      _serialize(() => _replaceAll(items));

  Future<void> _replaceAll(List<MenuAnalysisHistoryItem> items) async {
    for (final item in items.take(maxItems)) {
      await _upsert(item);
    }
    final keep = items.take(maxItems).map((item) => _safeId(item.id)).toSet();
    for (final entity in await (await _items()).list().toList()) {
      if (entity is File && entity.path.endsWith('.json')) {
        final id = path.basenameWithoutExtension(entity.path);
        if (!keep.contains(id)) await entity.delete();
      }
    }
  }

  Future<void> _prune() async {
    final records = <({File file, MenuAnalysisHistoryItem item})>[];
    for (final entity in await (await _items()).list().toList()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      try {
        final decoded = jsonDecode(await entity.readAsString());
        records.add((
          file: entity,
          item: MenuAnalysisHistoryItem.fromJson(
            Map<String, dynamic>.from(decoded as Map),
          ),
        ));
      } catch (_) {}
    }
    records.sort((a, b) => b.item.date.compareTo(a.item.date));
    for (final record in records.skip(maxItems)) {
      await record.file.delete();
    }
  }

  Future<File> _outboxFile() async =>
      File(path.join((await _root()).path, '.cloud_outbox.json'));

  Future<Map<String, dynamic>> _outbox() async {
    final file = await _outboxFile();
    if (!await file.exists()) return {};
    return Map<String, dynamic>.from(
      jsonDecode(await file.readAsString()) as Map,
    );
  }

  Future<void> _queueCloud(String id, Map<String, dynamic>? item) async {
    final pending = await _outbox();
    pending[id] = {
      'ownerUid': ownerId,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'deleted': item == null,
      'item': item,
    };
    await _writer(await _outboxFile(), jsonEncode(pending));
  }

  /// Pending edits and deletions survive offline sessions. Remote updates never
  /// overwrite an edit made locally while a request was in flight.
  Future<void> synchronize(
    ApiClient api,
    bool Function() isCurrentOwner,
  ) async {
    if (ownerId == null || _syncing || !isCurrentOwner()) return;
    _syncing = true;
    try {
      final first = await api.fetchMenuAnalysisHistory(ownerId!);
      if (!first.isSuccessful) {
        throw StateError('Menu history sync: ${first.statusCode}');
      }
      if (!isCurrentOwner()) return;
      final remote = (first.body as Map)['histories'] as List;
      final remoteIds = remote.map((row) => (row as Map)['id']).toSet();
      final local = await load();
      await _serialize(() async {
        final pending = await _outbox();
        for (final item in local) {
          if (!remoteIds.contains(item.id) && !pending.containsKey(item.id)) {
            await _queueCloud(item.id, item.toJson());
          }
        }
      });
      final pending = await _outbox();
      for (final entry in pending.entries) {
        if (!isCurrentOwner()) return;
        final body = Map<String, dynamic>.from(entry.value as Map);
        final item = body['item'];
        if (item is Map) {
          final filePath = item['imagePath'] as String?;
          item['imagePath'] = null;
          if (filePath != null && await File(filePath).exists()) {
            File? compressed;
            try {
              compressed = await ImageUtils.compressForSakeScan(
                File(filePath),
                longEdge: 1200,
                quality: 70,
              );
              final bytes = await compressed.readAsBytes();
              if (bytes.length <= 700000) {
                item['base64Image'] = base64Encode(bytes);
              }
            } catch (error) {
              logger.warning('メニュー履歴の写真を送信できません。解析結果を先に同期します: $error');
            } finally {
              if (compressed != null &&
                  compressed.path != filePath &&
                  await compressed.exists()) {
                await compressed.delete();
              }
            }
          }
        }
        if (!isCurrentOwner()) return;
        final response = await api.saveMenuAnalysisHistoryItem(entry.key, body);
        if (!response.isSuccessful) {
          throw StateError('Menu history sync: ${response.statusCode}');
        }
        await _serialize(() async {
          final latest = await _outbox();
          if ((latest[entry.key] as Map?)?['updatedAt'] ==
              (entry.value as Map)['updatedAt']) {
            latest.remove(entry.key);
            await _writer(await _outboxFile(), jsonEncode(latest));
          }
        });
      }
      if (!isCurrentOwner()) return;
      final response = await api.fetchMenuAnalysisHistory(ownerId!);
      if (!response.isSuccessful) {
        throw StateError('Menu history sync: ${response.statusCode}');
      }
      if (!isCurrentOwner()) return;
      await _serialize(() async {
        final unsent = await _outbox();
        for (final raw in (response.body as Map)['histories'] as List) {
          final row = Map<String, dynamic>.from(raw as Map);
          final id = row['id'] as String;
          if (unsent.containsKey(id)) continue;
          final target = await _itemFile(id);
          if (row['deleted'] == true) {
            if (await target.exists()) await target.delete();
            continue;
          }
          if (row['item'] == null) continue;
          var item = MenuAnalysisHistoryItem.fromJson(
            Map<String, dynamic>.from(row['item'] as Map),
          );
          String? imagePath;
          if (await target.exists()) {
            imagePath =
                (jsonDecode(await target.readAsString()) as Map)['imagePath']
                    as String?;
            if (imagePath != null && !await File(imagePath).exists()) {
              imagePath = null;
            }
          }
          if (imagePath == null && item.base64Image?.isNotEmpty == true) {
            final image = File(
              path.join((await _images()).path, '${_safeId(id)}.jpg'),
            );
            await image.writeAsBytes(
              base64Decode(item.base64Image!),
              flush: true,
            );
            imagePath = image.path;
          }
          item = item.copyWith(imagePath: imagePath, clearBase64Image: true);
          await _writer(target, jsonEncode(item.toJson()));
        }
        await _prune();
      });
    } finally {
      _syncing = false;
    }
  }

  Future<void> migrateLegacy() async {
    final marker = File(path.join((await _root()).path, '.legacy_migrated'));
    if (await marker.exists()) return;
    final base = await _directoryProvider();
    final claim = File(
      path.join(base.path, 'menu_analysis_history_v2', '.account_claim'),
    );
    final mayImportLegacy = ownerId == null
        ? !await claim.exists()
        : !await claim.exists() || await claim.readAsString() == ownerId;
    final legacy = mayImportLegacy ? await _legacyReader() : null;
    if (legacy != null && legacy.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(legacy);
        if (decoded is List) {
          for (final raw in decoded.whereType<Map>()) {
            MenuAnalysisHistoryItem item;
            try {
              item = MenuAnalysisHistoryItem.fromJson(
                Map<String, dynamic>.from(raw),
              );
            } catch (_) {
              continue;
            }
            String? imagePath = item.imagePath;
            if (imagePath != null && !await File(imagePath).exists()) {
              imagePath = null;
            }
            if (imagePath == null && item.base64Image?.isNotEmpty == true) {
              try {
                final image = File(
                  path.join((await _images()).path, '${_safeId(item.id)}.webp'),
                );
                await image.writeAsBytes(
                  base64Decode(item.base64Image!),
                  flush: true,
                );
                imagePath = image.path;
              } catch (_) {
                imagePath = null;
              }
            }
            item = item.copyWith(
              imagePath: imagePath,
              clearImagePath: imagePath == null,
              clearBase64Image: true,
            );
            // Storage failures must abort migration so the legacy source is
            // neither marked nor cleared before all valid rows are durable.
            await upsert(item);
          }
        }
      } on FormatException {
        // A malformed legacy blob must not hide already migrated v2 records.
      }
    }
    if (mayImportLegacy) await _legacyClearer();
    await _writeAtomically(marker, DateTime.now().toIso8601String());
  }
}
