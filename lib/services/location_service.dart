import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import '../models/report_model.dart';

class LocationResult {
  final ReportLocation? location;
  final String? error;
  const LocationResult({this.location, this.error});

  bool get isSuccess => location != null;
}

class LocationService {
  Future<LocationResult> getCurrentLocation() async {
    // Web Mock (Instant)
    if (kIsWeb) {
      await Future.delayed(const Duration(seconds: 1));
      return const LocationResult(
        location: ReportLocation(
          latitude: -33.0153,
          longitude: 27.9116,
          accuracy: 10.0,
        ),
      );
    }

    // Mobile Logic wrapped in a 15-second absolute timer
    try {
      return await _fetchMobileLocation().timeout(
        const Duration(seconds: 15),
        onTimeout: () => const LocationResult(
          error: 'GPS timed out. Make sure phone Location is ON and you are near a window.',
        ),
      );
    } on TimeoutException {
       return const LocationResult(
          error: 'GPS timed out. Make sure phone Location is ON and you are near a window.',
        );
    } catch (e) {
      return LocationResult(error: 'Location error: $e');
    }
  }

  Future<LocationResult> _fetchMobileLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationResult(
        error: 'Location services are disabled on this phone.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return const LocationResult(
          error: 'Location permission denied. Check phone settings.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationResult(
        error: 'Location permission permanently denied.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      return LocationResult(
        location: ReportLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
        ),
      );
    } catch (e) {
      // Fallback to last known
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        return LocationResult(
          location: ReportLocation(
            latitude: last.latitude,
            longitude: last.longitude,
            accuracy: last.accuracy,
          ),
        );
      }
      return LocationResult(error: 'Could not get GPS fix. Error: $e');
    }
  }
}