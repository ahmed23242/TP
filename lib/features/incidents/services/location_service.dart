import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;

class LocationService {
  Future<Position?> getCurrentLocation() async {
    try {
      // Check location permission
      final status = await Permission.location.request();
      if (status != PermissionStatus.granted) {
        developer.log('Location permission denied');
        return null;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        developer.log('Location services are disabled');
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      developer.log('Location obtained: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e, stackTrace) {
      developer.log('Error getting location', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  Future<bool> requestLocationPermission() async {
    try {
      final status = await Permission.location.request();
      developer.log('Location permission status: $status');
      return status == PermissionStatus.granted;
    } catch (e, stackTrace) {
      developer.log('Error requesting location permission', error: e, stackTrace: stackTrace);
      return false;
    }
  }
} 