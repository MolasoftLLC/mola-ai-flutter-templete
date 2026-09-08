import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mola_gemini_flutter_template/domain/repository/place_map_repository.dart';
import 'package:mola_gemini_flutter_template/presentation/sake_map/sake_map_page_notifier.dart';

void main() {
  test('古い地図レスポンスで新しい表示範囲を上書きしない', () async {
    final source = _FakeMapDataSource();
    final notifier = SakeMapPageNotifier(source);
    final firstBounds = LatLngBounds(
      southwest: const LatLng(26, 127),
      northeast: const LatLng(27, 128),
    );
    final secondBounds = LatLngBounds(
      southwest: const LatLng(28, 129),
      northeast: const LatLng(29, 130),
    );

    final first = notifier.loadBounds(firstBounds, 12);
    final second = notifier.loadBounds(secondBounds, 13);
    source.second.complete(const [
      MapVenue(
        venueId: 'venue_2',
        displayName: '新しい範囲',
        latitude: 28.5,
        longitude: 129.5,
        sakeCount: 1,
        recordCount: 1,
      ),
    ]);
    await second;
    source.first.complete(const [
      MapVenue(
        venueId: 'venue_1',
        displayName: '古い範囲',
        latitude: 26.5,
        longitude: 127.5,
        sakeCount: 1,
        recordCount: 1,
      ),
    ]);
    await first;

    expect(notifier.state.venues.single.venueId, 'venue_2');
    notifier.dispose();
  });

  test('日本酒名検索をデバウンスする', () async {
    final source = _FakeMapDataSource();
    final notifier = SakeMapPageNotifier(source);
    notifier.searchSakes('獺');
    notifier.searchSakes('獺祭');
    await Future<void>.delayed(const Duration(milliseconds: 550));

    expect(source.searchQueries, ['獺祭']);
    notifier.dispose();
  });

  test('日本酒を選ぶと検索範囲を広げて最寄り店舗を返す', () async {
    final source = _NearestMapDataSource();
    final notifier = SakeMapPageNotifier(source);
    const sake = SakeMapSearchResult(sakeId: 1, name: '獺祭', isMaster: true);

    final nearest = await notifier.selectSake(
      sake,
      origin: const LatLng(35, 135),
    );

    expect(nearest?.venueId, 'nearer_venue');
    expect(source.venueCalls, 2);
    expect(notifier.state.selectedSake, sake);
    expect(notifier.state.isLoading, isFalse);
    notifier.dispose();
  });

  test('検索元が米国でも日本国内の登録店舗を返す', () async {
    final source = _JapanFallbackMapDataSource();
    final notifier = SakeMapPageNotifier(source);
    const sake = SakeMapSearchResult(sakeId: 1, name: '獺祭', isMaster: true);

    final nearest = await notifier.selectSake(
      sake,
      origin: const LatLng(37.7749, -122.4194),
    );

    expect(nearest?.venueId, 'osaka_venue');
    expect(source.requestedBounds, hasLength(6));
    final japanBounds = source.requestedBounds.last;
    expect(japanBounds.southwest, const LatLng(20, 122));
    expect(japanBounds.northeast, const LatLng(48, 154));
    notifier.dispose();
  });
}

class _FakeMapDataSource implements SakeMapDataSource {
  final first = Completer<List<MapVenue>>();
  final second = Completer<List<MapVenue>>();
  final searchQueries = <String>[];
  var venueCalls = 0;

  @override
  Future<List<MapVenue>> fetchVenues({
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
    required double zoom,
    int? sakeId,
    String? sakeToken,
    int? sinceDays,
  }) {
    venueCalls += 1;
    return venueCalls == 1 ? first.future : second.future;
  }

  @override
  Future<List<VenueSake>> fetchVenueSakes(String venueId) async => const [];

  @override
  Future<List<SakeMapSearchResult>> searchSakes(String query) async {
    searchQueries.add(query);
    return const [];
  }
}

class _NearestMapDataSource implements SakeMapDataSource {
  var venueCalls = 0;

  @override
  Future<List<MapVenue>> fetchVenues({
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
    required double zoom,
    int? sakeId,
    String? sakeToken,
    int? sinceDays,
  }) async {
    venueCalls += 1;
    if (venueCalls == 1) {
      return const [
        MapVenue(
          venueId: 'corner_venue',
          displayName: '最初の範囲の端にある店舗',
          latitude: 35.04,
          longitude: 135.04,
          sakeCount: 1,
          recordCount: 1,
        ),
      ];
    }
    return const [
      MapVenue(
        venueId: 'nearer_venue',
        displayName: 'より近い店舗',
        latitude: 35.05,
        longitude: 135,
        sakeCount: 1,
        recordCount: 1,
      ),
    ];
  }

  @override
  Future<List<VenueSake>> fetchVenueSakes(String venueId) async => const [];

  @override
  Future<List<SakeMapSearchResult>> searchSakes(String query) async => const [];
}

class _JapanFallbackMapDataSource implements SakeMapDataSource {
  final requestedBounds = <LatLngBounds>[];

  @override
  Future<List<MapVenue>> fetchVenues({
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
    required double zoom,
    int? sakeId,
    String? sakeToken,
    int? sinceDays,
  }) async {
    requestedBounds.add(
      LatLngBounds(
        southwest: LatLng(swLat, swLng),
        northeast: LatLng(neLat, neLng),
      ),
    );
    if (swLat == 20 && swLng == 122 && neLat == 48 && neLng == 154) {
      return const [
        MapVenue(
          venueId: 'osaka_venue',
          displayName: '大阪の店舗',
          latitude: 34.6937,
          longitude: 135.5023,
          sakeCount: 1,
          recordCount: 1,
        ),
      ];
    }
    return const [];
  }

  @override
  Future<List<VenueSake>> fetchVenueSakes(String venueId) async => const [];

  @override
  Future<List<SakeMapSearchResult>> searchSakes(String query) async => const [];
}
