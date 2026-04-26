import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Utility class for managing notification filter preferences
class FilterPreferences {
  static const String _prefix = 'notification_filters_';
  static const String _enabledPrefix = 'filters_enabled_';

  /// Save filter selections for a specific tab
  static Future<void> saveFilters(String tab, List<String> filters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('$_prefix$tab', filters);
      await prefs.setBool('$_enabledPrefix$tab', filters.isNotEmpty);
    } catch (e) {
      debugPrint('Error saving filters for $tab: $e');
    }
  }

  /// Get filter selections for a specific tab
  static Future<List<String>> getFilters(String tab) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList('$_prefix$tab') ?? [];
    } catch (e) {
      debugPrint('Error getting filters for $tab: $e');
      return [];
    }
  }

  /// Check if filters are enabled for a specific tab
  static Future<bool> areFiltersEnabled(String tab) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('$_enabledPrefix$tab') ?? false;
    } catch (e) {
      debugPrint('Error checking filter enabled status for $tab: $e');
      return false;
    }
  }

  /// Clear all filters for a specific tab
  static Future<void> clearFilters(String tab) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_prefix$tab');
      await prefs.setBool('$_enabledPrefix$tab', false);
    } catch (e) {
      debugPrint('Error clearing filters for $tab: $e');
    }
  }

  /// Clear all filter preferences (for reset functionality)
  static Future<void> clearAllFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_prefix) || key.startsWith(_enabledPrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('Error clearing all filters: $e');
    }
  }

  /// Get available filter options for a specific tab
  static List<String> getFilterOptionsForTab(String tab) {
    switch (tab.toLowerCase()) {
      case 'jobs':
        return [
          'unread',
          'read',
          'today',
          'this_week',
          'this_month',
          'active',
          'completed',
          'cancelled',
          'pending',
          'low_priority',
          'medium_priority',
          'high_priority',
          'urgent',
          'emergency'
        ];
      case 'payments':
        return [
          'unread',
          'read',
          'today',
          'this_week',
          'this_month',
          'paid',
          'pending',
          'failed',
          'refunded',
          'under_50',
          '50_to_200',
          '200_to_500',
          'over_500'
        ];
      case 'reviews':
        return [
          'unread',
          'read',
          'today',
          'this_week',
          'this_month',
          '5_star',
          '4_star',
          '3_star',
          '2_star',
          '1_star',
          'positive',
          'negative',
          'neutral'
        ];
      case 'alerts':
        return [
          'unread',
          'read',
          'today',
          'this_week',
          'this_month',
          'low_priority',
          'medium_priority',
          'high_priority',
          'urgent',
          'emergency',
          'system',
          'account',
          'security',
          'marketing'
        ];
      case 'verify':
        return [
          'unread',
          'read',
          'today',
          'this_week',
          'this_month',
          'pending',
          'approved',
          'rejected',
          'document',
          'profile',
          'business'
        ];
      case 'ads':
        return [
          'unread',
          'read',
          'today',
          'this_week',
          'this_month',
          'active',
          'expired',
          'expiring_soon',
          'featured',
          'standard'
        ];
      case 'chat':
        return [
          'unread',
          'read',
          'today',
          'this_week',
          'this_month',
          'customer',
          'provider',
          'system',
          'group',
          'direct'
        ];
      case 'calls':
        return [
          'unread',
          'read',
          'today',
          'this_week',
          'this_month',
          'missed',
          'received',
          'ended',
          'voice',
          'video'
        ];
      default:
        return ['unread', 'read', 'today', 'this_week', 'this_month'];
    }
  }

  /// Get display labels for filter options
  static String getFilterLabel(String filterOption) {
    switch (filterOption) {
      // Read status
      case 'unread':
        return 'Unread';
      case 'read':
        return 'Read';

      // Time filters
      case 'today':
        return 'Today';
      case 'this_week':
        return 'This Week';
      case 'this_month':
        return 'This Month';

      // Job filters
      case 'active':
        return 'Active';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'pending':
        return 'Pending';

      // Priority filters
      case 'low_priority':
        return 'Low Priority';
      case 'medium_priority':
        return 'Medium Priority';
      case 'high_priority':
        return 'High Priority';
      case 'urgent':
        return 'Urgent';
      case 'emergency':
        return 'Emergency';

      // Payment filters
      case 'paid':
        return 'Paid';
      case 'failed':
        return 'Failed';
      case 'refunded':
        return 'Refunded';

      // Amount filters
      case 'under_50':
        return 'Under \$50';
      case '50_to_200':
        return '\$50-\$200';
      case '200_to_500':
        return '\$200-\$500';
      case 'over_500':
        return 'Over \$500';

      // Review filters
      case '5_star':
        return '5 Stars';
      case '4_star':
        return '4 Stars';
      case '3_star':
        return '3 Stars';
      case '2_star':
        return '2 Stars';
      case '1_star':
        return '1 Star';
      case 'positive':
        return 'Positive';
      case 'negative':
        return 'Negative';
      case 'neutral':
        return 'Neutral';

      // Alert filters
      case 'system':
        return 'System';
      case 'account':
        return 'Account';
      case 'security':
        return 'Security';
      case 'marketing':
        return 'Marketing';

      // Verification filters
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'document':
        return 'Document';
      case 'profile':
        return 'Profile';
      case 'business':
        return 'Business';

      // Ad filters
      case 'expired':
        return 'Expired';
      case 'expiring_soon':
        return 'Expiring Soon';
      case 'featured':
        return 'Featured';
      case 'standard':
        return 'Standard';

      // Chat filters
      case 'customer':
        return 'Customer';
      case 'provider':
        return 'Provider';
      case 'group':
        return 'Group';
      case 'direct':
        return 'Direct';

      // Call filters
      case 'missed':
        return 'Missed';
      case 'received':
        return 'Received';
      case 'ended':
        return 'Ended';
      case 'voice':
        return 'Voice';
      case 'video':
        return 'Video';

      default:
        return filterOption
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }
}
