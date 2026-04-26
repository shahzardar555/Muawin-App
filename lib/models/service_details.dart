/// Service details model for service providers
/// Replaces Map<String, dynamic> usage with type-safe model

library service_details;

class ServiceDetails {
  final String serviceType;
  final String hourlyRate;
  final String standardDescription;
  final String standardDuration;
  final String premiumPrice;
  final String premiumDescription;
  final String premiumDuration;
  final String workingHours;
  final String responseTime;
  final List<String> serviceAreas;
  final String availability;
  final String experience;
  final String description;

  const ServiceDetails({
    required this.serviceType,
    required this.hourlyRate,
    required this.standardDescription,
    required this.standardDuration,
    required this.premiumPrice,
    required this.premiumDescription,
    required this.premiumDuration,
    required this.workingHours,
    required this.responseTime,
    required this.serviceAreas,
    required this.availability,
    required this.experience,
    required this.description,
  });

  /// Default constructor with sensible defaults
  factory ServiceDetails.defaultValues() {
    return const ServiceDetails(
      serviceType: 'Driver',
      hourlyRate: '500',
      standardDescription: 'Professional driver with extensive experience',
      standardDuration: '45 mins',
      premiumPrice: '750',
      premiumDescription: 'Premium service with additional benefits',
      premiumDuration: '1 hour',
      workingHours: '9:00 AM - 6:00 PM',
      responseTime: '2',
      serviceAreas: ['Lahore'],
      availability: 'Full-time',
      experience: '3 years',
      description:
          'Professional driver with extensive experience in safe and efficient transportation services.',
    );
  }

  /// Create from JSON (for SharedPreferences)
  factory ServiceDetails.fromJson(Map<String, dynamic> json) {
    return ServiceDetails(
      serviceType: json['service_type'] ?? 'Driver',
      hourlyRate: json['hourly_rate'] ?? '500',
      standardDescription: json['standard_description'] ?? '',
      standardDuration: json['standard_duration'] ?? '45 mins',
      premiumPrice: json['premium_price'] ?? '750',
      premiumDescription: json['premium_description'] ?? '',
      premiumDuration: json['premium_duration'] ?? '1 hour',
      workingHours: json['working_hours'] ?? '9:00 AM - 6:00 PM',
      responseTime: json['response_time'] ?? '2',
      serviceAreas: List<String>.from(json['service_areas'] ?? ['Lahore']),
      availability: json['availability'] ?? 'Full-time',
      experience: json['experience'] ?? '3 years',
      description: json['description'] ?? '',
    );
  }

  /// Convert to JSON (for SharedPreferences)
  Map<String, dynamic> toJson() {
    return {
      'service_type': serviceType,
      'hourly_rate': hourlyRate,
      'standard_description': standardDescription,
      'standard_duration': standardDuration,
      'premium_price': premiumPrice,
      'premium_description': premiumDescription,
      'premium_duration': premiumDuration,
      'working_hours': workingHours,
      'response_time': responseTime,
      'service_areas': serviceAreas,
      'availability': availability,
      'experience': experience,
      'description': description,
    };
  }

  /// Create a copy with updated values
  ServiceDetails copyWith({
    String? serviceType,
    String? hourlyRate,
    String? standardDescription,
    String? standardDuration,
    String? premiumPrice,
    String? premiumDescription,
    String? premiumDuration,
    String? workingHours,
    String? responseTime,
    List<String>? serviceAreas,
    String? availability,
    String? experience,
    String? description,
  }) {
    return ServiceDetails(
      serviceType: serviceType ?? this.serviceType,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      standardDescription: standardDescription ?? this.standardDescription,
      standardDuration: standardDuration ?? this.standardDuration,
      premiumPrice: premiumPrice ?? this.premiumPrice,
      premiumDescription: premiumDescription ?? this.premiumDescription,
      premiumDuration: premiumDuration ?? this.premiumDuration,
      workingHours: workingHours ?? this.workingHours,
      responseTime: responseTime ?? this.responseTime,
      serviceAreas: serviceAreas ?? this.serviceAreas,
      availability: availability ?? this.availability,
      experience: experience ?? this.experience,
      description: description ?? this.description,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceDetails &&
        other.serviceType == serviceType &&
        other.hourlyRate == hourlyRate &&
        other.standardDescription == standardDescription &&
        other.standardDuration == standardDuration &&
        other.premiumPrice == premiumPrice &&
        other.premiumDescription == premiumDescription &&
        other.premiumDuration == premiumDuration &&
        other.workingHours == workingHours &&
        other.responseTime == responseTime &&
        other.availability == availability &&
        other.experience == experience &&
        other.description == description;
  }

  @override
  int get hashCode {
    return serviceType.hashCode ^
        hourlyRate.hashCode ^
        standardDescription.hashCode ^
        standardDuration.hashCode ^
        premiumPrice.hashCode ^
        premiumDescription.hashCode ^
        premiumDuration.hashCode ^
        workingHours.hashCode ^
        responseTime.hashCode ^
        availability.hashCode ^
        experience.hashCode ^
        description.hashCode;
  }

  @override
  String toString() {
    return 'ServiceDetails(serviceType: $serviceType, hourlyRate: $hourlyRate, availability: $availability)';
  }
}
