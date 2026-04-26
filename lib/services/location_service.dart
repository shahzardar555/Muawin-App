import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:math';
import 'featured_ad_manager.dart';

class LocationService {
  static const String _userLocationKey = 'user_location_';
  static const double _earthRadiusKm = 6371.0; // Earth's radius in kilometers

  /// Get current user's location
  static Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are disabled. Don't continue.
        return null;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permissions are denied, next time you could try showing permissions again.
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever, handle appropriately.
        return null;
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      return null;
    }
  }

  /// Save user location to SharedPreferences
  static Future<void> saveUserLocation(String userId, Position location) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final locationData = {
        'latitude': location.latitude,
        'longitude': location.longitude,
        'timestamp': location.timestamp.toIso8601String(),
        'accuracy': location.accuracy,
      };

      await prefs.setString(
          '$_userLocationKey$userId', jsonEncode(locationData));
    } catch (e) {
      // Handle error silently
    }
  }

  /// Get user's saved location
  static Future<Position?> getUserLocation(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationJson = prefs.getString('$_userLocationKey$userId');

      if (locationJson == null) return null;

      final locationData = jsonDecode(locationJson) as Map<String, dynamic>;

      return Position(
        latitude: locationData['latitude'] as double,
        longitude: locationData['longitude'] as double,
        timestamp: DateTime.parse(locationData['timestamp'] as String),
        accuracy: locationData['accuracy'] as double,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    } catch (e) {
      return null;
    }
  }

  /// Calculate distance between two points using Haversine formula
  static double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2));

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return _earthRadiusKm * c;
  }

  /// Convert degrees to radians
  static double _toRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Filter featured ads by location within specified radius
  static Future<List<FeaturedAd>> filterByLocation(
      List<FeaturedAd> ads, Position userLocation, double maxDistanceKm) async {
    final List<FeaturedAd> filteredAds = [];

    for (final ad in ads) {
      // Get provider/vendor location
      final providerLocation = await getUserLocation(ad.userId);

      if (providerLocation != null) {
        // Calculate distance
        final distance = calculateDistance(
          userLocation.latitude,
          userLocation.longitude,
          providerLocation.latitude,
          providerLocation.longitude,
        );

        // Include ad if within radius
        if (distance <= maxDistanceKm) {
          // Create a new ad with calculated distance
          final adWithDistance = FeaturedAd(
            id: ad.id,
            userId: ad.userId,
            userType: ad.userType,
            userName: ad.userName,
            userCategory: ad.userCategory,
            userRating: ad.userRating,
            userDistance: distance,
            tagline: ad.tagline,
            planType: ad.planType,
            planPrice: ad.planPrice,
            startDate: ad.startDate,
            endDate: ad.endDate,
            isActive: ad.isActive,
            profileImageUrl: ad.profileImageUrl,
            userProfileData: ad.userProfileData,
          );

          filteredAds.add(adWithDistance);
        }
      } else {
        // If no location data, include with default distance (for testing)
        final adWithDefaultDistance = FeaturedAd(
          id: ad.id,
          userId: ad.userId,
          userType: ad.userType,
          userName: ad.userName,
          userCategory: ad.userCategory,
          userRating: ad.userRating,
          userDistance: 5.0, // Default distance for testing
          tagline: ad.tagline,
          planType: ad.planType,
          planPrice: ad.planPrice,
          startDate: ad.startDate,
          endDate: ad.endDate,
          isActive: ad.isActive,
          profileImageUrl: ad.profileImageUrl,
          userProfileData: ad.userProfileData,
        );

        filteredAds.add(adWithDefaultDistance);
      }
    }

    return filteredAds;
  }

  /// Get nearby featured ads for a user
  static Future<List<FeaturedAd>> getNearbyFeaturedAds(
      String userId, double maxDistanceKm) async {
    try {
      // Get user's current location
      final userLocation = await getCurrentLocation();

      if (userLocation == null) {
        // If can't get location, return all ads with default distance
        final featuredManager = FeaturedAdManager();
        return featuredManager.activeFeaturedAds;
      }

      // Save user location for future reference
      await saveUserLocation(userId, userLocation);

      // Get all featured ads and filter by location
      final featuredManager = FeaturedAdManager();
      final allAds = featuredManager.activeFeaturedAds;

      return await filterByLocation(allAds, userLocation, maxDistanceKm);
    } catch (e) {
      // Return all ads as fallback
      final featuredManager = FeaturedAdManager();
      return featuredManager.activeFeaturedAds;
    }
  }

  /// Get distance between two users
  static Future<double?> getDistanceBetweenUsers(
      String userId1, String userId2) async {
    try {
      final location1 = await getUserLocation(userId1);
      final location2 = await getUserLocation(userId2);

      if (location1 == null || location2 == null) {
        return null;
      }

      return calculateDistance(
        location1.latitude,
        location1.longitude,
        location2.latitude,
        location2.longitude,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if location permissions are granted
  static Future<bool> hasLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      return false;
    }
  }

  /// Request location permissions
  static Future<LocationPermission> requestLocationPermission() async {
    try {
      return await Geolocator.requestPermission();
    } catch (e) {
      return LocationPermission.denied;
    }
  }

  /// Format distance for display
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1.0) {
      return '${(distanceKm * 1000).toInt()} m';
    } else {
      return '${distanceKm.toStringAsFixed(1)} km';
    }
  }
}
