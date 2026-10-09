import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../common/logger.dart';
import '../../common/localization/localization_extensions.dart';
import '../../common/utils/snack_bar_utils.dart';
import '../../common/utils/sake_image_utils.dart';
import '../../domain/repository/place_map_repository.dart';
import '../common/widgets/primary_app_bar.dart';
import 'sake_map_marker_icon.dart';
import 'sake_map_page_notifier.dart';
import 'sake_master_detail_page.dart';

class SakeMapPage extends StatefulWidget {
  const SakeMapPage._({this.initialSake});

  final SakeMapSearchResult? initialSake;

  static Widget wrapped({SakeMapSearchResult? initialSake}) =>
      StateNotifierProvider<SakeMapPageNotifier, SakeMapState>(
        create: (context) =>
            SakeMapPageNotifier(context.read<PlaceMapRepository>()),
        child: SakeMapPage._(initialSake: initialSake),
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
  bool _didApplyInitialSake = false;

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
    final markerLayout = _layoutNearbyMarkers(state.venues, _zoom);
    final markers = state.venues
        .map(
          (venue) => Marker(
            markerId: MarkerId(venue.venueId),
            position:
                markerLayout.positions[venue.venueId] ??
                LatLng(venue.latitude, venue.longitude),
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
            polylines: markerLayout.connectorLines,
            myLocationEnabled: _showMyLocation,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) async {
              _mapController = controller;
              await _moveToCurrentLocationIfAvailable();
              final initialSake = widget.initialSake;
              if (initialSake != null && !_didApplyInitialSake) {
                _didApplyInitialSake = true;
                await _selectSakeAndMoveToNearest(notifier, initialSake);
              } else {
                await _loadVisibleBounds(notifier);
              }
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

  Future<void> _openVenueInMaps(MapVenue venue) async {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '${venue.latitude},${venue.longitude}',
    });
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (error) {
      logger.warning('店舗の地図を開けませんでした: $error');
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('地図を開けませんでした。もう一度お試しください。')));
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
    // Keep one request while the sheet is resized or rebuilt.
    final sakesFuture = notifier.loadVenueSakes(venue.venueId);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF5F7FA),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .58,
        minChildSize: .35,
        maxChildSize: .9,
        builder: (_, scrollController) => SafeArea(
          top: false,
          child: FutureBuilder<List<VenueSake>>(
            future: sakesFuture,
            builder: (sheetContentContext, snapshot) {
              final sakes = snapshot.data ?? const <VenueSake>[];
              final loading = snapshot.connectionState != ConnectionState.done;
              return CustomScrollView(
                controller: scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 12, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 18),
                              decoration: BoxDecoration(
                                color: const Color(0xFFCBD2DC),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE7EEF6),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.storefront_outlined,
                                  color: Color(0xFF143861),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      venue.displayName,
                                      style: const TextStyle(
                                        color: Color(0xFF143861),
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextButton.icon(
                                      onPressed: () => _openVenueInMaps(venue),
                                      icon: const Icon(
                                        Icons.open_in_new,
                                        size: 14,
                                      ),
                                      label: const Text('マップで開く'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFF143861,
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 12,
                                        ),
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(0, 48),
                                        alignment: Alignment.centerLeft,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: '閉じる',
                                onPressed: () =>
                                    Navigator.of(sheetContext).pop(),
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFF647184),
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                          if (!loading &&
                              !snapshot.hasError &&
                              sakes.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(
                                '${sakes.length}種類の日本酒',
                                style: const TextStyle(
                                  color: Color(0xFF143861),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (loading)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF143861),
                          ),
                        ),
                      ),
                    )
                  else if (snapshot.hasError || sakes.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          snapshot.hasError
                              ? '日本酒の一覧を読み込めませんでした。もう一度店舗を開いてください。'
                              : '公開された日本酒記録はありません。',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF647184),
                            height: 1.5,
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      sliver: SliverList.separated(
                        itemCount: sakes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, index) {
                          final sake = sakes[index];
                          final subtitle = [
                            if (sake.brewery?.trim().isNotEmpty == true)
                              sake.brewery!,
                            if (sake.type?.trim().isNotEmpty == true)
                              sake.type!,
                          ].join('・');
                          return Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () {
                                Navigator.of(sheetContext).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        SakeMasterDetailPage(venueSake: sake),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    _SakeThumbnail(
                                      imageUrl: preferredSakeImagePath(
                                        thumbnailImageUrl:
                                            sake.thumbnailImageUrl,
                                        primaryImageUrl: sake.primaryImageUrl,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sake.name,
                                            style: const TextStyle(
                                              color: Color(0xFF143861),
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              height: 1.4,
                                            ),
                                          ),
                                          if (subtitle.isNotEmpty) ...[
                                            const SizedBox(height: 5),
                                            Text(
                                              subtitle,
                                              style: const TextStyle(
                                                color: Color(0xFF647184),
                                                fontSize: 12,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEFF4FA),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${sake.recordCount}件の登録',
                                              style: const TextStyle(
                                                color: Color(0xFF143861),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: Color(0xFF9CA6B4),
                                      size: 22,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

const _nearbyMarkerDistancePixels = 74.0;
const _minimumNearbyMarkerZoom = 14.0;

_NearbyMarkerLayout _layoutNearbyMarkers(List<MapVenue> venues, double zoom) {
  if (venues.length < 2 || zoom < _minimumNearbyMarkerZoom) {
    return const _NearbyMarkerLayout();
  }

  final worldSize = 256 * math.pow(2.0, zoom).toDouble();
  final remaining = venues.toList(growable: true)
    ..sort((left, right) => left.venueId.compareTo(right.venueId));
  final worldPositions = <String, Offset>{
    for (final venue in venues)
      venue.venueId: _toWorldPixel(
        LatLng(venue.latitude, venue.longitude),
        worldSize,
      ),
  };
  final positions = <String, LatLng>{};
  final connectorLines = <Polyline>{};

  while (remaining.isNotEmpty) {
    final seed = remaining.removeAt(0);
    final seedPosition = worldPositions[seed.venueId]!;
    final group = <MapVenue>[seed];
    for (var index = remaining.length - 1; index >= 0; index -= 1) {
      final candidate = remaining[index];
      if ((worldPositions[candidate.venueId]! - seedPosition).distance <=
          _nearbyMarkerDistancePixels) {
        group.add(candidate);
        remaining.removeAt(index);
      }
    }
    if (group.length == 1) continue;

    group.sort((left, right) => left.venueId.compareTo(right.venueId));
    final center =
        group
            .map((venue) => worldPositions[venue.venueId]!)
            .reduce((left, right) => left + right) /
        group.length.toDouble();
    final radius = _nearbyMarkerRadius(group.length);

    for (var index = 0; index < group.length; index += 1) {
      final venue = group[index];
      final angle = group.length == 2
          ? math.pi * index
          : -math.pi / 2 + (2 * math.pi * index / group.length);
      final displayPixel =
          center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      final displayPosition = _fromWorldPixel(displayPixel, worldSize);
      final actualPosition = LatLng(venue.latitude, venue.longitude);
      positions[venue.venueId] = displayPosition;
      connectorLines.add(
        Polyline(
          polylineId: PolylineId('nearby-marker-${venue.venueId}'),
          points: [actualPosition, displayPosition],
          color: const Color(0xFF143861).withValues(alpha: 0.42),
          width: 2,
        ),
      );
    }
  }

  return _NearbyMarkerLayout(
    positions: positions,
    connectorLines: connectorLines,
  );
}

double _nearbyMarkerRadius(int count) {
  if (count == 2) return 42;
  final radius = 38 / math.sin(math.pi / count);
  return radius.clamp(48, 110).toDouble();
}

Offset _toWorldPixel(LatLng position, double worldSize) {
  final sinLatitude = math
      .sin(position.latitude * math.pi / 180)
      .clamp(-0.9999, 0.9999)
      .toDouble();
  return Offset(
    (position.longitude + 180) / 360 * worldSize,
    (0.5 - math.log((1 + sinLatitude) / (1 - sinLatitude)) / (4 * math.pi)) *
        worldSize,
  );
}

LatLng _fromWorldPixel(Offset pixel, double worldSize) {
  final longitude = pixel.dx / worldSize * 360 - 180;
  final mercator = math.pi - 2 * math.pi * pixel.dy / worldSize;
  final hyperbolicSine = (math.exp(mercator) - math.exp(-mercator)) / 2;
  final latitude = 180 / math.pi * math.atan(hyperbolicSine);
  return LatLng(latitude, longitude);
}

class _NearbyMarkerLayout {
  const _NearbyMarkerLayout({
    this.positions = const {},
    this.connectorLines = const {},
  });

  final Map<String, LatLng> positions;
  final Set<Polyline> connectorLines;
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 64,
        height: 84,
        child: ColoredBox(
          color: const Color(0xFFE7EBEF),
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
