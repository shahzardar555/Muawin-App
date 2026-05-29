import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'location_service.dart';

class FeaturedAd {
  final String id;
  final String userId;
  final String userType; // provider/vendor
  final String userName;
  final String userCategory;
  final double userRating;
  final double userDistance; // in km
  final String tagline;
  final String planType; // daily/weekly/monthly
  final int planPrice; // 99/500/1800
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String profileImageUrl;
  final Map userProfileData; // stores full profile for navigation
  final double? userLatitude; // New field for geolocation
  final double? userLongitude; // New field for geolocation

  FeaturedAd({
    required this.id,
    required this.userId,
    required this.userType,
    required this.userName,
    required this.userCategory,
    required this.userRating,
    required this.userDistance,
    required this.tagline,
    required this.planType,
    required this.planPrice,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.profileImageUrl,
    required this.userProfileData,
    this.userLatitude,
    this.userLongitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userType': userType,
      'userName': userName,
      'userCategory': userCategory,
      'userRating': userRating,
      'userDistance': userDistance,
      'tagline': tagline,
      'planType': planType,
      'planPrice': planPrice,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'profileImageUrl': profileImageUrl,
      'userProfileData': userProfileData,
      'userLatitude': userLatitude,
      'userLongitude': userLongitude,
    };
  }

  factory FeaturedAd.fromJson(Map<String, dynamic> json) {
    return FeaturedAd(
      id: json['id'],
      userId: json['userId'],
      userType: json['userType'],
      userName: json['userName'],
      userCategory: json['userCategory'],
      userRating: json['userRating'].toDouble(),
      userDistance: json['userDistance'].toDouble(),
      tagline: json['tagline'],
      planType: json['planType'],
      planPrice: json['planPrice'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      isActive: json['isActive'],
      profileImageUrl: json['profileImageUrl'],
      userProfileData: json['userProfileData'],
      userLatitude: json['userLatitude']?.toDouble(),
      userLongitude: json['userLongitude']?.toDouble(),
    );
  }
}

class FeaturedAdManager extends ChangeNotifier {
  static final FeaturedAdManager _instance = FeaturedAdManager._internal();
  factory FeaturedAdManager() => _instance;
  FeaturedAdManager._internal() {
    // In-memory cache is populated on demand via Supabase queries
  }

  // In-memory fallback list (populated by purchaseFeaturedAd for instant display)
  List<FeaturedAd> _activeFeaturedAds = [];

  List<FeaturedAd> get activeFeaturedAds =>
      List.unmodifiable(_activeFeaturedAds);

  void purchaseFeaturedAd({
    required String userId,
    required String userType,
    required String userName,
    required String userCategory,
    required double userRating,
    required double userDistance,
    required String tagline,
    required String planType,
    required int planPrice,
    Map<String, dynamic>? userProfileData,
    double? userLatitude,
    double? userLongitude,
  }) async {
    final now = DateTime.now();
    DateTime endDate;

    // Set end date based on plan type
    switch (planType) {
      case 'daily':
        endDate = now.add(const Duration(days: 1));
        break;
      case 'weekly':
        endDate = now.add(const Duration(days: 7));
        break;
      case 'monthly':
        endDate = now.add(const Duration(days: 30));
        break;
      default:
        endDate = now.add(const Duration(days: 7)); // default to weekly
    }

    final featuredAd = FeaturedAd(
      id: 'featured_ad_${now.millisecondsSinceEpoch}',
      userId: userId,
      userType: userType,
      userName: userName,
      userCategory: userCategory,
      userRating: userRating,
      userDistance: userDistance,
      tagline: tagline,
      planType: planType,
      planPrice: planPrice,
      startDate: now,
      endDate: endDate,
      isActive: true,
      profileImageUrl:
          userProfileData?['profileImageUrl'] ?? '', // Use actual profile image
      userProfileData: userProfileData ?? {}, // Use actual profile data
      userLatitude: userLatitude,
      userLongitude: userLongitude,
    );

    _activeFeaturedAds.add(featuredAd);
    notifyListeners();
  }

  List<FeaturedAd> getActiveFeaturedAds() {
    final now = DateTime.now();
    final activeAds = _activeFeaturedAds
        .where((ad) => ad.isActive && ad.endDate.isAfter(now))
        .toList();

    return activeAds;
  }

