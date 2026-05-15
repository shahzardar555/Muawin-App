import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get user profile with related data
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('*, customers(*), providers(*), vendors(*)')
          .eq('user_id', userId)
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to fetch profile: ${e.toString()}');
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>?> updateProfile({
    required String userId,
    String? fullName,
    String? phoneNumber,
    String? city,
    String? area,
    String? address,
  }) async {
    try {
      final data = {
        if (fullName != null) 'full_name': fullName,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (city != null) 'city': city,
        if (area != null) 'area': area,
        if (address != null) 'address': address,
      };

      final response = await _supabase
          .from('profiles')
          .update(data)
          .eq('user_id', userId)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  /// Get provider profile with pricing packages
  Future<Map<String, dynamic>?> getProviderProfile(String profileId) async {
    try {
      final response = await _supabase
          .from('providers')
          .select('*, service_pricing_packages(*)')
          .eq('profile_id', profileId)
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to fetch provider profile: ${e.toString()}');
    }
  }

  /// Get vendor profile
  Future<Map<String, dynamic>?> getVendorProfile(String profileId) async {
    try {
      final response = await _supabase
          .from('vendors')
          .select('*')
          .eq('profile_id', profileId)
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to fetch vendor profile: ${e.toString()}');
    }
  }
}
