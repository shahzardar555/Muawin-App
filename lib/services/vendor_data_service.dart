import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:cross_file/cross_file.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
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
  String _vendorId = '';

  /// Default vendor data structure
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

  /// Get current vendor ID from Supabase by looking up auth user → profile → vendor
  Future<String> _getCurrentVendorId() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return '';

      final profile = await supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .single();

      final profileId = profile['id']?.toString() ?? '';
      if (profileId.isEmpty) return '';

      final vendor = await supabase
          .from('vendors')
          .select('id')
          .eq('profile_id', profileId)
          .single();

      final id = vendor['id']?.toString() ?? '';
      _vendorId = id;
      return id;
    } catch (e) {
      debugPrint('Error getting vendor ID: $e');
      return '';
    }
  }

  @override
  Future<Map<String, dynamic>> getVendorData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final vendorDataJson = prefs.getString(_vendorDataKey);

      if (vendorDataJson != null) {
        return Map<String, dynamic>.from(jsonDecode(vendorDataJson));
      }

      return {};
    } catch (e) {
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
      // Keep SharedPreferences update for local cache
      final prefs = await SharedPreferences.getInstance();
      final dataStr = prefs.getString(_vendorDataKey);
      if (dataStr != null) {
        final data = Map<String, dynamic>.from(jsonDecode(dataStr));
        data[field] = value;
        await prefs.setString(_vendorDataKey, jsonEncode(data));
      }

      // Also update Supabase
      final vendorId = await _getCurrentVendorId();
      if (vendorId.isEmpty) return true;

      final supabase = Supabase.instance.client;

      // Map field names to vendors table columns
      final columnMap = {
        'name': 'business_name',
        'category': 'business_type',
        'address': 'address',
        'city': 'city',
        'about': 'about',
        'phone': null, // phone is in profiles table, skip
        'mapsLink': 'location',
      };

      final column = columnMap[field];
      if (column != null) {
        await supabase
            .from('vendors')
            .update({column: value}).eq('id', vendorId);
        debugPrint('Vendor field updated: $field = $value');

        // If address updated, geocode and save coordinates
        // Address format is like "Lake City, Lahore"
        if (field == 'address') {
          try {
            // Use the address value directly for geocoding
            final address = value.trim();
            if (address.isNotEmpty) {
              // Parse address into parts
              // "Lake City, Lahore" → area: "Lake City", city: "Lahore"
              final parts = address.split(',');
              final area = parts.length > 1 ? parts[0].trim() : '';
              final city = parts.length > 1
                  ? parts[parts.length - 1].trim()
                  : parts[0].trim();

              final geocodeResponse = await http.post(
                Uri.parse(
                    'https://muawin-nodejs-backend-production.up.railway.app/api/geo/geocode'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'city': city,
                  'area': area,
                }),
              );

              if (geocodeResponse.statusCode == 200) {
                final geoData = jsonDecode(geocodeResponse.body);
                if (geoData['success'] == true) {
                  await supabase.from('vendors').update({
                    'latitude': geoData['latitude'],
                    'longitude': geoData['longitude'],
                  }).eq('id', vendorId);
                  debugPrint('Vendor coordinates saved: '
                      '${geoData['latitude']}, ${geoData['longitude']}');
                }
              }
            }
          } catch (e) {
            debugPrint('Vendor geocoding error (non-fatal): $e');
          }
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error updating vendor field: $e');
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
      if (imageUrl == null || imageUrl.isEmpty) return true;
      if (imageUrl.startsWith('http')) {
        // Already a URL, just save to profiles table
        final supabase = Supabase.instance.client;
        final user = supabase.auth.currentUser;
        if (user == null) return true;

        final profile = await supabase
            .from('profiles')
            .select('id')
            .eq('user_id', user.id)
            .single();

        await supabase
            .from('profiles')
            .update({'profile_image_url': imageUrl}).eq('id', profile['id']);

        // Also update local cache
        final prefs = await SharedPreferences.getInstance();
        final dataStr = prefs.getString(_vendorDataKey);
        if (dataStr != null) {
          final data = Map<String, dynamic>.from(jsonDecode(dataStr));
          data['profileImageUrl'] = imageUrl;
          await prefs.setString(_vendorDataKey, jsonEncode(data));
        }
        return true;
      }

      // Upload to Supabase Storage
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return true;

      final profile = await supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .single();

      final profileId = profile['id']?.toString() ?? '';
      final fileName =
          'vendor_${profileId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      if (kIsWeb) {
        // On web, imageUrl is a blob URL — use XFile to read bytes
        try {
          final xfile = XFile(imageUrl);
          final bytes = await xfile.readAsBytes();

          debugPrint('=== UPLOADING VENDOR AVATAR (WEB) ===');
          final webUploadResult = await supabase.storage
              .from('vendor-avatars')
              .uploadBinary(fileName, bytes,
                  fileOptions: const FileOptions(
                    upsert: true,
                    contentType: 'image/jpeg',
                  ));
          debugPrint('=== UPLOAD RESULT: $webUploadResult ===');

          final publicUrl =
              supabase.storage.from('vendor-avatars').getPublicUrl(fileName);
          debugPrint('=== PUBLIC URL: $publicUrl ===');

          await supabase
              .from('profiles')
              .update({'profile_image_url': publicUrl}).eq('id', profileId);
          debugPrint('=== PROFILE UPDATED ===');

          // Also update local cache
          final prefs = await SharedPreferences.getInstance();
          final dataStr = prefs.getString(_vendorDataKey);
          if (dataStr != null) {
            final data = Map<String, dynamic>.from(jsonDecode(dataStr));
            data['profileImageUrl'] = publicUrl;
            await prefs.setString(_vendorDataKey, jsonEncode(data));
          }

          debugPrint('Vendor web avatar uploaded: $publicUrl');
        } catch (e) {
          debugPrint('=== UPLOAD ERROR: $e ===');
        }
        return true;
      }

      debugPrint('=== UPLOADING VENDOR AVATAR (MOBILE) ===');
      final file = File(imageUrl);
      final uploadResult = await supabase.storage
          .from('vendor-avatars')
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));
      debugPrint('=== UPLOAD RESULT: $uploadResult ===');

      final publicUrl =
          supabase.storage.from('vendor-avatars').getPublicUrl(fileName);
      debugPrint('=== PUBLIC URL: $publicUrl ===');

      await supabase
          .from('profiles')
          .update({'profile_image_url': publicUrl}).eq('id', profileId);
      debugPrint('=== PROFILE UPDATED ===');

      // Also update local cache
      final prefs = await SharedPreferences.getInstance();
      final dataStr = prefs.getString(_vendorDataKey);
      if (dataStr != null) {
        final data = Map<String, dynamic>.from(jsonDecode(dataStr));
        data['profileImageUrl'] = publicUrl;
        await prefs.setString(_vendorDataKey, jsonEncode(data));
      }

      debugPrint('Vendor profile picture uploaded: $publicUrl');
      return true;
    } catch (e) {
      debugPrint('=== UPLOAD ERROR: $e ===');
      return false;
    }
  }

  Future<bool> updateCoverPhoto(
      String? coverPhotoUrl, String? coverPhotoPath) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      final profile = await supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .single();

      final profileId = profile['id']?.toString() ?? '';
      final vendorId = await _getCurrentVendorId();
      if (vendorId.isEmpty) return false;

      final fileName =
          'cover_vendor_${profileId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      String publicUrl = '';

      if (kIsWeb && coverPhotoUrl != null && coverPhotoUrl.isNotEmpty) {
        final xfile = XFile(coverPhotoUrl);
        final bytes = await xfile.readAsBytes();
        await supabase.storage
            .from('vendor-covers')
            .uploadBinary(fileName, bytes,
                fileOptions: const FileOptions(
                  upsert: true,
                  contentType: 'image/jpeg',
                ));
        publicUrl =
            supabase.storage.from('vendor-covers').getPublicUrl(fileName);
      } else if (coverPhotoPath != null && coverPhotoPath.isNotEmpty) {
        final file = File(coverPhotoPath);
        await supabase.storage.from('vendor-covers').upload(fileName, file,
            fileOptions: const FileOptions(upsert: true));
        publicUrl =
            supabase.storage.from('vendor-covers').getPublicUrl(fileName);
      }

      if (publicUrl.isNotEmpty) {
        await supabase
            .from('vendors')
            .update({'cover_photo_url': publicUrl}).eq('id', vendorId);
        debugPrint('Vendor cover photo uploaded: $publicUrl');
      }

      return true;
    } catch (e) {
      debugPrint('Error uploading vendor cover photo: $e');
      return false;
    }
  }

  @override
  Future<bool> updateRating(String rating) async {
    try {
      final vendorId = await _getCurrentVendorId();
      if (vendorId.isEmpty) return true;

      final supabase = Supabase.instance.client;
      await supabase.from('vendors').update(
          {'rating': double.tryParse(rating) ?? 0.0}).eq('id', vendorId);

      debugPrint('Vendor rating updated: $rating');
      return true;
    } catch (e) {
      debugPrint('Error updating rating: $e');
      return false;
    }
  }

  @override
  Future<bool> updateReviewCount(int count) async {
    try {
      final vendorId = await _getCurrentVendorId();
      if (vendorId.isEmpty) return true;

      final supabase = Supabase.instance.client;
      await supabase
          .from('vendors')
          .update({'review_count': count}).eq('id', vendorId);

      debugPrint('Vendor review count updated: $count');
      return true;
    } catch (e) {
      debugPrint('Error updating review count: $e');
      return false;
    }
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
    return await getVendorField('name') ?? '';
  }

  @override
  Future<String> getVendorCategory() async {
    return await getVendorField('category') ?? '';
  }

  @override
  Future<String> getVendorPhone() async {
    return await getVendorField('phone') ?? '';
  }

  @override
  Future<String> getVendorAddress() async {
    return await getVendorField('address') ?? '';
  }

  @override
  Future<String> getVendorMapsLink() async {
    return await getVendorField('mapsLink') ?? '';
  }

  @override
  Future<String> getVendorAbout() async {
    return await getVendorField('about') ?? '';
  }

  @override
  Future<String?> getVendorProfileImageUrl() async {
    return await getVendorField('profileImageUrl');
  }

  @override
  Future<String> getVendorRating() async {
    return await getVendorField('rating') ?? '0.0';
  }

  @override
  Future<int> getVendorReviewCount() async {
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
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      String statusStr;
      if (status == VendorStatus.busy) {
        statusStr = 'busy';
      } else if (status == VendorStatus.break_) {
        statusStr = 'break';
      } else if (status == VendorStatus.closed) {
        statusStr = 'closed';
      } else {
        statusStr = 'open';
      }

      // Get vendor ID
      final profile = await supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .single();
      final profileId = profile['id'].toString();

      final vendor = await supabase
          .from('vendors')
          .select('id')
          .eq('profile_id', profileId)
          .single();
      final vendorId = vendor['id'].toString();

      await supabase
          .from('vendors')
          .update({'status': statusStr}).eq('id', vendorId);

      debugPrint('Vendor status saved to Supabase: $statusStr');
      return true;
    } catch (e) {
      debugPrint('Error saving vendor status: $e');
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
