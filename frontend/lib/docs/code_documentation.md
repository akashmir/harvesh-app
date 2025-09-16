# Code Documentation

## Overview
This document provides comprehensive documentation for the Flutter app codebase, including architecture, components, and implementation details.

## Table of Contents
1. [Architecture](#architecture)
2. [Project Structure](#project-structure)
3. [Core Services](#core-services)
4. [UI Components](#ui-components)
5. [State Management](#state-management)
6. [Error Handling](#error-handling)
7. [Offline Support](#offline-support)
8. [Configuration Management](#configuration-management)
9. [Testing](#testing)
10. [Deployment](#deployment)

## Architecture

### Overall Architecture
The app follows a layered architecture pattern with clear separation of concerns:

```
┌─────────────────────────────────────┐
│           Presentation Layer        │
│  (Screens, Widgets, Controllers)    │
├─────────────────────────────────────┤
│           Business Logic Layer      │
│     (Services, Providers, Utils)    │
├─────────────────────────────────────┤
│           Data Layer                │
│  (APIs, Local Storage, Firebase)    │
└─────────────────────────────────────┘
```

### Design Patterns
- **Repository Pattern**: For data access abstraction
- **Service Layer Pattern**: For business logic encapsulation
- **Provider Pattern**: For state management
- **Factory Pattern**: For object creation
- **Observer Pattern**: For reactive programming

## Project Structure

```
lib/
├── config/                 # Configuration files
│   ├── app_config.dart     # App configuration
│   └── firebase_config.dart # Firebase configuration
├── docs/                   # Documentation
│   ├── api_documentation.md
│   └── code_documentation.md
├── models/                 # Data models
├── providers/              # State management
│   └── auth_provider.dart
├── screens/                # UI screens
│   ├── auth/              # Authentication screens
│   ├── crop/              # Crop recommendation screens
│   ├── weather/           # Weather screens
│   └── profile/           # Profile screens
├── services/               # Business logic services
│   ├── error_handler.dart
│   ├── network_service.dart
│   ├── offline_service.dart
│   ├── retry_service.dart
│   └── firestore_service.dart
├── utils/                  # Utility functions
│   └── validation_utils.dart
├── widgets/                # Reusable UI components
│   ├── common/            # Common widgets
│   │   ├── app_bar_widget.dart
│   │   ├── button_widget.dart
│   │   ├── card_widget.dart
│   │   ├── form_widget.dart
│   │   ├── input_field_widget.dart
│   │   └── loading_widget.dart
│   └── custom/            # Custom widgets
└── main.dart              # App entry point
```

## Core Services

### ErrorHandler Service
**File**: `lib/services/error_handler.dart`

The ErrorHandler service provides comprehensive error management across the app.

#### Key Features
- Error categorization and severity levels
- User-friendly error messages
- Retry mechanisms
- Error logging and reporting

#### Usage Example
```dart
try {
  final result = await apiCall();
} catch (error) {
  final appError = ErrorHandler.handleHttpError(response);
  ErrorHandler.showErrorDialog(context, appError);
}
```

#### Error Types
- `network`: Network connectivity issues
- `api`: API server errors
- `validation`: Input validation errors
- `authentication`: Authentication failures
- `permission`: Permission denied errors
- `timeout`: Request timeout errors
- `serverError`: Server internal errors
- `noInternet`: No internet connection
- `configuration`: Configuration errors
- `unknown`: Unknown errors

### NetworkService Service
**File**: `lib/services/network_service.dart`

The NetworkService handles all network operations with built-in retry logic and offline support.

#### Key Features
- Automatic retry with exponential backoff
- Offline request queuing
- Connectivity monitoring
- Response caching

#### Usage Example
```dart
final response = await NetworkService.post(
  '/api/recommend',
  body: requestData,
  timeout: Duration(seconds: 30),
  saveForOfflineSync: true,
);
```

#### Methods
- `get()`: GET requests
- `post()`: POST requests
- `put()`: PUT requests
- `delete()`: DELETE requests
- `syncOfflineData()`: Sync queued offline requests

### OfflineService Service
**File**: `lib/services/offline_service.dart`

The OfflineService manages offline functionality and data caching.

#### Key Features
- Local data storage using SharedPreferences
- Offline request queuing
- Data synchronization when online
- Cache management and cleanup

#### Usage Example
```dart
// Cache data
await OfflineService.cacheCropRecommendation(data);

// Get cached data
final cachedData = await OfflineService.getCachedRecommendations();

// Sync offline data
await OfflineService.syncOfflineRequests();
```

### RetryService Service
**File**: `lib/services/retry_service.dart`

The RetryService provides configurable retry mechanisms for various operations.

#### Key Features
- Exponential backoff
- Configurable retry conditions
- Network-aware retry strategies
- Timeout handling

#### Usage Example
```dart
final result = await RetryService.retryNetworkOperation(
  () => apiCall(),
  maxRetries: 3,
  operationName: 'crop_recommendation',
);
```

## UI Components

### Common Widgets
**Directory**: `lib/widgets/common/`

Reusable UI components that eliminate code duplication across screens.

#### AppBarWidget
**File**: `lib/widgets/common/app_bar_widget.dart`

Standardized app bar with consistent styling and behavior.

```dart
CommonAppBar(
  title: 'Crop Recommendation',
  actions: [IconButton(icon: Icons.help, onPressed: () {})],
)
```

#### InputFieldWidget
**File**: `lib/widgets/common/input_field_widget.dart`

Comprehensive input field with validation and styling.

```dart
CommonInputField(
  controller: controller,
  label: 'Email Address',
  icon: Icons.email,
  validator: ValidationUtils.validateEmail,
)
```

#### ButtonWidget
**File**: `lib/widgets/common/button_widget.dart`

Standardized buttons with loading states and multiple styles.

```dart
CommonButton(
  text: 'Submit',
  onPressed: () {},
  type: ButtonType.primary,
  isLoading: false,
)
```

#### CardWidget
**File**: `lib/widgets/common/card_widget.dart`

Consistent card layouts for different content types.

```dart
InfoCard(
  icon: Icons.info,
  title: 'Information',
  message: 'This is an info message',
)
```

### Form Widgets
**File**: `lib/widgets/common/form_widget.dart`

Pre-built forms for common use cases.

#### CropRecommendationForm
```dart
CropRecommendationForm(
  formKey: formKey,
  controllers: controllers,
  onSubmit: () {},
  isLoading: false,
)
```

#### LoginForm
```dart
LoginForm(
  formKey: formKey,
  emailController: emailController,
  passwordController: passwordController,
  onSubmit: () {},
)
```

## State Management

### Provider Pattern
The app uses the Provider pattern for state management with the following providers:

#### AuthProvider
**File**: `lib/providers/auth_provider.dart`

Manages authentication state and user data.

```dart
class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  
  Future<void> signIn(String email, String password) async {
    // Implementation
  }
  
  Future<void> signOut() async {
    // Implementation
  }
}
```

#### Usage in Widgets
```dart
Consumer<AuthProvider>(
  builder: (context, authProvider, child) {
    if (authProvider.isLoading) {
      return CircularProgressIndicator();
    }
    
    if (authProvider.isAuthenticated) {
      return HomeScreen();
    }
    
    return LoginScreen();
  },
)
```

## Error Handling

### Error Hierarchy
```
AppError
├── ErrorType (enum)
├── ErrorSeverity (enum)
├── message (String)
├── userFriendlyMessage (String)
├── code (String?)
├── details (Map<String, dynamic>?)
├── isRetryable (bool)
└── retryCount (int?)
```

### Error Display
- **Dialogs**: For critical errors requiring user action
- **Snackbars**: For non-critical errors and notifications
- **Inline**: For form validation errors

### Error Recovery
- **Automatic Retry**: For network and temporary errors
- **Manual Retry**: For user-initiated retry actions
- **Fallback**: For offline functionality

## Offline Support

### Offline Capabilities
- **Data Caching**: Store API responses locally
- **Request Queuing**: Queue failed requests for later sync
- **Offline Indicators**: Show offline status to users
- **Cached Data Access**: Allow users to view cached data

### Implementation
```dart
// Check connectivity
final isConnected = await ConnectivityService.isConnected();

// Make request with offline support
final response = await NetworkService.post(
  '/api/recommend',
  body: data,
  saveForOfflineSync: true,
);

// Sync offline data when online
await NetworkService.syncOfflineData();
```

## Configuration Management

### AppConfig
**File**: `lib/config/app_config.dart`

Centralized configuration management with environment variable support.

```dart
class AppConfig {
  // API Configuration
  static String get cropApiBaseUrl => 
    dotenv.env['CROP_API_BASE_URL'] ?? 'http://localhost:5000/api/v1';
  
  // Validation
  static bool get isCropApiUrlValid => 
    cropApiBaseUrl.isNotEmpty && cropApiBaseUrl.startsWith('http');
}
```

### Environment Variables
- **Development**: `env.development`
- **Production**: `env.production`
- **Staging**: `env.staging`

## Testing

### Unit Tests
**Directory**: `test/`

- Service layer tests
- Utility function tests
- Model tests

### Widget Tests
**Directory**: `test/widget_test.dart`

- UI component tests
- Screen interaction tests
- Form validation tests

### Integration Tests
**Directory**: `integration_test/`

- End-to-end user flows
- API integration tests
- Offline functionality tests

### Test Coverage
- **Target**: 80% code coverage
- **Tools**: `flutter test --coverage`
- **Reports**: Generated in `coverage/` directory

## Deployment

### Build Configurations
- **Debug**: Development builds with debugging enabled
- **Release**: Production builds optimized for performance
- **Profile**: Performance testing builds

### Build Commands
```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release

# App bundle for Play Store
flutter build appbundle --release
```

### Environment Setup
1. **Development**: Local development with mock APIs
2. **Staging**: Testing environment with staging APIs
3. **Production**: Live environment with production APIs

## Performance Optimization

### Image Optimization
- Use appropriate image formats (WebP, PNG, JPEG)
- Implement lazy loading for large images
- Cache images locally

### Memory Management
- Dispose controllers properly
- Use `const` constructors where possible
- Implement proper widget lifecycle management

### Network Optimization
- Implement request caching
- Use compression for API requests
- Batch multiple requests when possible

## Security

### Data Protection
- Encrypt sensitive data in local storage
- Use secure communication (HTTPS)
- Implement proper authentication

### Input Validation
- Validate all user inputs
- Sanitize data before processing
- Implement rate limiting

## Monitoring and Analytics

### Error Tracking
- Log errors to Firebase Crashlytics
- Track error patterns and frequency
- Monitor app stability

### Performance Monitoring
- Track app performance metrics
- Monitor API response times
- Track user engagement

### Analytics
- Track user behavior
- Monitor feature usage
- Analyze user retention

## Maintenance

### Code Quality
- Follow Flutter/Dart style guidelines
- Use static analysis tools
- Implement code reviews

### Documentation
- Keep API documentation updated
- Document code changes
- Maintain architecture documentation

### Updates
- Regular dependency updates
- Security patch updates
- Feature updates and improvements