  /// Get featured ads filtered by location for a specific customer
  Future<List<FeaturedAd>> getFeaturedAdsForCustomer(
      String customerId, double maxDistanceKm) async {
    try {
      final supabase = Supabase.instance.client;
      final now = DateTime.now().toIso8601String();

      // Fetch active featured ads from Supabase with joined profile data
      final response = await supabase
          .from('featured_ads')
          .select('''
            *,
            vendors!left (
              id,
              business_name,
              business_type,
              rating,
              city,
              area,
              profiles!inner (
                full_name,
                profile_image_url
              )
            ),
            providers!left (
              id,
              service_category,
              rating,
              city,
              area,
              profiles!inner (
                full_name,
                profile_image_url
              )
            )
          ''')
          .eq('is_active', true)
          .gt('end_date', now)
          .order('created_at', ascending: false)
          .limit(10);

      final List<FeaturedAd> ads = [];

      for (final row in response) {
        final isVendor = row['vendor_id'] != null;
        final entity = isVendor
            ? (row['vendors'] as Map<String, dynamic>?)
            : (row['providers'] as Map<String, dynamic>?);
        final profile = entity?['profiles'] as Map<String, dynamic>?;

        final ad = FeaturedAd(
          id: row['id']?.toString() ?? '',
          userId: isVendor
              ? (row['vendor_id']?.toString() ?? '')
              : (row['provider_id']?.toString() ?? ''),
          userType: row['user_type']?.toString() ??
              (isVendor ? 'vendor' : 'provider'),
          userName: profile?['full_name']?.toString() ??
              entity?['business_name']?.toString() ??
              'Featured Partner',
          userCategory: isVendor
              ? (entity?['business_type']?.toString() ?? '')
              : (entity?['service_category']?.toString() ?? ''),
          userRating: (entity?['rating'] as num?)?.toDouble() ?? 0.0,
          userDistance: 0.0,
          tagline: row['tagline']?.toString() ?? '',
          planType: row['plan_type']?.toString() ?? 'weekly',
          planPrice: (row['plan_price'] as num?)?.toInt() ?? 0,
          startDate: DateTime.tryParse(row['start_date']?.toString() ?? '') ??
              DateTime.now(),
          endDate: DateTime.tryParse(row['end_date']?.toString() ?? '') ??
              DateTime.now(),
          isActive: row['is_active'] == true,
          profileImageUrl: profile?['profile_image_url']?.toString() ?? '',
          userProfileData: row,
        );
        ads.add(ad);
      }

      // Get customer location and filter by distance (keep existing location logic)
      final customerLocation =
          await LocationService.getUserLocation(customerId);

      if (customerLocation == null) {
        return ads;
      }

      return await LocationService.filterByLocation(
          ads, customerLocation, maxDistanceKm);
    } catch (e) {
      debugPrint('Error fetching featured ads from Supabase: $e');
      // Fallback to in-memory list
      return getActiveFeaturedAds();
    }
  }

  FeaturedAd? getFeaturedAdByUserId(String userId) {
    try {
      return _activeFeaturedAds
          .where((ad) => ad.userId == userId && ad.isActive)
          .first;
    } catch (e) {
      return null;
    }
  }

  void checkAdExpiry() {
    final now = DateTime.now();
    bool hasExpired = false;
    List<FeaturedAd> updatedAds = [];

    for (final ad in _activeFeaturedAds) {
      if (ad.isActive && ad.endDate.isBefore(now)) {
        // Create new ad object with isActive = false
        final expiredAd = FeaturedAd(
          id: ad.id,
          userId: ad.userId,
          userType: ad.userType,
          userName: ad.userName,
          userCategory: ad.userCategory,
          userRating: ad.userRating,
          userDistance: ad.userDistance,
          tagline: ad.tagline,
          planType: ad.planType,
          planPrice: ad.planPrice,
          startDate: ad.startDate,
          endDate: ad.endDate,
          isActive: false, // Mark as inactive
          profileImageUrl: ad.profileImageUrl,
          userProfileData: ad.userProfileData,
        );
        updatedAds.add(expiredAd);
        hasExpired = true;

        // Send expiry notification
        // This would need to be implemented based on user type
        // For now, just mark as inactive
      } else {
        updatedAds.add(ad);
      }
    }

    if (hasExpired) {
      _activeFeaturedAds = updatedAds;
      notifyListeners();
    }
  }

  void cancelFeaturedAd(String adId) {
    final adIndex = _activeFeaturedAds.indexWhere((ad) => ad.id == adId);
    if (adIndex != -1) {
      // Remove the ad and add a new one with isActive = false
      final originalAd = _activeFeaturedAds[adIndex];
      final cancelledAd = FeaturedAd(
        id: originalAd.id,
        userId: originalAd.userId,
        userType: originalAd.userType,
        userName: originalAd.userName,
        userCategory: originalAd.userCategory,
        userRating: originalAd.userRating,
        userDistance: originalAd.userDistance,
        tagline: originalAd.tagline,
        planType: originalAd.planType,
        planPrice: originalAd.planPrice,
        startDate: originalAd.startDate,
        endDate: originalAd.endDate,
        isActive: false, // Mark as inactive
        profileImageUrl: originalAd.profileImageUrl,
        userProfileData: originalAd.userProfileData,
      );
      _activeFeaturedAds[adIndex] = cancelledAd;
      notifyListeners();
    }
  }
}
