# API Documentation

## Overview
This document provides comprehensive documentation for all APIs used in the Crop Recommendation App.

## Table of Contents
1. [Authentication APIs](#authentication-apis)
2. [Crop Recommendation APIs](#crop-recommendation-apis)
3. [Weather APIs](#weather-apis)
4. [User Management APIs](#user-management-apis)
5. [Error Handling](#error-handling)
6. [Rate Limiting](#rate-limiting)
7. [Response Formats](#response-formats)

## Authentication APIs

### Firebase Authentication
The app uses Firebase Authentication for user management.

#### Sign Up
```dart
Future<UserCredential> signUp(String email, String password)
```
- **Purpose**: Create a new user account
- **Parameters**:
  - `email` (String): User's email address
  - `password` (String): User's password (minimum 6 characters)
- **Returns**: `UserCredential` object
- **Errors**: 
  - `FirebaseAuthException` with code `email-already-in-use`
  - `FirebaseAuthException` with code `weak-password`
  - `FirebaseAuthException` with code `invalid-email`

#### Sign In
```dart
Future<UserCredential> signIn(String email, String password)
```
- **Purpose**: Authenticate existing user
- **Parameters**:
  - `email` (String): User's email address
  - `password` (String): User's password
- **Returns**: `UserCredential` object
- **Errors**:
  - `FirebaseAuthException` with code `user-not-found`
  - `FirebaseAuthException` with code `wrong-password`
  - `FirebaseAuthException` with code `invalid-email`

#### Google Sign In
```dart
Future<UserCredential> signInWithGoogle()
```
- **Purpose**: Authenticate user with Google account
- **Returns**: `UserCredential` object
- **Errors**:
  - `FirebaseAuthException` with code `account-exists-with-different-credential`
  - `FirebaseAuthException` with code `invalid-credential`

#### Phone Authentication
```dart
Future<void> verifyPhoneNumber(String phoneNumber)
```
- **Purpose**: Send OTP to phone number
- **Parameters**:
  - `phoneNumber` (String): Phone number in international format (+91XXXXXXXXXX)
- **Returns**: `void`
- **Errors**:
  - `FirebaseAuthException` with code `invalid-phone-number`
  - `FirebaseAuthException` with code `too-many-requests`

#### Sign Out
```dart
Future<void> signOut()
```
- **Purpose**: Sign out current user
- **Returns**: `void`
- **Errors**: None

## Crop Recommendation APIs

### Get Crop Recommendation
```dart
Future<Map<String, dynamic>> getCropRecommendation({
  required double nitrogen,
  required double phosphorus,
  required double potassium,
  required double temperature,
  required double humidity,
  required double ph,
  required double rainfall,
  String model = 'rf',
})
```

- **Purpose**: Get crop recommendation based on soil and weather parameters
- **Parameters**:
  - `nitrogen` (double): Nitrogen content in soil (0-200 ppm)
  - `phosphorus` (double): Phosphorus content in soil (0-200 ppm)
  - `potassium` (double): Potassium content in soil (0-200 ppm)
  - `temperature` (double): Temperature in Celsius (-50 to 60)
  - `humidity` (double): Humidity percentage (0-100)
  - `ph` (double): pH level of soil (0-14)
  - `rainfall` (double): Rainfall in mm (0-500)
  - `model` (String): ML model to use ('rf', 'nn', 'svm')
- **Returns**: `Map<String, dynamic>` with recommendation data
- **Response Format**:
  ```json
  {
    "recommendation": "Rice",
    "confidence": 0.95,
    "top_3_predictions": [
      {"crop": "Rice", "confidence": 0.95},
      {"crop": "Wheat", "confidence": 0.03},
      {"crop": "Maize", "confidence": 0.02}
    ],
    "model_used": "rf",
    "timestamp": "2024-01-01T12:00:00Z"
  }
  ```
- **Errors**:
  - `AppError` with type `validation` for invalid input
  - `AppError` with type `api` for server errors
  - `AppError` with type `network` for network issues

### Get Available Crops
```dart
Future<List<String>> getAvailableCrops()
```
- **Purpose**: Get list of all available crops
- **Returns**: `List<String>` of crop names
- **Errors**:
  - `AppError` with type `api` for server errors
  - `AppError` with type `network` for network issues

### Get Model Performance
```dart
Future<Map<String, dynamic>> getModelPerformance()
```
- **Purpose**: Get performance metrics for all ML models
- **Returns**: `Map<String, dynamic>` with performance data
- **Response Format**:
  ```json
  {
    "rf": {
      "accuracy": 0.95,
      "precision": 0.94,
      "recall": 0.93,
      "f1_score": 0.935
    },
    "nn": {
      "accuracy": 0.92,
      "precision": 0.91,
      "recall": 0.90,
      "f1_score": 0.905
    }
  }
  ```

## Weather APIs

### Get Current Weather
```dart
Future<Map<String, dynamic>> getCurrentWeather(double latitude, double longitude)
```
- **Purpose**: Get current weather data for a location
- **Parameters**:
  - `latitude` (double): Latitude coordinate
  - `longitude` (double): Longitude coordinate
- **Returns**: `Map<String, dynamic>` with weather data
- **Response Format**:
  ```json
  {
    "temperature": 25.5,
    "humidity": 65,
    "pressure": 1013.25,
    "description": "Clear sky",
    "icon": "01d",
    "wind_speed": 3.5,
    "wind_direction": 180,
    "timestamp": "2024-01-01T12:00:00Z"
  }
  ```
- **Errors**:
  - `AppError` with type `api` for API errors
  - `AppError` with type `network` for network issues

### Get Weather Forecast
```dart
Future<List<Map<String, dynamic>>> getWeatherForecast(double latitude, double longitude)
```
- **Purpose**: Get 5-day weather forecast for a location
- **Parameters**:
  - `latitude` (double): Latitude coordinate
  - `longitude` (double): Longitude coordinate
- **Returns**: `List<Map<String, dynamic>>` with forecast data
- **Response Format**:
  ```json
  [
    {
      "date": "2024-01-01",
      "temperature": {"min": 20.0, "max": 30.0},
      "humidity": 65,
      "description": "Clear sky",
      "icon": "01d",
      "rainfall": 0.0
    }
  ]
  ```

## User Management APIs

### Get User Profile
```dart
Future<Map<String, dynamic>> getUserProfile(String userId)
```
- **Purpose**: Get user profile information
- **Parameters**:
  - `userId` (String): User's unique identifier
- **Returns**: `Map<String, dynamic>` with user data
- **Response Format**:
  ```json
  {
    "id": "user123",
    "email": "user@example.com",
    "displayName": "John Doe",
    "phoneNumber": "+919876543210",
    "createdAt": "2024-01-01T12:00:00Z",
    "lastLoginAt": "2024-01-01T12:00:00Z"
  }
  ```

### Update User Profile
```dart
Future<void> updateUserProfile(String userId, Map<String, dynamic> updates)
```
- **Purpose**: Update user profile information
- **Parameters**:
  - `userId` (String): User's unique identifier
  - `updates` (Map<String, dynamic>): Fields to update
- **Returns**: `void`
- **Errors**:
  - `AppError` with type `validation` for invalid data
  - `AppError` with type `api` for server errors

### Get Query History
```dart
Future<List<Map<String, dynamic>>> getQueryHistory(String userId)
```
- **Purpose**: Get user's crop recommendation history
- **Parameters**:
  - `userId` (String): User's unique identifier
- **Returns**: `List<Map<String, dynamic>>` with query history
- **Response Format**:
  ```json
  [
    {
      "id": "query123",
      "timestamp": "2024-01-01T12:00:00Z",
      "parameters": {
        "nitrogen": 50.0,
        "phosphorus": 30.0,
        "potassium": 40.0,
        "temperature": 25.0,
        "humidity": 65.0,
        "ph": 6.5,
        "rainfall": 100.0
      },
      "recommendation": "Rice",
      "confidence": 0.95
    }
  ]
  ```

## Error Handling

### Error Types
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

### Error Severity Levels
- `low`: Minor issues that don't affect functionality
- `medium`: Issues that may affect some functionality
- `high`: Issues that significantly affect functionality
- `critical`: Issues that prevent app from working

### Error Response Format
```json
{
  "error": {
    "message": "Error description",
    "userFriendlyMessage": "User-friendly error message",
    "type": "api",
    "severity": "high",
    "code": "INVALID_INPUT",
    "details": {
      "field": "temperature",
      "value": "invalid"
    },
    "isRetryable": true,
    "retryCount": 0
  }
}
```

## Rate Limiting

### Limits
- **Crop Recommendation API**: 100 requests per hour per user
- **Weather API**: 1000 requests per day per user
- **User Management API**: 500 requests per hour per user

### Rate Limit Headers
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640995200
```

### Rate Limit Exceeded Response
```json
{
  "error": {
    "message": "Rate limit exceeded",
    "userFriendlyMessage": "Too many requests. Please try again later.",
    "type": "api",
    "severity": "medium",
    "code": "RATE_LIMIT_EXCEEDED",
    "retryAfter": 3600
  }
}
```

## Response Formats

### Success Response
```json
{
  "success": true,
  "data": {
    // Response data
  },
  "timestamp": "2024-01-01T12:00:00Z",
  "requestId": "req_123456789"
}
```

### Error Response
```json
{
  "success": false,
  "error": {
    "message": "Error description",
    "userFriendlyMessage": "User-friendly error message",
    "type": "api",
    "severity": "high",
    "code": "ERROR_CODE",
    "details": {},
    "isRetryable": true,
    "retryCount": 0
  },
  "timestamp": "2024-01-01T12:00:00Z",
  "requestId": "req_123456789"
}
```

## Authentication

### API Key
All API requests require an API key in the header:
```
Authorization: Bearer YOUR_API_KEY
```

### Firebase Token
For authenticated requests, include Firebase token:
```
X-Firebase-Token: YOUR_FIREBASE_TOKEN
```

## Base URLs

### Development
- **Crop API**: `http://localhost:5000/api/v1`
- **Weather API**: `https://api.openweathermap.org/data/2.5`

### Production
- **Crop API**: `https://crop-api.yourdomain.com/api/v1`
- **Weather API**: `https://api.openweathermap.org/data/2.5`

## SDKs and Libraries

### Flutter Packages
- `firebase_auth: ^5.7.0` - Firebase Authentication
- `cloud_firestore: ^5.6.12` - Firestore database
- `http: ^1.1.0` - HTTP requests
- `connectivity_plus: ^5.0.2` - Network connectivity
- `shared_preferences: ^2.2.2` - Local storage

### Dependencies
- Flutter SDK: ^3.0.0
- Dart SDK: ^3.0.0
- Android API Level: 21+
- iOS Deployment Target: 11.0+

## Support

For API support and questions:
- **Email**: support@yourdomain.com
- **Documentation**: https://docs.yourdomain.com
- **Status Page**: https://status.yourdomain.com
