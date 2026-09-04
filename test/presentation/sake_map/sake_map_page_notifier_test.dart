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
    await Future<void>.delayed(const Duration(milliseconds: 450));

    expect(source.searchQueries, ['獺祭']);
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
