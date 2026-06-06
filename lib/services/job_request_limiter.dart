import 'package:shared_preferences/shared_preferences.dart';
import 'pro_status_checker.dart';

/// Service to manage job request limits
/// Basic users: 2 job requests per day, 10 direct requests per day
/// PRO users: Unlimited job requests and direct requests
class JobRequestLimiter {
  static const String _jobRequestsKey = 'job_requests';
  static const String _lastResetDateKey = 'job_requests_last_reset_date';
  static const int _basicUserDailyLimit = 2;

  // Direct request tracking (separate counter from posted jobs)
  static const String _directRequestsKey = 'direct_job_requests';
  static const String _directLastResetDateKey =
      'direct_requests_last_reset_date';
  static const int _basicUserDirectRequestDailyLimit = 10;

  /// Check if user can post a new job
  /// Returns true if PRO user or if basic user hasn't exceeded daily limit
  static Future<bool> canPostJob() async {
    try {
      final isPro = await ProStatusChecker.isProUser();

      // PRO users have unlimited job requests
      if (isPro) {
        return true;
      }

      // Basic users: check daily limit
      final todayCount = await _getTodayCount(_jobRequestsKey);
      return todayCount < _basicUserDailyLimit;
    } catch (e) {
      // On error, allow posting (safe default)
      return true;
    }
  }

  /// Get the number of job requests posted today
  static Future<int> getTodayJobCount() async {
    try {
      return await _getTodayCount(_jobRequestsKey);
    } catch (e) {
      return 0;
    }
  }

  /// Check if user can send a new direct request
  /// Returns true if PRO user or if basic user hasn't exceeded daily limit
  static Future<bool> canSendDirectRequest() async {
    try {
      final isPro = await ProStatusChecker.isProUser();

      // PRO users have unlimited direct requests
      if (isPro) {
        return true;
      }

      // Basic users: check daily direct request limit
      final todayCount = await _getTodayCount(_directRequestsKey);
      return todayCount < _basicUserDirectRequestDailyLimit;
    } catch (e) {
      // On error, allow sending (safe default)
      return true;
    }
  }

  /// Get the number of direct requests sent today
  static Future<int> getTodayDirectRequestCount() async {
    try {
      return await _getTodayCount(_directRequestsKey);
    } catch (e) {
      return 0;
    }
  }

  /// Get remaining direct requests for today
  /// Returns -1 for PRO users (unlimited)
  static Future<int> getRemainingDirectRequests() async {
    try {
      final isPro = await ProStatusChecker.isProUser();

      // PRO users have unlimited
      if (isPro) {
        return -1;
      }

      final todayCount = await _getTodayCount(_directRequestsKey);
      return _basicUserDirectRequestDailyLimit - todayCount;
    } catch (e) {
      return _basicUserDirectRequestDailyLimit; // On error, assume full limit available
    }
  }

  /// Increment direct request count for today
  /// Called when a user successfully sends a direct request
  static Future<bool> incrementDirectRequestCount() async {
    try {
      final isPro = await ProStatusChecker.isProUser();

      // PRO users don't need to track counts
      if (isPro) {
        return true;
      }

      final prefs = await SharedPreferences.getInstance();
      await _resetIfNeeded(prefs, _directRequestsKey, _directLastResetDateKey);

      final currentCount = prefs.getInt(_directRequestsKey) ?? 0;
      await prefs.setInt(_directRequestsKey, currentCount + 1);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get the daily direct request limit for the current user
  /// Returns -1 for PRO users (unlimited)
  static Future<int> getDirectRequestDailyLimit() async {
    final isPro = await ProStatusChecker.isProUser();
    return isPro ? -1 : _basicUserDirectRequestDailyLimit;
  }

  /// Clear direct request data (for testing)
  static Future<bool> clearDirectRequestData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_directRequestsKey);
      await prefs.remove(_directLastResetDateKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get remaining job requests for today
  /// Returns -1 for PRO users (unlimited)
  static Future<int> getRemainingJobRequests() async {
    try {
      final isPro = await ProStatusChecker.isProUser();

      // PRO users have unlimited
      if (isPro) {
        return -1;
      }

      final todayCount = await _getTodayCount(_jobRequestsKey);
      return _basicUserDailyLimit - todayCount;
    } catch (e) {
      return _basicUserDailyLimit; // On error, assume full limit available
    }
  }

  /// Increment job request count for today
  /// Called when a user successfully posts a job
  static Future<bool> incrementJobCount() async {
    try {
      final isPro = await ProStatusChecker.isProUser();

      // PRO users don't need to track counts
      if (isPro) {
        return true;
      }

      final prefs = await SharedPreferences.getInstance();
      await _resetIfNeeded(prefs, _jobRequestsKey, _lastResetDateKey);

      final currentCount = prefs.getInt(_jobRequestsKey) ?? 0;
      await prefs.setInt(_jobRequestsKey, currentCount + 1);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get the daily limit for the current user
  /// Returns -1 for PRO users (unlimited)
  static Future<int> getDailyLimit() async {
    final isPro = await ProStatusChecker.isProUser();
    return isPro ? -1 : _basicUserDailyLimit;
  }

  /// Get today's count for a given key (internal helper)
  static Future<int> _getTodayCount(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Use the matching reset key for this counter
      final resetKey = key == _directRequestsKey
          ? _directLastResetDateKey
          : _lastResetDateKey;
      await _resetIfNeeded(prefs, key, resetKey);
      return prefs.getInt(key) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Reset counter if it's a new day (internal helper)
  static Future<void> _resetIfNeeded(
    SharedPreferences prefs,
    String countKey,
    String resetKey,
  ) async {
    try {
      final lastResetDateStr = prefs.getString(resetKey);
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month}-${today.day}';

      if (lastResetDateStr != todayStr) {
        // New day, reset counter
        await prefs.setInt(countKey, 0);
        await prefs.setString(resetKey, todayStr);
      }
    } catch (e) {
      // On error, reset to be safe
      await prefs.setInt(countKey, 0);
    }
  }

  /// Clear job request data (for testing)
  static Future<bool> clearJobRequestData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_jobRequestsKey);
      await prefs.remove(_lastResetDateKey);
      return true;
    } catch (e) {
      return false;
    }
  }
}
