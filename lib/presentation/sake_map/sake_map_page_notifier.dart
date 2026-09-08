import 'dart:async';
import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:state_notifier/state_notifier.dart';

import '../../domain/repository/place_map_repository.dart';

class SakeMapState {
  const SakeMapState({
    this.venues = const [],
    this.searchResults = const [],
    this.selectedSake,
    this.isLoading = false,
    this.isSearching = false,
    this.errorMessage,
  });

  final List<MapVenue> venues;
  final List<SakeMapSearchResult> searchResults;
  final SakeMapSearchResult? selectedSake;
  final bool isLoading;
  final bool isSearching;
  final String? errorMessage;

  SakeMapState copyWith({
    List<MapVenue>? venues,
    List<SakeMapSearchResult>? searchResults,
    SakeMapSearchResult? selectedSake,
    bool clearSelectedSake = false,
    bool? isLoading,
    bool? isSearching,
    String? errorMessage,
    bool clearError = false,
  }) => SakeMapState(
    venues: venues ?? this.venues,
    searchResults: searchResults ?? this.searchResults,
    selectedSake: clearSelectedSake ? null : selectedSake ?? this.selectedSake,
    isLoading: isLoading ?? this.isLoading,
    isSearching: isSearching ?? this.isSearching,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}

class SakeMapPageNotifier extends StateNotifier<SakeMapState> {
  SakeMapPageNotifier(this._repository) : super(const SakeMapState());

  final SakeMapDataSource _repository;
  Timer? _searchDebounce;
  LatLngBounds? _lastBounds;
  double _lastZoom = 12;
  int _venueRequestId = 0;
  int _searchRequestId = 0;

  void searchSakes(String query) {
    _searchDebounce?.cancel();
    final normalized = query.trim();
    if (normalized.isEmpty) {
      state = state.copyWith(searchResults: const [], isSearching: false);
      return;
    }
    _searchDebounce = Timer(
      const Duration(milliseconds: 400),
      () => _runSakeSearch(normalized),
    );
  }

  Future<void> _runSakeSearch(String query) async {
    final requestId = ++_searchRequestId;
    state = state.copyWith(isSearching: true, clearError: true);
    try {
      final results = await _repository.searchSakes(query);
      if (requestId != _searchRequestId) return;
      state = state.copyWith(searchResults: results, isSearching: false);
    } catch (_) {
      if (requestId != _searchRequestId) return;
      state = state.copyWith(
        searchResults: const [],
        isSearching: false,
        errorMessage: '日本酒を検索できませんでした。',
      );
    }
  }

  Future<MapVenue?> selectSake(
    SakeMapSearchResult sake, {
    required LatLng origin,
  }) async {
    final requestId = ++_venueRequestId;
    state = state.copyWith(
      selectedSake: sake,
      searchResults: const [],
      venues: const [],
      isLoading: true,
      clearError: true,
    );

    final foundVenues = <String, MapVenue>{};
    try {
      for (final area in _nearestSearchAreas(origin)) {
        final venues = await _repository.fetchVenues(
          swLat: area.bounds.southwest.latitude,
          swLng: area.bounds.southwest.longitude,
          neLat: area.bounds.northeast.latitude,
          neLng: area.bounds.northeast.longitude,
          zoom: area.zoom,
          sakeId: sake.sakeId,
          sakeToken: sake.searchToken,
        );
        if (requestId != _venueRequestId) return null;
        for (final venue in venues) {
          foundVenues[venue.venueId] = venue;
        }
        if (foundVenues.isEmpty) continue;

        final nearest = _nearestVenue(foundVenues.values, origin);
        if (area.acceptNearest ||
            _distanceMeters(origin, nearest) <= area.radiusMeters) {
          state = state.copyWith(
            venues: foundVenues.values.toList(growable: false),
            isLoading: false,
          );
          return nearest;
        }
      }
      if (requestId == _venueRequestId) {
        state = state.copyWith(venues: const [], isLoading: false);
      }
      return null;
    } catch (_) {
      if (requestId != _venueRequestId) return null;
      state = state.copyWith(
        venues: const [],
        isLoading: false,
        errorMessage: '地図の店舗情報を取得できませんでした。',
      );
      return null;
    }
  }

