import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'place_map_repository.dart';

abstract interface class VenueFavoritesStore {
  Future<List<MapVenue>> load(String? accountId);
  Future<void> save(String? accountId, List<MapVenue> venues);
}

/// Keeps enough place information to revisit a star outside the visible map.
class VenueFavoritesRepository implements VenueFavoritesStore {
  VenueFavoritesRepository({Future<SharedPreferences> Function()? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _preferences;

  String _key(String? accountId) => accountId == null
      ? 'map.venueFavorites.v1.guest'
      : 'map.venueFavorites.v1.user:${Uri.encodeComponent(accountId)}';

  @override
  Future<List<MapVenue>> load(String? accountId) async {
    final raw = (await _preferences()).getString(_key(accountId));
    if (raw == null) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Invalid venue favorites');
    }
    final venues = <String, MapVenue>{};
    for (final item in decoded) {
      if (item is! Map) continue;
      try {
        final venue = MapVenue.fromJson(Map<String, dynamic>.from(item));
        if (venue.venueId.trim().isEmpty ||
            venue.displayName.trim().isEmpty ||
            !venue.latitude.isFinite ||
            !venue.longitude.isFinite ||
            venue.latitude.abs() > 90 ||
            venue.longitude.abs() > 180) {
          continue;
        }
        venues.putIfAbsent(venue.venueId, () => venue);
      } catch (_) {
        // A malformed entry must not hide the other saved places.
      }
    }
    return venues.values.toList(growable: false);
  }

  @override
  Future<void> save(String? accountId, List<MapVenue> venues) async {
    final saved = await (await _preferences()).setString(
      _key(accountId),
      jsonEncode([
        for (final venue in venues)
          {
            'venueId': venue.venueId,
            'providerPlaceId': venue.providerPlaceId,
            'displayName': venue.displayName,
            'latitude': venue.latitude,
            'longitude': venue.longitude,
            'sakeCount': venue.sakeCount,
            'recordCount': venue.recordCount,
            'ownRecordCount': venue.ownRecordCount,
            'latestImageUrl': venue.latestImageUrl,
          },
      ]),
    );
    if (!saved) throw StateError('Venue favorites were not saved');
  }
}
