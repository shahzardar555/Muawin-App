import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Service for managing notification settings with SharedPreferences
class NotificationSettingsService {
  static final NotificationSettingsService _instance =
      NotificationSettingsService._internal();
  factory NotificationSettingsService() => _instance;
  NotificationSettingsService._internal();

  // User type detection
  String? _userType;

  // Settings keys with user type prefixes
  static const String _customerPrefix = 'customer_notifications_';
  static const String _providerPrefix = 'provider_notifications_';
  static const String _vendorPrefix = 'vendor_notifications_';

  // Default settings values
  static const Map<String, bool> _defaultSettings = {
    'jobs_enabled': true,
    'payments_enabled': true,
    'reviews_enabled': true,
    'alerts_enabled': true,
    'verification_enabled': true,
    'ads_enabled': true,
    'chat_enabled': true,
    'calls_enabled': true,
    'emergency_enabled': true,
    'documents_enabled': true,
    'system_enabled': true,
    'priority_filter_enabled': false,
    'sound_enabled': true,
    'haptic_enabled': true,
    'emergency_banners_enabled': true,
  };

  /// Initialize with user type (customer, provider, vendor)
  Future<void> initialize(String userType) async {
    _userType = userType;
    debugPrint(
        '🔧 NotificationSettingsService initialized for user type: $userType');
  }

  /// Get the current prefix for settings keys
  String get _prefix {
    switch (_userType) {
      case 'customer':
        return _customerPrefix;
      case 'provider':
        return _providerPrefix;
      case 'vendor':
        return _vendorPrefix;
      default:
        return _customerPrefix; // Fallback
    }
  }

  /// Get a specific setting value
  Future<bool> getSetting(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fullKey = '$_prefix$key';
      return prefs.getBool(fullKey) ?? _defaultSettings[key] ?? true;
    } catch (e) {
      debugPrint('❌ Error getting setting $key: $e');
      return _defaultSettings[key] ?? true;
    }
  }

  /// Set a specific setting value
  Future<void> setSetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fullKey = '$_prefix$key';
      await prefs.setBool(fullKey, value);
      debugPrint('✅ Saved setting $fullKey: $value');
    } catch (e) {
      debugPrint('❌ Error saving setting $key: $e');
    }
  }

  /// Get all settings for current user type
  Future<Map<String, bool>> getAllSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settings = <String, bool>{};

      for (final key in _defaultSettings.keys) {
        final fullKey = '$_prefix$key';
        settings[key] = prefs.getBool(fullKey) ?? _defaultSettings[key] ?? true;
      }

      return settings;
    } catch (e) {
      debugPrint('❌ Error getting all settings: $e');
      return _defaultSettings;
    }
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      for (final key in _defaultSettings.keys) {
        final fullKey = '$_prefix$key';
        await prefs.setBool(fullKey, _defaultSettings[key]!);
      }

      debugPrint('🔄 Reset all settings to defaults for user type: $_userType');
    } catch (e) {
      debugPrint('❌ Error resetting settings: $e');
    }
  }

  /// Get current user type
  String get userType => _userType ?? 'customer';

  /// Check if emergency banners are enabled
  Future<bool> get emergencyBannersEnabled async {
    return await getSetting('emergency_banners_enabled');
  }

  /// Set emergency banners enabled/disabled
  Future<void> setEmergencyBannersEnabled(bool value) async {
    await setSetting('emergency_banners_enabled', value);
  }

  /// Get priority filter enabled status
  Future<bool> get priorityFilterEnabled async {
    return await getSetting('priority_filter_enabled');
  }

  /// Set priority filter enabled/disabled
  Future<void> setPriorityFilterEnabled(bool value) async {
    await setSetting('priority_filter_enabled', value);
  }

  /// Get sound enabled status
  Future<bool> get soundEnabled async {
    return await getSetting('sound_enabled');
  }

  /// Set sound enabled/disabled
  Future<void> setSoundEnabled(bool value) async {
    await setSetting('sound_enabled', value);
  }

  /// Get haptic enabled status
  Future<bool> get hapticEnabled async {
    return await getSetting('haptic_enabled');
  }

  /// Set haptic enabled/disabled
  Future<void> setHapticEnabled(bool value) async {
    await setSetting('haptic_enabled', value);
  }

  /// Get enabled status for a specific category
  Future<bool> getCategoryEnabled(String category) async {
    return await getSetting('${category}_enabled');
  }

  /// Set enabled status for a specific category
  Future<void> setCategoryEnabled(String category, bool value) async {
    await setSetting('${category}_enabled', value);
  }

  /// Get all enabled categories
  Future<List<String>> getEnabledCategories() async {
    final allSettings = await getAllSettings();
    final enabledCategories = <String>[];

    final categories = [
      'jobs',
      'payments',
      'reviews',
      'alerts',
      'verification',
      'ads',
      'chat',
      'calls',
      'emergency',
      'documents',
      'system'
    ];

    for (final category in categories) {
      if (allSettings['${category}_enabled'] == true) {
        enabledCategories.add(category);
      }
    }

    return enabledCategories;
  }
}
