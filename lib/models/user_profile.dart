/// User profile model for service providers
/// Replaces Map<String, dynamic> usage with type-safe model

library user_profile;

class UserProfile {
  final String providerName;
  final String email;
  final String phoneNumber;
  final String? profileImagePath;
  final bool isCNICVerified;
  final double rating;
  final int reviewCount;
  final String verificationStatus;
  final String cnicNumber;
  final String cnicExpiry;

  const UserProfile({
    required this.providerName,
    required this.email,
    required this.phoneNumber,
    this.profileImagePath,
    required this.isCNICVerified,
    required this.rating,
    required this.reviewCount,
    required this.verificationStatus,
    required this.cnicNumber,
    required this.cnicExpiry,
  });

  /// Default constructor with sensible defaults
  factory UserProfile.defaultValues() {
    return const UserProfile(
      providerName: 'Ahmad M.',
      email: 'provider@example.com',
      phoneNumber: '+923001234567',
      profileImagePath: null,
      isCNICVerified: true,
      rating: 4.9,
      reviewCount: 124,
      verificationStatus: 'Verified',
      cnicNumber: '35202-1234567-1',
      cnicExpiry: '2028-12-31',
    );
  }

  /// Create from JSON (for SharedPreferences)
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      providerName: json['provider_name'] ?? 'Ahmad M.',
      email: json['email'] ?? 'provider@example.com',
      phoneNumber: json['contact_phone'] ?? '+923001234567',
      profileImagePath: json['profile_image_path'],
      isCNICVerified: json['is_cnic_verified'] ?? true,
      rating: (json['rating'] ?? 4.9).toDouble(),
      reviewCount: json['review_count'] ?? 124,
      verificationStatus: json['verification_status'] ?? 'Verified',
      cnicNumber: json['cnic_number'] ?? '35202-1234567-1',
      cnicExpiry: json['cnic_expiry'] ?? '2028-12-31',
    );
  }

  /// Convert to JSON (for SharedPreferences)
  Map<String, dynamic> toJson() {
    return {
      'provider_name': providerName,
      'email': email,
      'contact_phone': phoneNumber,
      'profile_image_path': profileImagePath,
      'is_cnic_verified': isCNICVerified,
      'rating': rating,
      'review_count': reviewCount,
      'verification_status': verificationStatus,
      'cnic_number': cnicNumber,
      'cnic_expiry': cnicExpiry,
    };
  }

  /// Create a copy with updated values
  UserProfile copyWith({
    String? providerName,
    String? email,
    String? phoneNumber,
    String? profileImagePath,
    bool? isCNICVerified,
    double? rating,
    int? reviewCount,
    String? verificationStatus,
    String? cnicNumber,
    String? cnicExpiry,
  }) {
    return UserProfile(
      providerName: providerName ?? this.providerName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      isCNICVerified: isCNICVerified ?? this.isCNICVerified,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      cnicNumber: cnicNumber ?? this.cnicNumber,
      cnicExpiry: cnicExpiry ?? this.cnicExpiry,
    );
  }

  /// Check if profile is complete
  bool get isProfileComplete {
    return providerName.isNotEmpty &&
        email.isNotEmpty &&
        phoneNumber.isNotEmpty &&
        isCNICVerified;
  }

  /// Get verification status color (for UI)
  String get verificationStatusColor {
    if (isCNICVerified) return 'green';
    if (verificationStatus == 'Pending') return 'orange';
    return 'red';
  }

  /// Get formatted rating string
  String get formattedRating => rating.toStringAsFixed(1);

  /// Get formatted review count string
  String get formattedReviewCount => '($reviewCount reviews)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.providerName == providerName &&
        other.email == email &&
        other.phoneNumber == phoneNumber &&
        other.profileImagePath == profileImagePath &&
        other.isCNICVerified == isCNICVerified &&
        other.rating == rating &&
        other.reviewCount == reviewCount &&
        other.verificationStatus == verificationStatus &&
        other.cnicNumber == cnicNumber &&
        other.cnicExpiry == cnicExpiry;
  }

  @override
  int get hashCode {
    return providerName.hashCode ^
        email.hashCode ^
        phoneNumber.hashCode ^
        profileImagePath.hashCode ^
        isCNICVerified.hashCode ^
        rating.hashCode ^
        reviewCount.hashCode ^
        verificationStatus.hashCode ^
        cnicNumber.hashCode ^
        cnicExpiry.hashCode;
  }

  @override
  String toString() {
    return 'UserProfile(providerName: $providerName, email: $email, isCNICVerified: $isCNICVerified)';
  }
}
