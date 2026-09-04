import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../domain/repository/place_map_repository.dart';
import '../common/widgets/primary_app_bar.dart';
import 'sake_map_page_notifier.dart';

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
    target: LatLng(26.2124, 127.6809),
    zoom: 12,
  );

  final _searchController = TextEditingController();
  GoogleMapController? _mapController;
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
    final markers = state.venues
        .map(
          (venue) => Marker(
            markerId: MarkerId(venue.venueId),
            position: LatLng(venue.latitude, venue.longitude),
            infoWindow: InfoWindow(
              title: venue.displayName,
              snippet: '${venue.sakeCount}種類・${venue.recordCount}件の公開記録',
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
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) async {
              _mapController = controller;
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
                                result.brewery ??
                                    (result.isMaster ? '日本酒マスター' : '公開記録の名称'),
                              ),
                              onTap: () {
                                _searchController.text = result.name;
                                FocusScope.of(context).unfocus();
                                notifier.selectSake(result);
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
                          label: Text('${state.selectedSake!.name}が飲まれた店舗'),
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
              bottom: 28,
              child: _MapMessage(
                message: state.errorMessage ?? 'この範囲には公開された飲酒記録がありません。',
                onRetry: state.errorMessage == null ? null : notifier.refresh,
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
        builder: (context, snapshot) {
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
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Text('この店で飲まれた日本酒'),
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
                            itemBuilder: (context, index) {
                              final sake = sakes[index];
                              return ListTile(
                                leading: sake.imageUrl == null
                                    ? const CircleAvatar(
                                        child: Icon(Icons.wine_bar_outlined),
                                      )
                                    : CircleAvatar(
                                        backgroundImage: NetworkImage(
                                          sake.imageUrl!,
                                        ),
                                      ),
                                title: Text(sake.name),
                                subtitle: Text(
                                  [
                                    if (sake.brewery != null) sake.brewery!,
                                    if (sake.type != null) sake.type!,
                                  ].join('・'),
                                ),
                                trailing: Text('${sake.recordCount}件'),
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
