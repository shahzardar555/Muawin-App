import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'vendor_service.dart';

/// Vendor status enum for state management
enum VendorStatus {
  open,
  busy,
  break_,
  closed,
}

/// Mock VendorService implementation using SharedPreferences
/// Provides persistent storage with backend-ready architecture
class MockVendorService implements VendorService {
  static const String _vendorDataKey = 'vendor_data';
  static const String _vendorId = 'vendor_001';

  /// Default vendor data structure
  static const Map<String, dynamic> _defaultVendorData = {
    'id': 'vendor_001',
    'name': 'Super Grocery Store',
    'category': 'Grocery Store',
    'phone': '+923001234567',
    'address': 'Gulberg III, Lahore',
    'mapsLink': 'https://maps.google.com/?q=Gulberg+III+Lahore',
    'about': 'Fresh groceries and daily essentials delivered to your doorstep.',
    'profileImageUrl': null,
    'coverPhotoUrl': null,
    'coverPhotoPath': null,
    'rating': '4.5',
    'reviewCount': 3,
  };

  @override
  String get vendorId => _vendorId;

  @override
  Future<Map<String, dynamic>> getVendorData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final vendorDataJson = prefs.getString(_vendorDataKey);

      if (vendorDataJson != null) {
        return Map<String, dynamic>.from(jsonDecode(vendorDataJson));
      }

      // Return default data if nothing stored
      return Map<String, dynamic>.from(_defaultVendorData);
    } catch (e) {
      // Return default data on error
      return Map<String, dynamic>.from(_defaultVendorData);
    }
  }

  @override
  Future<String?> getVendorField(String field) async {
    try {
      final vendorData = await getVendorData();
      return vendorData[field]?.toString();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> updateVendorField(String field, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentData = await getVendorData();

      // Update the field
      currentData[field] = value;

      // Save updated data
      await prefs.setString(_vendorDataKey, jsonEncode(currentData));
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> updateVendorFields(Map<String, String> updates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentData = await getVendorData();

      // Update all provided fields
      updates.forEach((field, value) {
        currentData[field] = value;
      });

      // Save updated data
      await prefs.setString(_vendorDataKey, jsonEncode(currentData));
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> updateProfilePicture(String? imageUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentData = await getVendorData();

      // Update profile picture URL
      currentData['profileImageUrl'] = imageUrl;

      // Save updated data
      await prefs.setString(_vendorDataKey, jsonEncode(currentData));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateCoverPhoto(
      String? coverPhotoUrl, String? coverPhotoPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentData = await getVendorData();

      // Update cover photo fields
      currentData['coverPhotoUrl'] = coverPhotoUrl;
      currentData['coverPhotoPath'] = coverPhotoPath;

      // Save updated data
      await prefs.setString(_vendorDataKey, jsonEncode(currentData));
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> updateRating(String rating) async {
    return await updateVendorField('rating', rating);
  }

  @override
  Future<bool> updateReviewCount(int count) async {
    return await updateVendorField('reviewCount', count.toString());
  }

  @override
  Future<bool> resetToDefaults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_vendorDataKey, jsonEncode(_defaultVendorData));
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_vendorDataKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> hasVendorData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_vendorDataKey);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String> getVendorName() async {
    return await getVendorField('name') ?? _defaultVendorData['name'];
  }

  @override
  Future<String> getVendorCategory() async {
    return await getVendorField('category') ?? _defaultVendorData['category'];
  }

  @override
  Future<String> getVendorPhone() async {
    return await getVendorField('phone') ?? _defaultVendorData['phone'];
  }

  @override
  Future<String> getVendorAddress() async {
    return await getVendorField('address') ?? _defaultVendorData['address'];
  }

  @override
  Future<String> getVendorMapsLink() async {
    return await getVendorField('mapsLink') ?? _defaultVendorData['mapsLink'];
  }

  @override
  Future<String> getVendorAbout() async {
    return await getVendorField('about') ?? _defaultVendorData['about'];
  }

  @override
  Future<String?> getVendorProfileImageUrl() async {
    return await getVendorField('profileImageUrl');
  }

  @override
  Future<String> getVendorRating() async {
    return await getVendorField('rating') ?? _defaultVendorData['rating'];
  }

  @override
  Future<int> getVendorReviewCount() async {
    final count = await getVendorField('reviewCount');
    return int.tryParse(count ?? '') ?? _defaultVendorData['reviewCount'];
  }
}

/// Legacy static wrapper for backward compatibility
/// @deprecated Use ServiceLocator.vendorService instead
class VendorDataService {
  static final MockVendorService _instance = MockVendorService();

  static Future<Map<String, dynamic>> getVendorData() =>
      _instance.getVendorData();
  static Future<String?> getVendorField(String field) =>
      _instance.getVendorField(field);
  static Future<bool> updateVendorField(String field, String value) =>
      _instance.updateVendorField(field, value);
  static Future<bool> updateVendorFields(Map<String, String> updates) =>
      _instance.updateVendorFields(updates);
  static Future<bool> updateProfilePicture(String? imageUrl) =>
      _instance.updateProfilePicture(imageUrl);
  static Future<bool> updateRating(String rating) =>
      _instance.updateRating(rating);
  static Future<bool> updateReviewCount(int count) =>
      _instance.updateReviewCount(count);
  static Future<bool> resetToDefaults() => _instance.resetToDefaults();
  static Future<bool> clearAllData() => _instance.clearAllData();
  static Future<bool> hasVendorData() => _instance.hasVendorData();
  static String get vendorId => 'vendor_001';

  // Convenience getters for common fields
  static Future<String> getVendorName() async =>
      MockVendorService().getVendorName();
  static Future<String> getVendorCategory() async =>
      MockVendorService().getVendorCategory();
  static Future<String> getVendorPhone() async =>
      MockVendorService().getVendorPhone();
  static Future<String> getVendorAddress() async =>
      MockVendorService().getVendorAddress();
  static Future<String> getVendorMapsLink() async =>
      MockVendorService().getVendorMapsLink();
  static Future<String> getVendorAbout() async =>
      MockVendorService().getVendorAbout();
  static Future<String?> getVendorProfileImageUrl() async =>
      MockVendorService().getVendorProfileImageUrl();
  static Future<String> getVendorRating() async =>
      MockVendorService().getVendorRating();
  static Future<int> getVendorReviewCount() async =>
      MockVendorService().getVendorReviewCount();

  // Status management methods
  static Future<bool> updateVendorStatus(VendorStatus status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('vendor_status', status.toString());
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<VendorStatus> getVendorStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statusString = prefs.getString('vendor_status');
      if (statusString != null) {
        final statusInt = int.tryParse(statusString) ?? 0;
        if (statusInt < VendorStatus.values.length) {
          return VendorStatus.values[statusInt];
        }
      }
      return VendorStatus.open; // Default to open
    } catch (e) {
      return VendorStatus.open;
    }
  }

  static Future<bool> hasVendorStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey('vendor_status');
    } catch (e) {
      return false;
    }
  }
}
