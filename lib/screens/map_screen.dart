import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/tools_models.dart';
import '../services/alex_api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/glass.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late Future<List<MapMarkerData>> _future;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _future = context.read<AlexApiService>().getMapData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Carte d\'Alex', style: AppTheme.wordmark(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.creamDim),
            onPressed: () => setState(() => _future = context.read<AlexApiService>().getMapData()),
          ),
        ],
      ),
      body: FutureBuilder<List<MapMarkerData>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.amber, strokeWidth: 2),
            );
          }
          final markers = snapshot.data ?? [];
          if (markers.isEmpty) {
            return const Center(
              child: Text('Aucun lieu enregistré pour le moment.', style: TextStyle(color: AppColors.creamFaint)),
            );
          }
          return Stack(
            children: [
              _FlutterMapView(markers: markers, mapController: _mapController),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: GlassPanel(
                  borderRadius: 14,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Text(
                    '${markers.length} lieu${markers.length > 1 ? 'x' : ''} enregistré${markers.length > 1 ? 's' : ''}',
                    style: const TextStyle(color: AppColors.creamDim, fontSize: 12.5),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FlutterMapView extends StatelessWidget {
  const _FlutterMapView({required this.markers, required this.mapController});

  final List<MapMarkerData> markers;
  final MapController mapController;

  @override
  Widget build(BuildContext context) {
    final center = LatLng(markers.first.lat, markers.first.lng);

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(initialCenter: center, initialZoom: markers.length > 1 ? 5 : 12),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.alex.mobile',
        ),
        const RichAttributionWidget(
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),
        MarkerLayer(
          markers: markers
              .map(
                (m) => Marker(
                  point: LatLng(m.lat, m.lng),
                  width: 120,
                  height: 56,
                  child: _MapPin(marker: m),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.marker});

  final MapMarkerData marker;

  Color get _pinColor {
    try {
      final hex = marker.color.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.75),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _pinColor.withOpacity(0.6)),
          ),
          child: Text(
            marker.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.cream, fontSize: 10.5),
          ),
        ),
        const SizedBox(height: 2),
        Icon(Icons.location_on_rounded, color: _pinColor, size: 26),
      ],
    );
  }
}
