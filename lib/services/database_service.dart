import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Central database service for all Supabase queries
/// Handles all database operations with proper error handling
class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ═════════════════════════════════════════
  // SECTION 1: SERVICE CATEGORIES
  // ═════════════════════════════════════════

  /// Get all active service categories (backward compatibility)
  Future<List<Map<String, dynamic>>> getServiceCategories() async {
    return getProviderCategories();
  }

  /// Get provider categories only
  Future<List<Map<String, dynamic>>> getProviderCategories() async {
    try {
      final response = await _supabase
          .from('service_categories')
          .select('id, name, name_urdu, icon, description, sort_order')
          .eq('is_active', true)
          .eq('category_type', 'provider')
          .order('sort_order');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting provider categories: $e');
      return [];
    }
  }

  /// Get vendor categories only
  Future<List<Map<String, dynamic>>> getVendorCategories() async {
    try {
      final response = await _supabase
          .from('service_categories')
          .select('id, name, name_urdu, icon, description, sort_order')
          .eq('is_active', true)
          .eq('category_type', 'vendor')
          .order('sort_order');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting vendor categories: $e');
      return [];
    }
  }

  /// Get a single category by ID
  Future<Map<String, dynamic>?> getCategoryById(String categoryId) async {
    try {
      final response = await _supabase
          .from('service_categories')
          .select('*')
          .eq('id', categoryId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error in getCategoryById: $e');
      return null;
    }
  }

  // ═════════════════════════════════════════
  // SECTION 2: PROVIDERS
  // ═════════════════════════════════════════

  /// Get providers with optional filters
  Future<List<Map<String, dynamic>>> getProviders({
    String? category,
    String? city,
    String? searchQuery,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from('providers').select("""
        id,
        profile_id,
        service_category,
        city,
        area,
        rating,
        review_count,
        is_verified,
        verification_status,
        is_pro,
        profiles!inner(
          full_name,
          profile_image_url,
          phone_number
        ),
        service_pricing_packages(
          id,
          package_type,
          package_name,
          price,
          currency,
          description,
          includes,
          duration,
          is_active,
          sort_order
        )
      """).eq('is_verified', true).eq('verification_status', 'verified');

      if (category != null) {
        query = query.eq('service_category', category);
      }

      if (city != null) {
        query = query.eq('city', city);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('service_category', '%$searchQuery%');
      }

      final response = await query
          .order('rating', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error in getProviders: $e');
      return [];
    }
  }

  /// Get full provider details by ID
  Future<Map<String, dynamic>?> getProviderById(String providerId) async {
    try {
      final response = await _supabase.from('providers').select("""
        *,
        profiles!inner(
          full_name,
          email,
          phone_number,
          profile_image_url,
          city
        )
      """).eq('id', providerId).maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error in getProviderById: $e');
      return null;
    }
  }

  /// Get provider by profile ID
  Future<Map<String, dynamic>?> getProviderByProfileId(String profileId) async {
    try {
      final response = await _supabase.from('providers').select("""
        *,
        profiles!inner(
          full_name,
          email,
          phone_number,
          profile_image_url,
          city
        ),
        service_pricing_packages(
          id,
          package_type,
          package_name,
          price,
          currency,
          description,
          includes,
          duration,
          is_active,
          sort_order
        )
      """).eq('profile_id', profileId).maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error in getProviderByProfileId: $e');
      return null;
    }
  }

  /// Get featured providers with active ads
  Future<List<Map<String, dynamic>>> getFeaturedProviders() async {
    try {
      final response = await _supabase
          .from('featured_ads')
          .select("""
        id,
        tagline,
        plan_type,
        start_date,
        end_date,
        provider_id,
        providers!inner(
          id,
          service_category,
          rating,
          city,
          area,
          profiles!inner(
            full_name,
            profile_image_url
          )
        )
      """)
          .eq('is_active', true)
          .not('provider_id', 'is', null)
          .gt('end_date', DateTime.now().toIso8601String())
          .order('plan_type', ascending: false)
          .limit(5);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error in getFeaturedProviders: $e');
      return [];
    }
  }

  // ═════════════════════════════════════════
  // SECTION 3: VENDORS
  // ═════════════════════════════════════════

  /// Get vendors with optional filters
  Future<List<Map<String, dynamic>>> getVendors({
    String? businessType,
    String? city,
    String? searchQuery,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from('vendors').select("""
        id,
        profile_id,
        business_name,
        business_type,
        city,
        area,
        rating,
        review_count,
        is_verified,
        is_pro,
        profiles!inner(
          full_name,
          profile_image_url,
          phone_number
        )
      """);

      if (businessType != null) {
        query = query.eq('business_type', businessType);
      }

      if (city != null) {
        query = query.eq('city', city);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('business_name', '%$searchQuery%');
      }

      final response = await query
          .order('rating', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error in getVendors: $e');
      return [];
    }
  }

  /// Get full vendor details by ID
  Future<Map<String, dynamic>?> getVendorById(String vendorId) async {
    try {
      final response = await _supabase.from('vendors').select("""
        *,
        profiles!inner(
          full_name,
          email,
          phone_number,
          profile_image_url,
          city
        )
      """).eq('id', vendorId).maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error in getVendorById: $e');
      return null;
    }
  }

  /// Get featured vendors with active ads
  Future<List<Map<String, dynamic>>> getFeaturedVendors() async {
    try {
      final response = await _supabase
          .from('featured_ads')
          .select("""
        id,
        tagline,
        plan_type,
        start_date,
        end_date,
        vendor_id,
        vendors!inner(
          id,
          business_name,
          business_type,
          rating,
          city,
          area,
          profiles!inner(
            full_name,
            profile_image_url
          )
        )
      """)
          .eq('is_active', true)
          .not('vendor_id', 'is', null)
          .gt('end_date', DateTime.now().toIso8601String())
          .order('plan_type', ascending: false)
          .limit(5);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error in getFeaturedVendors: $e');
      return [];
    }
  }

  // ═════════════════════════════════════════
  // SECTION 4: REVIEWS
  // ═════════════════════════════════════════

  /// Get reviews for a provider
  Future<List<Map<String, dynamic>>> getProviderReviews(
    String providerId, {
    int limit = 10,
  }) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select("""
        id,
        rating,
        review,
        created_at,
        customer_id,
        customers!inner(
          profile_id,
          profiles!inner(
            full_name,
            profile_image_url
          )
        )
      """)
          .eq('provider_id', providerId)
          .eq('is_verified', true)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error in getProviderReviews: $e');
      return [];
    }
  }

  /// Get reviews for a vendor
  Future<List<Map<String, dynamic>>> getVendorReviews(
    String vendorId, {
    int limit = 10,
  }) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select("""
        id,
        rating,
        review,
        created_at,
        customer_id,
        customers!inner(
          profile_id,
          profiles!inner(
            full_name,
            profile_image_url
          )
        )
      """)
          .eq('vendor_id', vendorId)
          .eq('is_verified', true)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error in getVendorReviews: $e');
      return [];
    }
  }

  // ═════════════════════════════════════════
  // SECTION 5: SEARCH
  // ═════════════════════════════════════════

  /// Search providers across multiple fields
  Future<List<Map<String, dynamic>>> searchProviders(String query) async {
    try {
      final response = await _supabase
          .from('providers')
          .select("""
        id,
        service_category,
        city,
        rating,
        profiles!inner(
          full_name,
          profile_image_url
        )
      """)
          .or('service_category.ilike.%$query%,city.ilike.%$query%')
          .eq('is_verified', true)
          .eq('verification_status', 'approved')
          .limit(20);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error in searchProviders: $e');
      return [];
    }
  }

  /// Search vendors across multiple fields
  Future<List<Map<String, dynamic>>> searchVendors(String query) async {
    try {
      final response = await _supabase
          .from('vendors')
          .select("""
        id,
        business_name,
        business_type,
        city,
        rating,
        profiles!inner(
          full_name,
          profile_image_url
        )
      """)
          .or('business_name.ilike.%$query%,business_type.ilike.%$query%,city.ilike.%$query%')
          .limit(20);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error in searchVendors: $e');
      return [];
    }
  }

  /// Search by Urdu category name
  Future<List<Map<String, dynamic>>> searchByUrduCategory(
      String urduName) async {
    try {
      // First find the category by Urdu name
      final category = await _supabase
          .from('service_categories')
          .select('name')
          .ilike('name_urdu', '%$urduName%')
          .maybeSingle();

      if (category == null) {
        return [];
      }

      // Then search providers by the English category name
      final englishName = category['name'] as String;
      return await getProviders(category: englishName);
    } catch (e) {
      debugPrint('Error in searchByUrduCategory: $e');
      return [];
    }
  }

  // ═════════════════════════════════════════
  // SECTION 6: FAVORITES
  // ═════════════════════════════════════════

  /// Get all favorites for a customer
  Future<List<Map<String, dynamic>>> getCustomerFavorites(
      String customerId) async {
    try {
      final response = await _supabase.from('favorites').select("""
        id,
        provider_id,
        vendor_id,
        providers(
          id,
          service_category,
          rating,
          profiles!inner(full_name, profile_image_url)
        ),
        vendors(
          id,
          business_name,
          business_type,
          rating,
          profiles!inner(full_name, profile_image_url)
        )
      """).eq('customer_id', customerId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error in getCustomerFavorites: $e');
      return [];
    }
  }

  /// Toggle provider favorite status
  Future<bool> toggleFavoriteProvider(
      String customerId, String providerId) async {
    try {
      // Check if already favorited
      final existing = await _supabase
          .from('favorites')
          .select('id')
          .eq('customer_id', customerId)
          .eq('provider_id', providerId)
          .maybeSingle();

      if (existing != null) {
        // Remove from favorites
        await _supabase
            .from('favorites')
            .delete()
            .eq('customer_id', customerId)
            .eq('provider_id', providerId);
        return false;
      } else {
        // Add to favorites
        await _supabase.from('favorites').insert({
          'customer_id': customerId,
          'provider_id': providerId,
        });
        return true;
      }
    } catch (e) {
      debugPrint('Error in toggleFavoriteProvider: $e');
      return false;
    }
  }

  /// Toggle vendor favorite status
  Future<bool> toggleFavoriteVendor(String customerId, String vendorId) async {
    try {
      // Check if already favorited
      final existing = await _supabase
          .from('favorites')
          .select('id')
          .eq('customer_id', customerId)
          .eq('vendor_id', vendorId)
          .maybeSingle();

      if (existing != null) {
        // Remove from favorites
        await _supabase
            .from('favorites')
            .delete()
            .eq('customer_id', customerId)
            .eq('vendor_id', vendorId);
        return false;
      } else {
        // Add to favorites
        await _supabase.from('favorites').insert({
          'customer_id': customerId,
          'vendor_id': vendorId,
        });
        return true;
      }
    } catch (e) {
      debugPrint('Error in toggleFavoriteVendor: $e');
      return false;
    }
  }

  /// Check if provider is favorited by customer
  Future<bool> isProviderFavorited(String customerId, String providerId) async {
    try {
      final response = await _supabase
          .from('favorites')
          .select('id')
          .eq('customer_id', customerId)
          .eq('provider_id', providerId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error in isProviderFavorited: $e');
      return false;
    }
  }

  // ═════════════════════════════════════════
  // SECTION 7: PRICING PACKAGES
  // ═════════════════════════════════════════

  /// Get pricing packages for a provider
  Future<List<Map<String, dynamic>>> getProviderPricingPackages(
      String providerId) async {
    try {
      final response = await _supabase
          .from('service_pricing_packages')
          .select('id, package_type, package_name, '
              'price, currency, description, '
              'includes, duration, is_active, '
              'sort_order')
          .eq('provider_id', providerId)
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error in getProviderPricingPackages: $e');
      return [];
    }
  }

  /// Save pricing packages for a provider
  Future<void> saveProviderPricingPackages(
      String providerId, List<Map<String, dynamic>> packages) async {
    try {
      // Delete existing packages
      await _supabase
          .from('service_pricing_packages')
          .delete()
          .eq('provider_id', providerId);

      // Insert new packages
      if (packages.isNotEmpty) {
        final packagesWithProviderId =
            packages.map((pkg) => {...pkg, 'provider_id': providerId}).toList();
        await _supabase
            .from('service_pricing_packages')
            .insert(packagesWithProviderId);
      }
    } catch (e) {
      debugPrint('Error in saveProviderPricingPackages: $e');
    }
  }
}
