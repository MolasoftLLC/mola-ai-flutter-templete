import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../../common/localization/localization_extensions.dart';
import '../../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../../domain/repository/place_map_repository.dart';

enum _PlaceSearchMode { nearby, name }

class PlacePickerSheet extends StatefulWidget {
  const PlacePickerSheet({super.key, this.initialPlace});

  final String? initialPlace;

  static Future<DrinkingPlace?> show(
    BuildContext context, {
    String? initialPlace,
  }) {
    return showModalBottomSheet<DrinkingPlace>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.78,
        child: PlacePickerSheet(initialPlace: initialPlace),
      ),
    );
  }

  @override
  State<PlacePickerSheet> createState() => _PlacePickerSheetState();
}

class _PlacePickerSheetState extends State<PlacePickerSheet> {
  final _queryController = TextEditingController();
  Timer? _searchDebounce;
  _PlaceSearchMode _mode = _PlaceSearchMode.nearby;
  List<PlaceCandidate> _places = const [];
  Position? _position;
  bool _isLoading = false;
  bool _isPermissionPermanentlyDenied = false;
  String? _errorMessage;
  int _requestId = 0;

  PlaceMapRepository get _placeMapRepository =>
      context.read<PlaceMapRepository>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNearbyPlaces());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        top: 12,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 12,
      ),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.initialPlace?.isNotEmpty == true
                      ? context.l10n.changeConsumedPlace
                      : context.l10n.addConsumedPlace,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Text(
            context.l10n.shopContributionNotice,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 12),
          SegmentedButton<_PlaceSearchMode>(
            segments: [
              ButtonSegment(
                value: _PlaceSearchMode.nearby,
                icon: const Icon(Icons.near_me),
                label: Text(context.l10n.findPlaceNearby),
              ),
              ButtonSegment(
                value: _PlaceSearchMode.name,
                icon: const Icon(Icons.search),
                label: Text(context.l10n.findPlaceByName),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (selection) {
              final mode = selection.first;
              if (mode == _mode) return;
              setState(() {
                _requestId++;
                _mode = mode;
                _places = const [];
                _isLoading = false;
                _errorMessage = null;
              });
              if (mode == _PlaceSearchMode.nearby) {
                _loadNearbyPlaces();
              }
            },
          ),
          const SizedBox(height: 16),
          if (_mode == _PlaceSearchMode.name) ...[
            TextField(
              controller: _queryController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onQueryChanged,
              onSubmitted: (_) => _searchByName(),
              decoration: InputDecoration(
                hintText: context.l10n.placeNameSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _queryController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _queryController.clear();
                          _onQueryChanged('');
                        },
                        icon: const Icon(Icons.clear),
                      ),
                filled: true,
                fillColor: const Color(0xFFF3F5F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Expanded(child: _buildContent()),
          if (_places.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                context.l10n.poweredByGoogle,
                style: const TextStyle(color: Colors.black45, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final query = _queryController.text.trim();
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text(
              _mode == _PlaceSearchMode.nearby
                  ? context.l10n.searchingNearbyPlaces
                  : context.l10n.searchingPlaces,
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off_outlined, size: 44),
            const SizedBox(height: 12),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            if (_isPermissionPermanentlyDenied)
              FilledButton.tonalIcon(
                onPressed: Geolocator.openAppSettings,
                icon: const Icon(Icons.settings),
                label: Text(context.l10n.openSettings),
              )
            else if (_mode == _PlaceSearchMode.nearby)
              FilledButton.tonalIcon(
                onPressed: _loadNearbyPlaces,
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.findPlaceNearby),
              ),
          ],
        ),
      );
    }

    if (_mode == _PlaceSearchMode.name && query.isEmpty) {
      return Center(child: Text(context.l10n.placeNameSearchHint));
    }

    if (_places.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _mode == _PlaceSearchMode.nearby
                  ? context.l10n.noNearbyPlaces
                  : context.l10n.noPlaceResults,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: _places.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final place = _places[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFF0F3F7),
            child: Icon(Icons.place_outlined, color: Color(0xFF1D3567)),
          ),
          title: Text(
            place.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: place.formattedAddress == null
              ? null
              : Text(
                  place.formattedAddress!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
          trailing: place.distanceMeters == null
              ? null
              : Text(
                  _formatDistance(place.distanceMeters!),
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
          onTap: () => Navigator.of(context).pop(place.toDrinkingPlace()),
        );
      },
    );
  }

  void _onQueryChanged(String value) {
    _searchDebounce?.cancel();
    setState(() {
      _requestId++;
      _isLoading = false;
      _errorMessage = null;
      if (value.trim().isEmpty) _places = const [];
    });
    if (value.trim().length < 2) return;
    _searchDebounce = Timer(const Duration(milliseconds: 450), _searchByName);
  }

  Future<void> _loadNearbyPlaces() async {
    final requestId = ++_requestId;
    final locationServicesDisabled = context.l10n.locationServicesDisabled;
    final locationPermissionPermanentlyDenied =
        context.l10n.locationPermissionPermanentlyDenied;
    final locationPermissionDenied = context.l10n.locationPermissionDenied;
    final placeSearchFailed = context.l10n.placeSearchFailed;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isPermissionPermanentlyDenied = false;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw _LocationMessage(locationServicesDisabled);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _isPermissionPermanentlyDenied = true;
        throw _LocationMessage(locationPermissionPermanentlyDenied);
      }
      if (permission == LocationPermission.denied) {
        throw _LocationMessage(locationPermissionDenied);
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      );
      final places = await _placeMapRepository.searchNearby(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _position = position;
        _places = places;
      });
    } on _LocationMessage catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() => _errorMessage = placeSearchFailed);
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _searchByName() async {
    final query = _queryController.text.trim();
    if (query.length < 2) return;
    final requestId = ++_requestId;
    final placeSearchFailed = context.l10n.placeSearchFailed;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final places = await _placeMapRepository.searchByName(
        query,
        latitude: _position?.latitude,
        longitude: _position?.longitude,
      );
      if (!mounted ||
          requestId != _requestId ||
          query != _queryController.text.trim()) {
        return;
      }
      setState(() => _places = places);
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() => _errorMessage = placeSearchFailed);
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDistance(double distanceMeters) {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }
}

class _LocationMessage implements Exception {
  const _LocationMessage(this.message);

  final String message;
}
