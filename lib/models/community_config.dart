import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityConfig {
  final String name;
  final double latitude;
  final double longitude;
  final double radiusKm;
  final bool isActive;

  const CommunityConfig({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
    this.isActive = true,
  });

  factory CommunityConfig.fromMap(Map<String, dynamic> map) {
    return CommunityConfig(
      name: map['name'] ?? 'Community',
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      radiusKm: (map['radiusKm'] as num?)?.toDouble() ?? 30.0,
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radiusKm': radiusKm,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class LocationCheckResult {
  final bool isInside;
  final double distanceKm;
  final CommunityConfig community;
  final double userLat;
  final double userLng;

  const LocationCheckResult({
    required this.isInside,
    required this.distanceKm,
    required this.community,
    required this.userLat,
    required this.userLng,
  });
}