import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/repository/place_map_repository.dart';
import '../../domain/repository/venue_favorites_repository.dart';

class VenueFavoritesController extends ChangeNotifier {
  VenueFavoritesController({
    required VenueFavoritesStore store,
    String? accountId,
    Stream<String?>? accountChanges,
  }) : _store = store,
       _accountId = accountId {
    _accountSubscription = accountChanges?.listen((id) {
      if (id == _accountId) return;
      _accountId = id;
      _venues = const [];
      unawaited(reload());
    });
    unawaited(reload());
  }

  final VenueFavoritesStore _store;
  StreamSubscription<String?>? _accountSubscription;
  String? _accountId;
  List<MapVenue> _venues = const [];
  int _generation = 0;
  bool _disposed = false;
  Future<void> _saveSettled = Future.value();
  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;

  List<MapVenue> get venues => List.unmodifiable(_venues);
  bool isFavorite(String id) => _venues.any((venue) => venue.venueId == id);

  Future<void> reload() async {
    if (_disposed) return;
    final generation = ++_generation;
    final account = _accountId;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _saveSettled;
      if (_disposed || generation != _generation) return;
      final venues = await _store.load(account);
      if (_disposed || generation != _generation) return;
      _venues = venues;
    } catch (_) {
      if (_disposed || generation != _generation) return;
      errorMessage = 'お気に入りを読み込めませんでした。もう一度お試しください。';
    }
    if (_disposed || generation != _generation) return;
    isLoading = false;
    notifyListeners();
  }

  Future<bool> toggle(MapVenue venue) async {
    if (_disposed || isLoading || isSaving || errorMessage != null) {
      return false;
    }
    final generation = _generation;
    final account = _accountId;
    final next = isFavorite(venue.venueId)
        ? _venues.where((item) => item.venueId != venue.venueId).toList()
        : [venue, ..._venues];
    isSaving = true;
    final settled = Completer<void>();
    _saveSettled = settled.future;
    notifyListeners();
    var saved = false;
    try {
      await _store.save(account, next);
      if (!_disposed && generation == _generation) {
        _venues = next;
        saved = true;
      }
    } catch (_) {
      // Keep the last persisted stars. A failed save must not look successful.
    } finally {
      settled.complete();
      isSaving = false;
      if (!_disposed) notifyListeners();
    }
    return saved;
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    unawaited(_accountSubscription?.cancel());
    super.dispose();
  }
}
