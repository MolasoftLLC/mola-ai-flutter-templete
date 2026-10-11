import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../common/analytics/app_analytics.dart';
import '../../../common/utils/personal_map_camera.dart';
import '../../../domain/notifier/saved_sake/saved_sake_notifier.dart';
import '../../../domain/repository/place_map_repository.dart';
import '../../app_page_notifier.dart';

class MyMapPreview extends StatefulWidget {
  const MyMapPreview({super.key, required this.isActive});
  final bool isActive;

  @override
  State<MyMapPreview> createState() => _MyMapPreviewState();
}

class _MyMapPreviewState extends State<MyMapPreview> {
  List<MapVenue> _venues = const [];
  bool _loading = true;
  bool _failed = false;
  String? _recordsSignature;
  int _generation = 0;
  int _mapRevision = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.isActive) _load();
    });
  }

  @override
  void didUpdateWidget(covariant MyMapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) _load();
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final venues = await context.read<PlaceMapRepository>().fetchMyVenues();
      if (!mounted || generation != _generation) return;
      setState(() {
        _venues = venues.take(30).toList(growable: false);
        _loading = false;
        _mapRevision++;
      });
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final signature = context.select(
      (SavedSakeState state) => state.savedSakeList
          .map((sake) => '${sake.savedId}:${sake.drinkingPlace}')
          .join('|'),
    );
    if (_recordsSignature == null) {
      _recordsSignature = signature;
    } else if (_recordsSignature != signature) {
      _recordsSignature = signature;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.isActive) _load();
      });
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.map_outlined, color: Colors.amber),
              SizedBox(width: 10),
              Text(
                'あなたの地図',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '最近登録した30店舗',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: !widget.isActive
                  ? const SizedBox.shrink()
                  : _failed
                  ? Center(
                      child: TextButton(
                        onPressed: _load,
                        child: const Text(
                          '地図を取得できませんでした。再試行',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                  : _loading && _venues.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.amber),
                    )
                  : _venues.isEmpty
                  ? const ColoredBox(
                      color: Color(0xFF143861),
                      child: Center(
                        child: Text(
                          'お酒に場所を登録すると\nここにピンが表示されます。',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    )
                  : GoogleMap(
                      key: ValueKey(_mapRevision),
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          _venues.first.latitude,
                          _venues.first.longitude,
                        ),
                        zoom: 13,
                      ),
                      markers: {
                        for (final venue in _venues)
                          Marker(
                            markerId: MarkerId(venue.venueId),
                            position: LatLng(venue.latitude, venue.longitude),
                            infoWindow: InfoWindow(title: venue.displayName),
                          ),
                      },
                      onMapCreated: (controller) async {
                        if (!mounted) return;
                        await fitPersonalMapVenues(
                          controller,
                          _venues,
                          padding: 32,
                        );
                      },
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                      mapToolbarEnabled: false,
                      scrollGesturesEnabled: false,
                      zoomGesturesEnabled: false,
                      rotateGesturesEnabled: false,
                      tiltGesturesEnabled: false,
                    ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF143861),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                AppAnalytics.instance.event('my_page', 'my_map');
                context.read<AppPageNotifier>().openMyMap();
              },
              icon: const Icon(Icons.open_in_full, size: 17),
              label: const Text(
                '大きいマップで見る',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
