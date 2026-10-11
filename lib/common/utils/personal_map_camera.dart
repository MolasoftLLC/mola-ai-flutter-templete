import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../domain/repository/place_map_repository.dart';

Future<void> fitPersonalMapVenues(
  GoogleMapController controller,
  List<MapVenue> venues, {
  double padding = 48,
}) async {
  if (venues.isEmpty) return;
  if (venues.length == 1) {
    await controller.moveCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(venues.first.latitude, venues.first.longitude),
        14,
      ),
    );
    return;
  }
  final latitudes = venues.map((venue) => venue.latitude);
  final longitudes = venues.map((venue) => venue.longitude);
  final south = latitudes.reduce(math.min);
  final north = latitudes.reduce(math.max);
  final west = longitudes.reduce(math.min);
  final east = longitudes.reduce(math.max);
  if (north - south < .0001 && east - west < .0001) {
    await controller.moveCamera(
      CameraUpdate.newLatLngZoom(LatLng(south, west), 14),
    );
    return;
  }
  await controller.moveCamera(
    CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(south - .0001, west - .0001),
        northeast: LatLng(north + .0001, east + .0001),
      ),
      padding,
    ),
  );
}
