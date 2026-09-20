import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../domain/eintities/menu_analysis_history.dart';
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
    final root = Directory(
      path.join(documents.path, 'menu_analysis_history_v2'),
    );
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
    await _prune();
  }

  Future<void> delete(String id) => _serialize(() => _delete(id));

  Future<void> _delete(String id) async {
    final file = await _itemFile(id);
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

  Future<void> migrateLegacy() async {
    final marker = File(path.join((await _root()).path, '.legacy_migrated'));
    if (await marker.exists()) return;
    final legacy = await _legacyReader();
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
    await _legacyClearer();
    await _writeAtomically(marker, DateTime.now().toIso8601String());
  }
}
