import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserProfileService {
  static const String _userEmailKey = 'user_email';
  static const String _userProfileDataKey = 'user_profile_data';

  /// Get the current user's complete profile data
  static Future<Map<String, dynamic>> getCurrentUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if user is logged in by checking email
      final userEmail = prefs.getString(_userEmailKey);
      if (userEmail == null) {
        return _getDefaultProfile();
      }

      // Get user type from email
      String userType = 'customer';
      if (userEmail == 'am@pro.com') {
        userType = 'provider';
      } else if (userEmail == 'am@vendor.com') {
        userType = 'vendor';
      }

      // Get stored profile data or use defaults
      final profileDataJson =
          prefs.getString('${_userProfileDataKey}_$userType');
      Map<String, dynamic> profileData = {};

      if (profileDataJson != null) {
        profileData = jsonDecode(profileDataJson) as Map<String, dynamic>;
      }

      return {
        'userType': userType,
        'userId': profileData['userId'] ?? _getUserIdForType(userType),
        'userName': profileData['userName'] ?? _getUserNameForType(userType),
        'userCategory':
            profileData['userCategory'] ?? _getUserCategoryForType(userType),
        'userRating':
            profileData['userRating'] ?? _getUserRatingForType(userType),
        'userEmail': userEmail,
        'profileData': profileData,
      };
    } catch (e) {
      return _getDefaultProfile();
    }
  }

  /// Get current user ID
  static Future<String> getCurrentUserId() async {
    final profile = await getCurrentUserProfile();
    return profile['userId'] as String;
  }

  /// Get current user type (provider/vendor/customer)
  static Future<String> getCurrentUserType() async {
    final profile = await getCurrentUserProfile();
    return profile['userType'] as String;
  }

  /// Get current user name
  static Future<String> getCurrentUserName() async {
    final profile = await getCurrentUserProfile();
    return profile['userName'] as String;
  }

  /// Get current user category
  static Future<String> getCurrentUserCategory() async {
    final profile = await getCurrentUserProfile();
    return profile['userCategory'] as String;
  }

  /// Get current user rating
  static Future<double> getCurrentUserRating() async {
    final profile = await getCurrentUserProfile();
    return (profile['userRating'] as num).toDouble();
  }

  /// Save user profile data
  static Future<void> saveUserProfileData(
      Map<String, dynamic> profileData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userType = profileData['userType'] as String;

      await prefs.setString(
          '${_userProfileDataKey}_$userType', jsonEncode(profileData));
    } catch (e) {
      // Handle error silently for now
    }
  }

  /// Get default profile for fallback
  static Map<String, dynamic> _getDefaultProfile() {
    return {
      'userType': 'customer',
      'userId': 'customer_default',
      'userName': 'Guest User',
      'userCategory': 'General',
      'userRating': 4.0,
      'userEmail': null,
      'profileData': {},
    };
  }

  /// Get user ID based on type
  static String _getUserIdForType(String userType) {
    switch (userType) {
      case 'provider':
        return 'provider_001';
      case 'vendor':
        return 'vendor_001';
      case 'customer':
      default:
        return 'customer_001';
    }
  }

  /// Get user name based on type
  static String _getUserNameForType(String userType) {
    switch (userType) {
      case 'provider':
        return 'Professional Provider';
      case 'vendor':
        return 'Local Vendor';
      case 'customer':
      default:
        return 'Customer';
    }
  }

  /// Get user category based on type
  static String _getUserCategoryForType(String userType) {
    switch (userType) {
      case 'provider':
        return 'Driver'; // Default provider category
      case 'vendor':
        return 'Supermarket'; // Default vendor category
      case 'customer':
      default:
        return 'General';
    }
  }

  /// Get user rating based on type
  static double _getUserRatingForType(String userType) {
    switch (userType) {
      case 'provider':
        return 4.8;
      case 'vendor':
        return 4.5;
      case 'customer':
      default:
        return 4.0;
    }
  }

  /// Update user category
  static Future<void> updateUserCategory(String category) async {
    try {
      final profile = await getCurrentUserProfile();
      profile['userCategory'] = category;
      profile['profileData']['userCategory'] = category;
      await saveUserProfileData(profile['profileData']);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Update user name
  static Future<void> updateUserName(String name) async {
    try {
      final profile = await getCurrentUserProfile();
      profile['userName'] = name;
      profile['profileData']['userName'] = name;
      await saveUserProfileData(profile['profileData']);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Check if user is logged in
  static Future<bool> isUserLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_userEmailKey);
    } catch (e) {
      return false;
    }
  }
}
