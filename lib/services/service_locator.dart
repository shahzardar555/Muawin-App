import 'vendor_service.dart';
import 'vendor_data_service.dart';

/// Service locator for dependency injection
/// Enables easy switching between mock and backend implementations
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  VendorService _vendorService = MockVendorService();

  /// Get the current vendor service implementation
  VendorService get vendorService => _vendorService;

  /// Initialize with mock service (default)
  void initializeMockService() {
    _vendorService = MockVendorService();
  }

  /// Switch to backend service (for production)
  /// Uncomment when backend is ready:
  /*
  void initializeBackendService({
    required String baseUrl,
    required String apiKey,
  }) {
    _vendorService = BackendVendorService(
      baseUrl: baseUrl,
      apiKey: apiKey,
    );
  }
  */

  /// Switch between services programmatically
  void setVendorService(VendorService service) {
    _vendorService = service;
  }

  /// Check if using mock service
  bool get isUsingMockService => _vendorService is MockVendorService;

  /// Check if using backend service
  bool get isUsingBackendService => _vendorService is! MockVendorService;
}

/// Global access to service locator
final serviceLocator = ServiceLocator();

/// Convenience getter for vendor service
VendorService get vendorService => serviceLocator.vendorService;