  Future<void> clearSakeFilter() async {
    state = state.copyWith(clearSelectedSake: true, searchResults: const []);
    await refresh();
  }

  Future<void> loadBounds(LatLngBounds bounds, double zoom) async {
    _lastBounds = bounds;
    _lastZoom = zoom;
    await refresh();
  }

  Future<void> refresh() async {
    final bounds = _lastBounds;
    if (bounds == null) return;
    final requestId = ++_venueRequestId;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final venues = await _repository.fetchVenues(
        swLat: bounds.southwest.latitude,
        swLng: bounds.southwest.longitude,
        neLat: bounds.northeast.latitude,
        neLng: bounds.northeast.longitude,
        zoom: _lastZoom,
        sakeId: state.selectedSake?.sakeId,
        sakeToken: state.selectedSake?.searchToken,
      );
      if (requestId != _venueRequestId) return;
      state = state.copyWith(venues: venues, isLoading: false);
    } catch (_) {
      if (requestId != _venueRequestId) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: '地図の店舗情報を取得できませんでした。',
      );
    }
  }

  Future<List<VenueSake>> loadVenueSakes(String venueId) =>
      _repository.fetchVenueSakes(venueId);

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}

Iterable<_NearestSearchArea> _nearestSearchAreas(LatLng origin) sync* {
  for (final radiusMeters in const <double>[
    5000,
    25000,
    100000,
    500000,
    2500000,
  ]) {
    final latitudeDelta = radiusMeters / 111320;
    final longitudeScale = math.cos(origin.latitude * math.pi / 180).abs();
    final longitudeDelta = math.min(
      179.999,
      radiusMeters / (111320 * math.max(longitudeScale, 0.01)),
    );
    yield _NearestSearchArea(
      bounds: LatLngBounds(
        southwest: LatLng(
          math.max(-85, origin.latitude - latitudeDelta),
          math.max(-180, origin.longitude - longitudeDelta),
        ),
        northeast: LatLng(
          math.min(85, origin.latitude + latitudeDelta),
          math.min(180, origin.longitude + longitudeDelta),
        ),
      ),
      radiusMeters: radiusMeters,
      zoom: switch (radiusMeters) {
        <= 5000 => 12,
        <= 25000 => 10,
        <= 100000 => 8,
        <= 500000 => 6,
        _ => 3,
      },
    );
  }
  // 世界全体の境界はAPI側で広すぎる範囲として除外される場合があるため、
  // 国内店舗を確実に拾える日本周辺の範囲を先に検索する。
  yield _NearestSearchArea(
    bounds: LatLngBounds(
      southwest: const LatLng(20, 122),
      northeast: const LatLng(48, 154),
    ),
    radiusMeters: double.infinity,
    zoom: 4,
    acceptNearest: true,
  );
  yield _NearestSearchArea(
    bounds: LatLngBounds(
      southwest: const LatLng(-85, -180),
      northeast: const LatLng(85, 180),
    ),
    radiusMeters: double.infinity,
    zoom: 1,
    acceptNearest: true,
  );
}

MapVenue _nearestVenue(Iterable<MapVenue> venues, LatLng origin) =>
    venues.reduce(
      (nearest, venue) =>
          _distanceMeters(origin, venue) < _distanceMeters(origin, nearest)
          ? venue
          : nearest,
    );

double _distanceMeters(LatLng origin, MapVenue venue) {
  const earthRadiusMeters = 6371000.0;
  final originLatitude = origin.latitude * math.pi / 180;
  final venueLatitude = venue.latitude * math.pi / 180;
  final latitudeDelta = venueLatitude - originLatitude;
  final longitudeDelta = (venue.longitude - origin.longitude) * math.pi / 180;
  final haversine =
      math.pow(math.sin(latitudeDelta / 2), 2) +
      math.cos(originLatitude) *
          math.cos(venueLatitude) *
          math.pow(math.sin(longitudeDelta / 2), 2);
  return 2 * earthRadiusMeters * math.asin(math.sqrt(haversine));
}

class _NearestSearchArea {
  const _NearestSearchArea({
    required this.bounds,
    required this.radiusMeters,
    required this.zoom,
    this.acceptNearest = false,
  });

  final LatLngBounds bounds;
  final double radiusMeters;
  final double zoom;
  final bool acceptNearest;
}
