import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Sign up a new user
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String role,
    String? serviceCategory,
    String? businessName,
    String? businessType,
  }) async {
    try {
      // Sanitize email
      String cleanEmail = email
          .trim()
          .toLowerCase()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll(' ', '');

      // Validate email
      if (!cleanEmail.contains('@') || !cleanEmail.contains('.')) {
        throw Exception('Please enter a valid email address');
      }

      final response = await _supabase.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {
          'full_name': fullName,
          'phone_number': phoneNumber,
          'role': role,
          if (serviceCategory != null) 'service_category': serviceCategory,
          if (businessName != null) 'business_name': businessName,
          if (businessType != null) 'business_type': businessType,
        },
      );
      return response;
    } catch (error) {
      debugPrint('Registration error: ${error.toString()}');
      if (error is AuthException) {
        debugPrint('Registration error message: ${error.message}');
        debugPrint('Registration error code: ${error.statusCode}');
      }
      throw Exception('Sign up failed: ${error.toString()}');
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (error) {
      debugPrint('Login error: ${error.toString()}');
      if (error is AuthException) {
        debugPrint('Login error message: ${error.message}');
        debugPrint('Login error code: ${error.statusCode}');
      }
      throw Exception('Sign in failed: ${error.toString()}');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  /// Get current user
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  /// Get current session
  Session? getCurrentSession() {
    return _supabase.auth.currentSession;
  }

  /// Reset password for email
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }

  /// Check if user is logged in
  bool isLoggedIn() {
    return _supabase.auth.currentSession != null;
  }

  /// Get user role from metadata
  String? getUserRole() {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return user.userMetadata?['role'] as String?;
  }

  /// Get user role from both metadata and profiles table
  Future<String?> getUserRoleWithFallback() async {
    // Method 1: Try to get from auth metadata (faster)
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    String? role = user.userMetadata?['role'] as String?;

    // Method 2: If metadata empty, query profiles table
    if (role == null || role.isEmpty) {
      try {
        final profile = await _supabase
            .from('profiles')
            .select('role')
            .eq('user_id', user.id)
            .maybeSingle();
        role = profile?['role'] as String?;
      } catch (e) {
        debugPrint('Error fetching role from profiles: ${e.toString()}');
      }
    }

    return role;
  }

  /// Get provider verification status
  Future<String> getProviderVerificationStatus(String userId) async {
    try {
      // Get provider verification status
      final response = await _supabase
          .from('providers')
          .select('verification_status, is_verified, profile_id')
          .eq('profile_id', await _getProfileId(userId))
          .maybeSingle();

      if (response == null) {
        return 'not_found';
      }

      // Check verification status
      final isVerified = response['is_verified'] as bool? ?? false;
      final status = response['verification_status'] as String? ?? 'pending';

      if (isVerified && status == 'approved') {
        return 'approved';
      } else if (status == 'rejected') {
        return 'rejected';
      } else {
        return 'pending';
      }
    } catch (e) {
      debugPrint('Error checking verification: $e');
      return 'pending';
    }
  }

  /// Helper method to get profile_id from user_id
  Future<String> _getProfileId(String userId) async {
    final profile = await _supabase
        .from('profiles')
        .select('id')
        .eq('user_id', userId)
        .single();
    return profile['id'] as String;
  }
}
