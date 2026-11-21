import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/eintities/menu_analysis_history.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';

bool hasMapPlace(DrinkingPlace? place) =>
    place != null &&
    place.latitude != null &&
    place.longitude != null &&
    place.latitude!.isFinite &&
    place.longitude!.isFinite &&
    place.latitude!.abs() <= 90 &&
    place.longitude!.abs() <= 180;

class PlaceRegistrationItem {
  const PlaceRegistrationItem({
    required this.key,
    required this.title,
    this.sake,
    this.menu,
  });
  final String key, title;
  final Sake? sake;
  final MenuAnalysisHistoryItem? menu;
  bool get isMenu => menu != null;
  DateTime? get recordedAt {
    if (menu != null) return menu!.date.toLocal();
    final match = RegExp(
      r'^saved_([0-9]{13})_',
    ).firstMatch(sake?.savedId ?? '');
    final millis = match == null ? null : int.tryParse(match.group(1)!);
    return millis == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal();
  }

  bool get hasPhoto =>
      imagePath?.trim().isNotEmpty == true ||
      menu?.base64Image?.isNotEmpty == true;
  String? get imagePath => menu?.imagePath ?? sake?.imagePaths?.firstOrNull;
  String? get initialPlace =>
      menu?.drinkingPlace?.displayName ??
      menu?.storeName ??
      sake?.drinkingPlace?.displayName ??
      sake?.place;
}

List<PlaceRegistrationItem> pendingPlaceRegistrations({
  required List<Sake> bottles,
  required List<MenuAnalysisHistoryItem> menus,
  Set<String> dismissed = const {},
}) {
  final rows = <String, PlaceRegistrationItem>{};
  for (final sake in bottles) {
    final id = sake.savedId;
    if (id == null || id.isEmpty || hasMapPlace(sake.drinkingPlace)) continue;
    // Bookmarks without a bottle photo are not drinking-location reminders.
    if (sake.imagePaths?.isNotEmpty != true) continue;
    final key = 'bottle:$id';
    if (!dismissed.contains(key))
      rows[key] = PlaceRegistrationItem(
        key: key,
        title: sake.name?.trim().isNotEmpty == true ? sake.name! : '撮影したお酒',
        sake: sake,
      );
  }
  for (final menu in menus) {
    if (hasMapPlace(menu.drinkingPlace) ||
        (menu.imagePath?.isNotEmpty != true && menu.sakes.isEmpty))
      continue;
    final key = 'menu:${menu.id}';
    if (!dismissed.contains(key))
      rows[key] = PlaceRegistrationItem(
        key: key,
        title: menu.storeName?.trim().isNotEmpty == true
            ? menu.storeName!
            : '撮影したメニュー',
        menu: menu,
      );
  }
  return rows.values.toList(growable: false);
}

/// Only reminder dismissals; never deletes photos, bottles or menu history.
/// These settings are device-local and isolated by account (including guests).
class PlaceRegistrationDismissals extends ChangeNotifier {
  PlaceRegistrationDismissals(
    this.owner, {
    Future<SharedPreferences> Function()? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance;
  static final revision = ValueNotifier<int>(0);
  final String owner;
  final Future<SharedPreferences> Function() _preferences;
  Set<String> _ids = {};
  Set<String> get ids => Set.unmodifiable(_ids);
  bool ready = false;
  Future<void> _queue = Future.value();
  String get _key => 'map-place-inbox-v1-${sha256.convert(utf8.encode(owner))}';
  bool _disposed = false;
  Future<void> load() async {
    final ids = (await _preferences()).getStringList(_key) ?? [];
    if (_disposed) return;
    _ids = ids.toSet();
    ready = true;
    notifyListeners();
  }

  Future<void> setDismissed(String id, bool dismissed) {
    final result = _queue.then((_) async {
      final next = {..._ids};
      if (dismissed) {
        next.add(id);
      } else {
        next.remove(id);
      }
      if (!await (await _preferences()).setStringList(_key, next.toList()))
        throw StateError('Could not save reminder setting');
      if (_disposed) return;
      _ids = next;
      notifyListeners();
      revision.value++;
    });
    _queue = result.catchError((Object _) {});
    return result;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
