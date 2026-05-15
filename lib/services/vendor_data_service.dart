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
  // TODO: Connect to Supabase
  static const String _vendorId = '';

  /// Default vendor data structure
  // TODO: Connect to Supabase
  static const Map<String, dynamic> _defaultVendorData = {
    'id': '',
    'name': '',
    'category': '',
    'phone': '',
    'address': '',
    'mapsLink': '',
    'about': '',
    'profileImageUrl': null,
    'coverPhotoUrl': null,
    'coverPhotoPath': null,
    'rating': '0.0',
    'reviewCount': 0,
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

      // TODO: Connect to Supabase
      return {};
    } catch (e) {
      // TODO: Connect to Supabase
      return {};
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
    // TODO: Connect to Supabase
    return await getVendorField('name') ?? '';
  }

  @override
  Future<String> getVendorCategory() async {
    // TODO: Connect to Supabase
    return await getVendorField('category') ?? '';
  }

  @override
  Future<String> getVendorPhone() async {
    // TODO: Connect to Supabase
    return await getVendorField('phone') ?? '';
  }

  @override
  Future<String> getVendorAddress() async {
    // TODO: Connect to Supabase
    return await getVendorField('address') ?? '';
  }

  @override
  Future<String> getVendorMapsLink() async {
    // TODO: Connect to Supabase
    return await getVendorField('mapsLink') ?? '';
  }

  @override
  Future<String> getVendorAbout() async {
    // TODO: Connect to Supabase
    return await getVendorField('about') ?? '';
  }

  @override
  Future<String?> getVendorProfileImageUrl() async {
    return await getVendorField('profileImageUrl');
  }

  @override
  Future<String> getVendorRating() async {
    // TODO: Connect to Supabase
    return await getVendorField('rating') ?? '0.0';
  }

  @override
  Future<int> getVendorReviewCount() async {
    // TODO: Connect to Supabase
    final count = await getVendorField('reviewCount');
    return int.tryParse(count ?? '') ?? 0;
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
  // TODO: Connect to Supabase
  static String get vendorId => '';

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
