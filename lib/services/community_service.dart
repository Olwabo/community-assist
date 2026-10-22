import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/community_config.dart';
import '../models/report_model.dart';

class CommunityService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream the current community config.
  Stream<CommunityConfig?> streamConfig() {
    return _db.collection('config').doc('community').snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return CommunityConfig.fromMap(snap.data()!);
    });
  }

  // Get the community config once.
  Future<CommunityConfig?> getConfig() async {
    try {
      final doc = await _db.collection('config').doc('community').get()
          .timeout(const Duration(seconds: 5)); // <- Add timeout
      if (!doc.exists || doc.data() == null) return null;
      return CommunityConfig.fromMap(doc.data()!);
    } catch (e) {
      // If Firestore fails (e.g. no internet), return null
      return null; 
    }
  }

  // Check if a location is inside the community boundary.
  LocationCheckResult? checkLocation({
    required CommunityConfig community,
    required ReportLocation location,
  }) {
    final distanceMeters = Geolocator.distanceBetween(
      community.latitude,
      community.longitude,
      location.latitude,
      location.longitude,
    );
    final distanceKm = distanceMeters / 1000;
    return LocationCheckResult(
      isInside: distanceKm <= community.radiusKm,
      distanceKm: distanceKm,
      community: community,
      userLat: location.latitude,
      userLng: location.longitude,
    );
  }

  // Convenience: check a ReportLocation against a live config.
  Future<LocationCheckResult?> checkReportLocation(ReportLocation location) async {
    final config = await getConfig();
    if (config == null) return null;
    return checkLocation(community: config, location: location);
  }
}