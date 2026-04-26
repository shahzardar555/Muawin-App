/// Abstract interface for vendor data operations
/// Enables easy switching between mock and backend implementations
abstract class VendorService {
  /// Get all vendor data
  Future<Map<String, dynamic>> getVendorData();

  /// Get specific vendor field
  Future<String?> getVendorField(String field);

  /// Update specific vendor field
  Future<bool> updateVendorField(String field, String value);

  /// Update multiple vendor fields at once
  Future<bool> updateVendorFields(Map<String, String> updates);

  /// Update profile picture URL
  Future<bool> updateProfilePicture(String? imageUrl);

  /// Update vendor rating
  Future<bool> updateRating(String rating);

  /// Update review count
  Future<bool> updateReviewCount(int count);

  /// Reset vendor data to defaults
  Future<bool> resetToDefaults();

  /// Clear all vendor data
  Future<bool> clearAllData();

  /// Check if vendor data exists
  Future<bool> hasVendorData();

  /// Get vendor ID
  String get vendorId;

  /// Convenience getters for common fields
  Future<String> getVendorName();
  Future<String> getVendorCategory();
  Future<String> getVendorPhone();
  Future<String> getVendorAddress();
  Future<String> getVendorMapsLink();
  Future<String> getVendorAbout();
  Future<String?> getVendorProfileImageUrl();
  Future<String> getVendorRating();
  Future<int> getVendorReviewCount();
}
