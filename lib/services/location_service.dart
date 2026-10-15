import 'package:geolocator/geolocator.dart';

import '../models/report_model.dart';

class LocationResult {
  final ReportLocation? location;
  final String? error;
  const LocationResult({this.location, this.error});

  bool get isSuccess => location != null;
}

class LocationService {
  /// Requests permission and returns a ReportLocation, or an error.
  Future<LocationResult> getCurrentLocation() async {
    try {
      // 1. Is location service on?
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(
          error: 'Location services are disabled. Please enable GPS.',
        );
      }

      // 2. Permission status
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const LocationResult(
            error: 'Location permission denied.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(
          error:
              'Location permission permanently denied. Enable it from app settings.',
        );
      }

      // 3. Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
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
      // Fallback: last known position if current fails (e.g. timeout)
      try {
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
      } catch (_) {}
      return LocationResult(error: 'Could not get location: $e');
    }
  }

  /// Opens the OS-level app settings for the user to grant permissions manually.
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}