import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/tools_models.dart';
import '../services/alex_api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/glass.dart';

/// Écran carte avec MapLibre GL JS intégré via WebView.
///
/// Affiche une carte interactive stylée MapLibre (dark theme, sans clé API)
/// avec les markers enregistrés par Alex. Si le WebView n'est pas disponible,
/// fallback sur flutter_map avec les tuiles OSM standard.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late Future<List<MapMarkerData>> _future;
  final MapController _mapController = MapController();
  bool _useWebView = true;

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
            icon: Icon(
              _useWebView ? Icons.map_rounded : Icons.map_outlined,
              color: AppColors.creamDim,
            ),
            onPressed: () => setState(() => _useWebView = !_useWebView),
            tooltip: _useWebView ? 'Vue MapLibre' : 'Vue OSM',
          ),
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
              if (_useWebView)
                _MapLibreWebView(markers: markers)
              else
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

/// Vue MapLibre GL JS intégrée via WebView (tuiles sans clé API).
class _MapLibreWebView extends StatefulWidget {
  const _MapLibreWebView({required this.markers});

  final List<MapMarkerData> markers;

  @override
  State<_MapLibreWebView> createState() => _MapLibreWebViewState();
}

class _MapLibreWebViewState extends State<_MapLibreWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(_buildHtml());
  }

  String _buildHtml() {
    final markersJson = widget.markers.map((m) => '''
      {
        "lngLat": [${m.lng}, ${m.lat}],
        "label": "${_escapeHtml(m.label)}",
        "color": "${m.color}"
      }
    ''').join(',');

    final center = widget.markers.isNotEmpty
        ? [widget.markers.first.lng, widget.markers.first.lat]
        : [2.3522, 48.8566]; // Paris par défaut

    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link href="https://unpkg.com/maplibre-gl@4.1.0/dist/maplibre-gl.css" rel="stylesheet">
<script src="https://unpkg.com/maplibre-gl@4.1.0/dist/maplibre-gl.js"></script>
<style>
  body { margin: 0; padding: 0; }
  #map { position: absolute; top: 0; bottom: 0; width: 100%; }
</style>
</head>
<body>
<div id="map"></div>
<script>
const map = new maplibregl.Map({
  container: 'map',
  style: {
    version: 8,
    sources: {
      osm: {
        type: 'raster',
        tiles: ['https://tile.openstreetmap.org/{z}/{x}/{y}.png'],
        tileSize: 256,
        attribution: '© OpenStreetMap contributors'
      }
    },
    layers: [{
      id: 'osm',
      type: 'raster',
      source: 'osm'
    }],
    glyphs: 'https://fonts.openmaptiles.org/{fontstack}/{range}.pbf'
  },
  center: $center,
  zoom: 13,
  pitch: 45,
  bearing: -17
});

map.addControl(new maplibregl.NavigationControl(), 'top-right');

const markers = [$markersJson];

markers.forEach(m => {
  const el = document.createElement('div');
  el.style.cssText = 'width:28px;height:28px;border-radius:50%;background:' + m.color + ';border:2px solid rgba(0,0,0,0.5);box-shadow:0 2px 8px rgba(0,0,0,0.4);';
  const label = document.createElement('div');
  label.textContent = m.label;
  label.style.cssText = 'position:absolute;top:-24px;left:50%;transform:translateX(-50%);background:rgba(0,0,0,0.8);color:#fff;padding:2px 6px;border-radius:4px;font-size:11px;white-space:nowrap;';
  el.appendChild(label);

  new maplibregl.Marker({ element: el })
    .setLngLat(m.lngLat)
    .addTo(map);
});

if (markers.length > 1) {
  const bounds = new maplibregl.LngLatBounds();
  markers.forEach(m => bounds.extend(m.lngLat));
  map.fitBounds(bounds, { padding: 50 });
} else if (markers.length === 1) {
  map.setCenter(markers[0].lngLat);
  map.setZoom(15);
}
</script>
</body>
</html>''';
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}

/// Fallback flutter_map sans WebView.
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
