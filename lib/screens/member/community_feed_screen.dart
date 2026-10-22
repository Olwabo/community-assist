import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_statuses.dart';
import '../../constants/app_categories.dart';
import '../../models/report_model.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import 'report/report_details_screen.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final _reportService = ReportService();
  final _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    final currentUid = _auth.currentUid;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Community Feed'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.map_outlined), text: 'Map'),
              Tab(icon: Icon(Icons.list_alt), text: 'List'),
            ],
          ),
        ),
        body: StreamBuilder<List<ReportModel>>(
          stream: _reportService.streamCommunityReports(excludeUid: currentUid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final reports = snapshot.data ?? [];
            if (reports.isEmpty) {
              return const Center(
                child: Text('No other reports in your community yet.'),
              );
            }

              return RefreshIndicator(
              onRefresh: () async {
                // A quick 1-second fake delay to show the spinner
                await Future.delayed(const Duration(seconds: 1));
              },
              child: TabBarView(
                children: [
                  _buildMap(reports),
                  _buildList(reports),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // MAP VIEW

  Widget _buildMap(List<ReportModel> reports) {
    // KuGompo Metro center
    final center = const LatLng(-33.0153, 27.9116);

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 12,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.umphakathi.app',
          maxNativeZoom: 17,
          maxZoom: 17,
        ),
        MarkerLayer(
          markers: reports.map((r) {
            return Marker(
              point: LatLng(r.location.latitude, r.location.longitude),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReportDetailsScreen(reportId: r.id),
                    ),
                  );
                },
                child: Icon(
                  r.category.icon,
                  color: r.status.color,
                  size: 32,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // LIST VIEW

  Widget _buildList(List<ReportModel> reports) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: reports.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final r = reports[index];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReportDetailsScreen(reportId: r.id),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: r.status.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(r.category.icon, color: r.status.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.category.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          r.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: r.status.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      r.status.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: r.status.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}