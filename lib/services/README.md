# Vendor Services Architecture

## Overview
This directory contains the service layer architecture for vendor data management, enabling seamless switching between mock (SharedPreferences) and backend (API) implementations.

## Architecture Components

### 1. Abstract Interface (`vendor_service.dart`)
- `VendorService` abstract class defining all vendor operations
- Future-based async methods for all CRUD operations
- Type-safe interface with proper error handling

### 2. Mock Implementation (`vendor_data_service.dart`)
- `MockVendorService` implements `VendorService` using SharedPreferences
- `VendorDataService` legacy static wrapper for backward compatibility
- All current functionality preserved

### 3. Backend Template (`backend_vendor_service.dart`)
- `BackendVendorService` commented implementation for API integration
- HTTP client with proper error handling and timeouts
- Ready for production when backend is available

### 4. Service Locator (`service_locator.dart`)
- Dependency injection pattern for service management
- Easy switching between implementations
- Global access point with singleton pattern

### 5. App Configuration (`../config/app_config.dart`)
- Centralized configuration for service selection
- One-line switching between mock and backend
- Production-ready setup

## Usage Examples

### Current Usage (Mock Service)
```dart
// Automatic - uses mock service by default
final data = await vendorService.getVendorData();
await vendorService.updateVendorField('name', 'New Name');
```

### Backend Migration (When Ready)
```dart
// 1. Uncomment BackendVendorService implementation
// 2. Update AppConfig.useBackendServices()
// 3. Done! No other changes needed

AppConfig.useBackendServices(
  baseUrl: 'https://your-api.com',
  apiKey: 'your-api-key',
);
```

## Migration Process

### Step 1: Backend Development
1. Implement API endpoints matching the interface
2. Uncomment `BackendVendorService` implementation
3. Update API URLs and authentication

### Step 2: Switch to Backend
```dart
// In main.dart or app initialization:
AppConfig.initializeServices(); // Uses mock by default

// When ready for production:
AppConfig.useBackendServices(
  baseUrl: 'https://your-api.com',
  apiKey: 'your-api-key',
);
```

### Step 3: Testing
- All existing tests continue to work
- New backend tests can be written
- Easy switching for A/B testing

## Benefits

✅ **Zero Breaking Changes**: Existing code continues to work
✅ **Easy Migration**: One-line backend switch
✅ **Clean Architecture**: Proper separation of concerns
✅ **Testable**: Easy to mock and test
✅ **Maintainable**: Centralized service management
✅ **Scalable**: Ready for production deployment

## File Structure
```
lib/services/
├── vendor_service.dart          # Abstract interface
├── vendor_data_service.dart     # Mock implementation
├── backend_vendor_service.dart  # Backend template (commented)
├── service_locator.dart         # Dependency injection
└── README.md                    # This documentation

lib/config/
└── app_config.dart              # Service configuration
```

## Future Enhancements
- Caching layer for offline support
- Real-time updates with WebSocket
- Multiple vendor support
- Advanced error handling and retry logic
