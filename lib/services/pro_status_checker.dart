import 'package:supabase_flutter/supabase_flutter.dart';

class ProStatusChecker {
  /// Check if current user is PRO by reading from Supabase
  static Future<bool> isProUser() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      final profile = await supabase
          .from('profiles')
          .select('id, role')
          .eq('user_id', user.id)
          .single();

      final profileId = profile['id'].toString();
      final role = profile['role'].toString();

      String table = 'customers';
      if (role == 'provider') table = 'providers';
      if (role == 'vendor') table = 'vendors';

      final record = await supabase
          .from(table)
          .select('is_pro, pro_expiry_date')
          .eq('profile_id', profileId)
          .single();

      final isPro = record['is_pro'] == true;
      final expiryStr = record['pro_expiry_date']?.toString();

      if (!isPro) return false;
      if (expiryStr == null) return false;

      // Check if subscription is still valid
      final expiry = DateTime.parse(expiryStr);
      if (DateTime.now().isAfter(expiry)) {
        // Subscription expired - update database
        await supabase
            .from(table)
            .update({'is_pro': false})
            .eq('profile_id', profileId);
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get subscription expiry date from Supabase
  static Future<DateTime?> getProExpiryDate() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      final profile = await supabase
          .from('profiles')
          .select('id, role')
          .eq('user_id', user.id)
          .single();

      final profileId = profile['id'].toString();
      final role = profile['role'].toString();

      String table = 'customers';
      if (role == 'provider') table = 'providers';
      if (role == 'vendor') table = 'vendors';

      final record = await supabase
          .from(table)
          .select('is_pro, pro_expiry_date')
          .eq('profile_id', profileId)
          .single();

      final expiryStr = record['pro_expiry_date']?.toString();
      if (expiryStr == null) return null;
      return DateTime.parse(expiryStr);
    } catch (e) {
      return null;
    }
  }

  /// Check if user has active subscription (blocks new purchase)
  static Future<bool> hasActiveSubscription() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      final profile = await supabase
          .from('profiles')
          .select('id, role')
          .eq('user_id', user.id)
          .single();

      final profileId = profile['id'].toString();
      final role = profile['role'].toString();

      String table = 'customers';
      if (role == 'provider') table = 'providers';
      if (role == 'vendor') table = 'vendors';

      final record = await supabase
          .from(table)
          .select('is_pro, pro_expiry_date')
          .eq('profile_id', profileId)
          .single();

      final isPro = record['is_pro'] == true;
      final expiryStr = record['pro_expiry_date']?.toString();
      if (!isPro || expiryStr == null) return false;

      final expiry = DateTime.parse(expiryStr);
      return DateTime.now().isBefore(expiry);
    } catch (e) {
      return false;
    }
  }

  // Keep these for backward compatibility
  static Future<bool> isUpgradeInProgress() async => false;
  static Future<Map<String, dynamic>?> getSubscriptionData() async => null;
  static Future<bool> saveSubscriptionData(Map<String, dynamic> data) async => true;
  static Future<bool> markSubscriptionCompleted({
    required String subscriptionType,
    required String startDate,
    required String endDate,
  }) async => true;
  static Future<bool> markUpgradeStarted() async => true;
  static Future<bool> clearSubscriptionData() async => true;
  static Future<String?> getSubscriptionType() async => null;
  static Future<String?> getSubscriptionEndDate() async => null;
  static Future<bool> isSubscriptionExpired() async => true;
}
