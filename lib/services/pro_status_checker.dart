import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service to check and manage Muawin PRO subscription status
/// PRO features are only enabled when:
/// - subscription_type = 'pro'
/// - payment_status = 'completed'
/// - subscription_status = 'active'
/// - all_steps_completed = true
class ProStatusChecker {
  static const String _subscriptionDataKey = 'subscription_data';
  static const String _subscriptionTypeKey = 'subscription_type';
  static const String _paymentStatusKey = 'payment_status';
  static const String _subscriptionStatusKey = 'subscription_status';
  static const String _allStepsCompletedKey = 'all_steps_completed';
  static const String _paymentVerifiedKey = 'payment_verified';
  static const String _subscriptionStartDateKey = 'subscription_start_date';
  static const String _subscriptionEndDateKey = 'subscription_end_date';

  /// Check if the current user is a fully paid PRO user
  /// Returns true only when all conditions are met:
  /// - subscription_type = 'pro'
  /// - payment_status = 'completed'
  /// - subscription_status = 'active'
  /// - all_steps_completed = true
  /// - payment_verified = true
  static Future<bool> isProUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final subscriptionData = prefs.getString(_subscriptionDataKey);

      if (subscriptionData == null) {
        // No subscription data = basic user
        return false;
      }

      final data = jsonDecode(subscriptionData) as Map<String, dynamic>;

      // Check all required conditions for PRO status
      return data[_subscriptionTypeKey] == 'pro' &&
          data[_paymentStatusKey] == 'completed' &&
          data[_subscriptionStatusKey] == 'active' &&
          data[_allStepsCompletedKey] == true &&
          data[_paymentVerifiedKey] == true;
    } catch (e) {
      // On any error, treat as basic user (safe default)
      return false;
    }
  }

  /// Check if user is in the middle of upgrade process
  /// Returns true if subscription_type = 'pro' but payment is not completed
  /// or all steps are not completed
  static Future<bool> isUpgradeInProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final subscriptionData = prefs.getString(_subscriptionDataKey);

      if (subscriptionData == null) {
        // No subscription data = not upgrading
        return false;
      }

      final data = jsonDecode(subscriptionData) as Map<String, dynamic>;

      // Check if upgrade is in progress
      return data[_subscriptionTypeKey] == 'pro' &&
          (data[_paymentStatusKey] != 'completed' ||
              data[_allStepsCompletedKey] != true ||
              data[_paymentVerifiedKey] != true);
    } catch (e) {
      // On any error, treat as not upgrading
      return false;
    }
  }

  /// Get complete subscription data
  static Future<Map<String, dynamic>?> getSubscriptionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final subscriptionData = prefs.getString(_subscriptionDataKey);

      if (subscriptionData == null) {
        return null;
      }

      return jsonDecode(subscriptionData) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Save subscription data (called when user completes upgrade)
  static Future<bool> saveSubscriptionData(
      Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_subscriptionDataKey, jsonEncode(data));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Mark subscription as completed (called after successful payment)
  static Future<bool> markSubscriptionCompleted({
    required String subscriptionType,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingData = await getSubscriptionData() ?? {};

      final updatedData = {
        ...existingData,
        _subscriptionTypeKey: subscriptionType,
        _paymentStatusKey: 'completed',
        _subscriptionStatusKey: 'active',
        _allStepsCompletedKey: true,
        _paymentVerifiedKey: true,
        _subscriptionStartDateKey: startDate,
        _subscriptionEndDateKey: endDate,
      };

      await prefs.setString(_subscriptionDataKey, jsonEncode(updatedData));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Mark upgrade as started (called when user begins upgrade process)
  static Future<bool> markUpgradeStarted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingData = await getSubscriptionData() ?? {};

      final updatedData = {
        ...existingData,
        _subscriptionTypeKey: 'pro',
        _paymentStatusKey: 'pending',
        _subscriptionStatusKey: 'pending',
        _allStepsCompletedKey: false,
        _paymentVerifiedKey: false,
      };

      await prefs.setString(_subscriptionDataKey, jsonEncode(updatedData));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clear subscription data (for testing or cancellation)
  static Future<bool> clearSubscriptionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_subscriptionDataKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get subscription type ('basic', 'pro', or null)
  static Future<String?> getSubscriptionType() async {
    try {
      final data = await getSubscriptionData();
      if (data == null) return 'basic'; // Default to basic
      return data[_subscriptionTypeKey] as String? ?? 'basic';
    } catch (e) {
      return 'basic';
    }
  }

  /// Get subscription end date
  static Future<String?> getSubscriptionEndDate() async {
    try {
      final data = await getSubscriptionData();
      if (data == null) return null;
      return data[_subscriptionEndDateKey] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Check if subscription is expired
  static Future<bool> isSubscriptionExpired() async {
    try {
      final endDateStr = await getSubscriptionEndDate();
      if (endDateStr == null) return true;

      final endDate = DateTime.parse(endDateStr);
      return DateTime.now().isAfter(endDate);
    } catch (e) {
      return true; // On error, treat as expired
    }
  }
}
