import 'dart:async';

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

  Future<void> selectSake(SakeMapSearchResult sake) async {
    state = state.copyWith(selectedSake: sake, searchResults: const []);
    await refresh();
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
        sinceDays: 90,
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
