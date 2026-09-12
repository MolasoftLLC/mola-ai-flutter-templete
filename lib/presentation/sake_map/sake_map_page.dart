import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../common/logger.dart';
import '../../common/localization/localization_extensions.dart';
import '../../common/utils/snack_bar_utils.dart';
import '../../domain/repository/place_map_repository.dart';
import '../common/widgets/primary_app_bar.dart';
import 'sake_map_marker_icon.dart';
import 'sake_map_page_notifier.dart';
import 'sake_master_detail_page.dart';

class SakeMapPage extends StatefulWidget {
  const SakeMapPage._();

  static Widget wrapped() =>
      StateNotifierProvider<SakeMapPageNotifier, SakeMapState>(
        create: (context) =>
            SakeMapPageNotifier(context.read<PlaceMapRepository>()),
        child: const SakeMapPage._(),
      );

  @override
  State<SakeMapPage> createState() => _SakeMapPageState();
}

class _SakeMapPageState extends State<SakeMapPage> {
  static const _initialCamera = CameraPosition(
    target: LatLng(34.6811499, 135.5097380),
    zoom: 15,
  );

  final _searchController = TextEditingController();
  final _markerIcons = <String, BitmapDescriptor>{};
  final _fallbackMarkerIcons = <int, Future<BitmapDescriptor>>{};
  final _requestedMarkerKeys = <String>{};
  final _pendingMarkerRequests = Queue<_MarkerIconRequest>();
  int _activeMarkerLoads = 0;
  bool _isLocating = false;
  bool _showMyLocation = false;
  GoogleMapController? _mapController;
  LatLng? _lastKnownLocation;
  double _zoom = _initialCamera.zoom;

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SakeMapState>();
    final notifier = context.read<SakeMapPageNotifier>();
    _requestMarkerIcons(state.venues);
    final markers = state.venues
        .map(
          (venue) => Marker(
            markerId: MarkerId(venue.venueId),
            position: LatLng(venue.latitude, venue.longitude),
            icon:
                _markerIcons[_markerKey(venue)] ??
                BitmapDescriptor.defaultMarker,
            anchor: _markerIcons.containsKey(_markerKey(venue))
                ? const Offset(0.5, 0.96)
                : const Offset(0.5, 1),
            infoWindow: InfoWindow(
              title: venue.displayName,
              snippet: '${venue.sakeCount}種類・${venue.recordCount}件の登録',
            ),
            onTap: () => _showVenueSakes(context, notifier, venue),
          ),
        )
        .toSet();

