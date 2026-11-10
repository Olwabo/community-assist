import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../constants/app_colors.dart';
import '../models/report_model.dart';

class LocationMap extends StatelessWidget {
  final ReportLocation location;
  final double height;
  final bool interactive;
  final ValueChanged<ReportLocation>? onLocationChanged;

  const LocationMap({
    super.key,
    required this.location,
    this.height = 240,
    this.interactive = true,
    this.onLocationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final center = LatLng(location.latitude, location.longitude);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 16,
            minZoom: 3,
            maxZoom: 19,
            interactionOptions: InteractionOptions(
              flags: interactive
                  ? InteractiveFlag.all & ~InteractiveFlag.rotate
                  : InteractiveFlag.none,
            ),
            onTap: interactive && onLocationChanged != null
                ? (tapPos, latlng) {
                    onLocationChanged!(
                      ReportLocation(
                        latitude: latlng.latitude,
                        longitude: latlng.longitude,
                        accuracy: location.accuracy,
                        address: location.address,
                      ),
                    );
                  }
                : null,
          ),
          children: [
            // Esri World Street Map (No API key needed)
            TileLayer(
              urlTemplate:
                  'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
              userAgentPackageName: 'com.umphakathi.app',
              maxNativeZoom: 19,
              maxZoom: 19,
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  width: 50,
                  height: 50,
                  alignment: Alignment.topCenter,
                  child: const _LocationPin(),
                ),
              ],
            ),
            if (interactive)
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    '© OpenStreetMap contributors',
                    onTap: () {},
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _LocationPin extends StatelessWidget {
  const _LocationPin();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          bottom: 0,
          child: Container(
            width: 16,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const Icon(
          Icons.location_on,
          size: 44,
          color: AppColors.error,
        ),
      ],
    );
  }
}