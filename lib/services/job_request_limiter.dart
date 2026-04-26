import 'package:shared_preferences/shared_preferences.dart';
import 'pro_status_checker.dart';

/// Service to manage job request limits
/// Basic users: 2 job requests per day
/// PRO users: Unlimited job requests
class JobRequestLimiter {
  static const String _jobRequestsKey = 'job_requests';
  static const String _lastResetDateKey = 'job_requests_last_reset_date';
  static const int _basicUserDailyLimit = 2;

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
      final todayCount = await _getTodayJobCount();
      return todayCount < _basicUserDailyLimit;
    } catch (e) {
      // On error, allow posting (safe default)
      return true;
    }
  }

  /// Get the number of job requests posted today
  static Future<int> getTodayJobCount() async {
    return await _getTodayJobCount();
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

      final todayCount = await _getTodayJobCount();
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
      await _resetIfNeeded(prefs);

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

  /// Get today's job count (internal helper)
  static Future<int> _getTodayJobCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _resetIfNeeded(prefs);
      return prefs.getInt(_jobRequestsKey) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Reset counter if it's a new day (internal helper)
  static Future<void> _resetIfNeeded(SharedPreferences prefs) async {
    try {
      final lastResetDateStr = prefs.getString(_lastResetDateKey);
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month}-${today.day}';

      if (lastResetDateStr != todayStr) {
        // New day, reset counter
        await prefs.setInt(_jobRequestsKey, 0);
        await prefs.setString(_lastResetDateKey, todayStr);
      }
    } catch (e) {
      // On error, reset to be safe
      await prefs.setInt(_jobRequestsKey, 0);
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
