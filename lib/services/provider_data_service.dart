import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/service_details.dart';
import '../models/user_profile.dart';

/// Centralized service for managing provider data
/// Handles data synchronization between provider and customer views
class ProviderDataService {
  static const String _providerDataKey = 'provider_data';
  static const String _experienceKey = 'experience';
  static const String _availabilityKey = 'availability';
  static const String _serviceAreasKey = 'service_areas';
  static const String _descriptionKey = 'service_description';
  static const String _serviceTypeKey = 'service_type';
  static const String _hourlyRateKey = 'hourly_rate';
  static const String _contactPhoneKey = 'contact_phone';
  static const String _emailKey = 'email';
  static const String _responseTimeKey = 'response_time';
  static const String _workingHoursKey = 'working_hours';
  static const String _profileImagePathKey = 'profile_image_path';
  static const String _providerNameKey = 'provider_name';

  /// Get provider data for both provider and customer views
  /// Returns comprehensive provider profile data from SharedPreferences
  static Future<Map<String, dynamic>> getProviderData(String providerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load all provider-related data
      // TODO: Load from Supabase
      final experience = prefs.getString(_experienceKey) ?? '';
      final availability = prefs.getString(_availabilityKey) ?? '';
      final serviceAreas = prefs.getStringList(_serviceAreasKey) ?? [];
      final description = prefs.getString(_descriptionKey) ?? '';
      final serviceType = prefs.getString(_serviceTypeKey) ?? '';
      final hourlyRate = prefs.getString(_hourlyRateKey) ?? '';
      final contactPhone = prefs.getString(_contactPhoneKey) ?? '';
      final email = prefs.getString(_emailKey) ?? '';
      final responseTime = prefs.getString(_responseTimeKey) ?? '';
      final workingHours = prefs.getString(_workingHoursKey) ?? '';
      final profileImagePath = prefs.getString(_profileImagePathKey);
      final providerName = prefs.getString(_providerNameKey) ?? '';

      return {
        'id': providerId,
        'experience': experience,
        'availability': availability,
        'service_areas': serviceAreas,
        'description': description,
        'service_type': serviceType,
        'hourly_rate': hourlyRate,
        'contact_phone': contactPhone,
        'email': email,
        'response_time': responseTime,
        'working_hours': workingHours,
        'profile_image_path': profileImagePath,
        'provider_name': providerName,
        'category': serviceType, // For backward compatibility
      };
    } catch (e) {
      debugPrint('Error loading provider data: $e');
      // TODO: Load from Supabase
      // Return default data on error
      return {
        'id': providerId,
        'experience': '',
        'availability': '',
        'service_areas': <String>[],
        'description': '',
        'service_type': '',
        'hourly_rate': '',
        'contact_phone': '',
        'email': '',
        'response_time': '',
        'working_hours': '',
        'profile_image_path': null,
        'provider_name': '',
        'category': '',
      };
    }
  }

  /// Update provider data from provider side with real-time synchronization
  /// Saves all provider details to SharedPreferences and notifies listeners
  /// Future: Add API call for backend synchronization
  static Future<void> updateProviderData(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get current data to merge
      final currentDataJson = prefs.getString(_providerDataKey);
      Map<String, dynamic> currentData = {};
      if (currentDataJson != null) {
        currentData = jsonDecode(currentDataJson) as Map<String, dynamic>;
      }

      // Update with new data
      currentData.addAll(data);

      // Save individual fields for backward compatibility
      if (data.containsKey('experience')) {
        await prefs.setString(_experienceKey, data['experience']);
      }
      if (data.containsKey('availability')) {
        await prefs.setString(_availabilityKey, data['availability']);
      }
      if (data.containsKey('description')) {
        await prefs.setString(_descriptionKey, data['description']);
      }
      if (data.containsKey('service_type')) {
        await prefs.setString(_serviceTypeKey, data['service_type']);
      }
      if (data.containsKey('hourly_rate')) {
        await prefs.setString(_hourlyRateKey, data['hourly_rate']);
      }
      if (data.containsKey('contact_phone')) {
        await prefs.setString(_contactPhoneKey, data['contact_phone']);
      }
      if (data.containsKey('email')) {
        await prefs.setString(_emailKey, data['email']);
      }
      if (data.containsKey('response_time')) {
        await prefs.setString(_responseTimeKey, data['response_time']);
      }
      if (data.containsKey('working_hours')) {
        await prefs.setString(_workingHoursKey, data['working_hours']);
      }
      if (data.containsKey('profile_image_path')) {
        final profileImagePath = data['profile_image_path'];
        if (profileImagePath != null) {
          await prefs.setString(_profileImagePathKey, profileImagePath);
        } else {
          await prefs.remove(_profileImagePathKey);
        }
      }
      if (data.containsKey('provider_name')) {
        await prefs.setString(_providerNameKey, data['provider_name']);
      }

      // Save merged data as JSON
      final updatedDataJson = jsonEncode(currentData);
      await prefs.setString(_providerDataKey, updatedDataJson);

      // Notify all listeners of the change
      notifyDataChangeListeners(currentData);

      debugPrint('Provider data updated and synchronized: $currentData');
    } catch (e) {
      debugPrint('Error updating provider data: $e');
      rethrow;
    }
  }

  /// Save provider data as JSON for complex scenarios
  /// Save provider data as JSON for complex scenarios
  static Future<void> saveProviderDataJson(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataJson = jsonEncode(data);
      await prefs.setString(_providerDataKey, dataJson);
      debugPrint('Provider data saved as JSON');
    } catch (e) {
      debugPrint('Error saving provider data JSON: $e');
    }
  }

  /// Load provider data from JSON (legacy support)
  static Future<Map<String, dynamic>?> loadProviderDataJson(
      String providerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final providerDataJson = prefs.getString('provider_data_$providerId');
      if (providerDataJson != null) {
        return jsonDecode(providerDataJson) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error loading provider data JSON: $e');
    }
    return null;
  }

  /// Add real-time data change listener for service details synchronization
  static void addProviderDataChangeListener(
      void Function(Map<String, dynamic>) listener) {
    // Store the listener for real-time updates
    _dataChangeListener = listener;
  }

  /// Notify all listeners of service details changes
  static void notifyDataChangeListeners(Map<String, dynamic> updatedData) {
    if (_dataChangeListener != null) {
      _dataChangeListener!(updatedData);
    }
  }

  // Data change listener storage
  static void Function(Map<String, dynamic>)? _dataChangeListener;

  /// Clear all provider data (for testing/reset)
  static Future<void> clearProviderData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_experienceKey);
      await prefs.remove(_availabilityKey);
      await prefs.remove(_serviceAreasKey);
      await prefs.remove(_descriptionKey);
      await prefs.remove(_serviceTypeKey);
      await prefs.remove(_hourlyRateKey);
      await prefs.remove(_providerDataKey);
      debugPrint('Provider data cleared');
    } catch (e) {
      debugPrint('Error clearing provider data: $e');
    }
  }

  // ===== PROFILE-SPECIFIC METHODS =====

  /// Get user profile data with type safety
  static Future<UserProfile> getUserProfile({String? phoneNumber}) async {
    try {
      final providerData = await getProviderData(phoneNumber ?? 'default');

      return UserProfile.fromJson(providerData);
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      return UserProfile.defaultValues();
    }
  }

  /// Update user profile data with type safety
  static Future<void> updateUserProfile(UserProfile profile) async {
    try {
      final profileJson = profile.toJson();
      await updateProviderData(profileJson);
      debugPrint('User profile updated successfully');
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  /// Update profile image path
  static Future<void> updateProfileImage(String imagePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileImagePathKey, imagePath);

      // Also update the main provider data
      await updateProviderData({'profile_image_path': imagePath});

      debugPrint('Profile image updated: $imagePath');
    } catch (e) {
      debugPrint('Error updating profile image: $e');
      rethrow;
    }
  }

  /// Get service details data with type safety
  static Future<ServiceDetails> getServiceDetails() async {
    try {
      final providerData = await getProviderData('default');

      return ServiceDetails.fromJson(providerData);
    } catch (e) {
      debugPrint('Error loading service details: $e');
      return ServiceDetails.defaultValues();
    }
  }

  /// Update service details data with type safety
  static Future<void> updateServiceDetails(ServiceDetails details) async {
    try {
      final detailsJson = details.toJson();
      await updateProviderData(detailsJson);
      debugPrint('Service details updated successfully');
    } catch (e) {
      debugPrint('Error updating service details: $e');
      rethrow;
    }
  }

  /// Save profile state for complex scenarios
  static Future<void> saveProfileState(Map<String, dynamic> state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = jsonEncode(state);
      await prefs.setString('profile_state', stateJson);
      debugPrint('Profile state saved');
    } catch (e) {
      debugPrint('Error saving profile state: $e');
    }
  }

  /// Load profile state for complex scenarios
  static Future<Map<String, dynamic>> loadProfileState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString('profile_state');
      if (stateJson != null) {
        return jsonDecode(stateJson) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error loading profile state: $e');
    }
    return {};
  }
}
