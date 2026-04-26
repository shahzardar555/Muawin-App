import '../services/service_locator.dart';

/// Application configuration for service management
/// Controls which service implementation is active (mock vs backend)
class AppConfig {
  static bool _useMockServices = true;

  /// Initialize services based on configuration
  static void initializeServices() {
    if (_useMockServices) {
      ServiceLocator().initializeMockService();
    } else {
      // Uncomment when backend is ready:
      // ServiceLocator().initializeBackendService(
      //   baseUrl: 'https://your-api.com',
      //   apiKey: 'your-api-key',
      // );
    }
  }

  /// Switch to mock services (for development/testing)
  static void useMockServices() {
    _useMockServices = true;
    initializeServices();
  }

  /// Switch to backend services (for production)
  /// Uncomment and implement when backend is ready:
  /*
  static void useBackendServices({
    required String baseUrl,
    required String apiKey,
  }) {
    _useMockServices = false;
    ServiceLocator().initializeBackendService(
      baseUrl: baseUrl,
      apiKey: apiKey,
    );
  }
  */

  /// Check if currently using mock services
  static bool get isUsingMockServices => _useMockServices;

  /// Get current service type
  static String get currentServiceType {
    return _useMockServices ? 'Mock (SharedPreferences)' : 'Backend (API)';
  }
}