    return Scaffold(
      appBar: const PrimaryAppBar(title: '日本酒マップ', titleFontSize: 21),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCamera,
            markers: markers,
            myLocationEnabled: _showMyLocation,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) async {
              _mapController = controller;
              unawaited(_moveToCurrentLocationIfAvailable());
              await _loadVisibleBounds(notifier);
            },
            onCameraMove: (position) => _zoom = position.zoom,
            onCameraIdle: () => _loadVisibleBounds(notifier),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    elevation: 5,
                    borderRadius: BorderRadius.circular(14),
                    child: TextField(
                      controller: _searchController,
                      onChanged: notifier.searchSakes,
                      decoration: InputDecoration(
                        hintText: '日本酒名で店舗を絞り込む',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: state.isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : state.selectedSake == null
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  notifier.clearSakeFilter();
                                },
                                icon: const Icon(Icons.clear),
                              ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  if (state.searchResults.isNotEmpty)
                    Material(
                      elevation: 5,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(14),
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 240),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: state.searchResults.length,
                          itemBuilder: (context, index) {
                            final result = state.searchResults[index];
                            return ListTile(
                              leading: Icon(
                                result.isMaster
                                    ? Icons.verified_outlined
                                    : Icons.history,
                              ),
                              title: Text(result.name),
                              subtitle: Text(
                                [
                                  if (result.brewery != null) result.brewery!,
                                  context.l10n.registeredVenueCount(
                                    result.venueCount,
                                  ),
                                ].join('・'),
                              ),
                              onTap: () {
                                _selectSakeAndMoveToNearest(notifier, result);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  if (state.selectedSake != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Chip(
                          label: Text('${state.selectedSake!.name}が登録されている店舗'),
                          onDeleted: () {
                            _searchController.clear();
                            notifier.clearSakeFilter();
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (state.isLoading)
            const Positioned(
              top: 12,
              right: 12,
              child: SafeArea(child: CircularProgressIndicator()),
            ),
          if (!state.isLoading && state.venues.isEmpty)
            Positioned(
              left: 24,
              right: 24,
              bottom: 92,
              child: _MapMessage(
                message:
                    state.errorMessage ??
                    (state.selectedSake == null
                        ? 'この範囲には店舗と日本酒の登録がありません。'
                        : '「${state.selectedSake!.name}」が登録されている店舗はありません。'),
                onRetry: state.errorMessage == null ? null : notifier.refresh,
              ),
            ),
          Positioned(
            right: 16,
            bottom: 16,
            child: SafeArea(
              top: false,
              left: false,
              child: Material(
                color: Colors.white,
                elevation: 5,
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: '現在地へ移動',
                  onPressed: _isLocating ? null : _moveToCurrentLocation,
                  icon: _isLocating
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF143861),
                          ),
                        )
                      : const Icon(Icons.my_location, color: Color(0xFF143861)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadVisibleBounds(SakeMapPageNotifier notifier) async {
    final controller = _mapController;
    if (controller == null) return;
    final bounds = await controller.getVisibleRegion();
    await notifier.loadBounds(bounds, _zoom);
  }

  Future<void> _selectSakeAndMoveToNearest(
    SakeMapPageNotifier notifier,
    SakeMapSearchResult sake,
  ) async {
    _searchController.text = sake.name;
    FocusScope.of(context).unfocus();
    final origin = await _resolveNearestSearchOrigin();
    if (!mounted) return;
    final nearest = await notifier.selectSake(sake, origin: origin);
    if (!mounted || nearest == null) return;
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(nearest.latitude, nearest.longitude),
          zoom: 15.5,
        ),
      ),
    );
  }

  Future<LatLng> _resolveNearestSearchOrigin() async {
    final lastKnownLocation = _lastKnownLocation;
    if (lastKnownLocation != null) return lastKnownLocation;
    try {
      if (await Geolocator.isLocationServiceEnabled()) {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          final position = await Geolocator.getLastKnownPosition();
          if (position != null) {
            return _lastKnownLocation = LatLng(
              position.latitude,
              position.longitude,
            );
          }
        }
      }
    } catch (error) {
      logger.info('最寄り店舗検索用の現在地を取得できませんでした: $error');
    }

    final controller = _mapController;
    if (controller == null) return _initialCamera.target;
    final bounds = await controller.getVisibleRegion();
    return LatLng(
      (bounds.southwest.latitude + bounds.northeast.latitude) / 2,
      (bounds.southwest.longitude + bounds.northeast.longitude) / 2,
    );
  }

  Future<void> _moveToCurrentLocationIfAvailable() async {
    final controller = _mapController;
    if (controller == null || _isLocating) return;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return;
      }
      if (!mounted) return;
      setState(() => _isLocating = true);
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      );
      if (!mounted) return;
      _lastKnownLocation = LatLng(position.latitude, position.longitude);
      await _moveCameraToPosition(controller, position);
    } catch (error) {
      logger.info('初期表示用の現在地を取得できませんでした: $error');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _moveToCurrentLocation() async {
    final controller = _mapController;
    if (controller == null || _isLocating) return;
    setState(() => _isLocating = true);

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (!mounted) return;
        _showLocationWarning(
          '端末の位置情報サービスがオフになっています。',
          action: const SnackBarAction(
            label: '設定',
            onPressed: Geolocator.openLocationSettings,
          ),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (!mounted) return;
      if (permission == LocationPermission.deniedForever) {
        _showLocationWarning(
          '位置情報の利用が許可されていません。設定から許可してください。',
          action: const SnackBarAction(
            label: '設定',
            onPressed: Geolocator.openAppSettings,
          ),
        );
        return;
      }
      if (permission == LocationPermission.denied) {
        _showLocationWarning('現在地へ移動するには位置情報の許可が必要です。');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      );
      if (!mounted) return;
      _lastKnownLocation = LatLng(position.latitude, position.longitude);
      await _moveCameraToPosition(controller, position);
    } on TimeoutException {
      if (mounted) _showLocationWarning('現在地を取得できませんでした。もう一度お試しください。');
    } catch (error) {
      logger.warning('マップで現在地を取得できませんでした: $error');
      if (mounted) _showLocationWarning('現在地を取得できませんでした。');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _moveCameraToPosition(
    GoogleMapController controller,
    Position position,
  ) async {
    if (!_showMyLocation) setState(() => _showMyLocation = true);
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 15.5,
        ),
      ),
    );
  }

  void _showLocationWarning(String message, {SnackBarAction? action}) {
    SnackBarUtils.showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.orange.shade800,
      action: action,
      leadingIcon: Icons.location_off_outlined,
    );
  }

  void _requestMarkerIcons(List<MapVenue> venues) {
    for (final venue in venues) {
      final key = _markerKey(venue);
      if (_markerIcons.containsKey(key) || !_requestedMarkerKeys.add(key)) {
        continue;
      }
      final request = _MarkerIconRequest(
        key: key,
        imageUrl: venue.latestImageUrl,
        recordCount: venue.recordCount,
      );
      unawaited(_loadFallbackMarker(request));
      if (request.imageUrl != null) _pendingMarkerRequests.add(request);
    }
    _drainMarkerQueue();
  }

  void _drainMarkerQueue() {
    if (!mounted) {
      _pendingMarkerRequests.clear();
      return;
    }
    while (_activeMarkerLoads < 4 && _pendingMarkerRequests.isNotEmpty) {
      final request = _pendingMarkerRequests.removeFirst();
      _activeMarkerLoads += 1;
      unawaited(
        _loadMarkerIcon(request).whenComplete(() {
          _activeMarkerLoads -= 1;
          _drainMarkerQueue();
        }),
      );
    }
  }

  Future<void> _loadMarkerIcon(_MarkerIconRequest request) async {
    try {
      final imageUrl = request.imageUrl;
      if (imageUrl == null) return;
      final uri = Uri.tryParse(imageUrl);
      if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
        return;
      }
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode < 200 || response.statusCode >= 300) return;
      final icon = await createCircularSakeMarker(
        response.bodyBytes,
        recordCount: request.recordCount,
      );
      if (!mounted) return;
      setState(() => _markerIcons[request.key] = icon);
    } catch (error) {
      logger.info('地図ピン画像を読み込めませんでした: $error');
    }
  }

  Future<void> _loadFallbackMarker(_MarkerIconRequest request) async {
    try {
      final icon = await (_fallbackMarkerIcons[request.recordCount] ??=
          createCircularSakeMarker(null, recordCount: request.recordCount));
      if (!mounted || _markerIcons.containsKey(request.key)) return;
      setState(() => _markerIcons[request.key] = icon);
    } catch (error) {
      logger.info('地図の代替ピンを生成できませんでした: $error');
    }
  }

  String _markerKey(MapVenue venue) =>
      '${venue.latestImageUrl ?? 'fallback'}#${venue.recordCount}';

  Future<void> _showVenueSakes(
    BuildContext context,
    SakeMapPageNotifier notifier,
    MapVenue venue,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => FutureBuilder<List<VenueSake>>(
        future: notifier.loadVenueSakes(venue.venueId),
        builder: (sheetContentContext, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 260,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final sakes = snapshot.data ?? const <VenueSake>[];
          return SafeArea(
            child: SizedBox(
              height: 420,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          venue.displayName,
                          style: Theme.of(
                            sheetContentContext,
                          ).textTheme.titleLarge,
                        ),
                        const Text('この店舗に登録されている日本酒'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: sakes.isEmpty
                        ? const Center(child: Text('公開された日本酒記録はありません。'))
                        : ListView.separated(
                            itemCount: sakes.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (itemContext, index) {
                              final sake = sakes[index];
                              return ListTile(
                                leading: _SakeThumbnail(
                                  imageUrl:
                                      sake.thumbnailImageUrl ??
                                      sake.primaryImageUrl,
                                ),
                                title: Text(sake.name),
                                subtitle: Text(
                                  [
                                    if (sake.brewery != null) sake.brewery!,
                                    if (sake.type != null) sake.type!,
                                  ].join('・'),
                                ),
                                trailing: Text('${sake.recordCount}件'),
                                onTap: () {
                                  Navigator.of(sheetContext).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          SakeMasterDetailPage(venueSake: sake),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MarkerIconRequest {
  const _MarkerIconRequest({
    required this.key,
    required this.imageUrl,
    required this.recordCount,
  });

  final String key;
  final String? imageUrl;
  final int recordCount;
}

class _SakeThumbnail extends StatelessWidget {
  const _SakeThumbnail({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final fallback = Image.asset(
      'assets/images/sake_placeholder.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(Icons.wine_bar_outlined),
    );
    return CircleAvatar(
      backgroundColor: const Color(0xFFF2F2F2),
      child: ClipOval(
        child: SizedBox.expand(
          child: imageUrl == null
              ? fallback
              : Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => fallback,
                ),
        ),
      ),
    );
  }
}

class _MapMessage extends StatelessWidget {
  const _MapMessage({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Material(
    elevation: 4,
    borderRadius: BorderRadius.circular(14),
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(child: Text(message)),
          if (onRetry != null)
            IconButton(onPressed: onRetry, icon: const Icon(Icons.refresh)),
        ],
      ),
    ),
  );
}
