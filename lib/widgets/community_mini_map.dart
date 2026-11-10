import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../constants/app_categories.dart';
import '../constants/app_statuses.dart';
import '../models/report_model.dart';
import '../screens/member/report/report_details_screen.dart';

class CommunityMiniMap extends StatelessWidget {
  final List<ReportModel> reports;
  final BuildContext parentContext;

  const CommunityMiniMap({
    super.key,
    required this.reports,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    // KuGompo Metro center
    const center = LatLng(-33.0153, 27.9116);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          SizedBox(
            height: 220,
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: center,
                initialZoom: 13,
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.umphakathi.app',
                  maxNativeZoom: 19,
                  maxZoom: 19,
                ),
                MarkerLayer(
                  markers: reports.map((r) {
                    return Marker(
                      point: LatLng(r.location.latitude, r.location.longitude),
                      width: 40,
                      height: 40,
                      alignment: Alignment.topCenter,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(parentContext).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ReportDetailsScreen(reportId: r.id),
                            ),
                          );
                        },
                        child: Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            Positioned(
                              bottom: 0,
                              child: Container(
                                width: 14,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            Icon(
                              Icons.location_on,
                              color: r.status.color,
                              size: 36,
                            ),
                            Positioned(
                              top: 6,
                              child: Icon(
                                r.category.icon,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('© OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 30,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.2),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}