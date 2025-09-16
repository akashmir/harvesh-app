import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Error types for better categorization
enum ErrorType {
  network,
  api,
  validation,
  authentication,
  permission,
  unknown,
  timeout,
  serverError,
  noInternet,
  configuration
}

/// Error severity levels
enum ErrorSeverity { low, medium, high, critical }

/// Custom error class with detailed information
class AppError {
  final String message;
  final String userFriendlyMessage;
  final ErrorType type;
  final ErrorSeverity severity;
  final String? code;
  final Map<String, dynamic>? details;
  final bool isRetryable;
  final int? retryCount;

  AppError({
    required this.message,
    required this.userFriendlyMessage,
    required this.type,
    required this.severity,
    this.code,
    this.details,
    this.isRetryable = false,
    this.retryCount,
  });

  @override
  String toString() => 'AppError: $message (Type: $type, Severity: $severity)';
}

/// Comprehensive error handling service for the Flutter app
class ErrorHandler {
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  /// Handle HTTP response errors
  static AppError handleHttpError(http.Response response) {
    final statusCode = response.statusCode;
    String message = 'HTTP Error: $statusCode';
    String userFriendlyMessage = 'Something went wrong. Please try again.';
    ErrorType type = ErrorType.api;
    ErrorSeverity severity = ErrorSeverity.medium;
    bool isRetryable = false;

    switch (statusCode) {
      case 400:
        message = 'Bad Request: Invalid data provided';
        userFriendlyMessage = 'Please check your input and try again.';
        type = ErrorType.validation;
        severity = ErrorSeverity.low;
        break;
      case 401:
        message = 'Unauthorized: Authentication required';
        userFriendlyMessage = 'Please log in to continue.';
        type = ErrorType.authentication;
        severity = ErrorSeverity.medium;
        break;
      case 403:
        message = 'Forbidden: Access denied';
        userFriendlyMessage =
            'You don\'t have permission to perform this action.';
        type = ErrorType.permission;
        severity = ErrorSeverity.medium;
        break;
      case 404:
        message = 'Not Found: Resource not available';
        userFriendlyMessage = 'The requested information is not available.';
        type = ErrorType.api;
        severity = ErrorSeverity.low;
        break;
      case 408:
        message = 'Request Timeout';
        userFriendlyMessage = 'The request took too long. Please try again.';
        type = ErrorType.timeout;
        severity = ErrorSeverity.medium;
        isRetryable = true;
        break;
      case 429:
        message = 'Too Many Requests: Rate limit exceeded';
        userFriendlyMessage =
            'Too many requests. Please wait a moment and try again.';
        type = ErrorType.api;
        severity = ErrorSeverity.medium;
        isRetryable = true;
        break;
      case 500:
        message = 'Internal Server Error';
        userFriendlyMessage = 'Server error. Please try again later.';
        type = ErrorType.serverError;
        severity = ErrorSeverity.high;
        isRetryable = true;
        break;
      case 502:
      case 503:
      case 504:
        message = 'Service Unavailable';
        userFriendlyMessage =
            'Service temporarily unavailable. Please try again later.';
        type = ErrorType.serverError;
        severity = ErrorSeverity.high;
        isRetryable = true;
        break;
      default:
        if (statusCode >= 400 && statusCode < 500) {
          type = ErrorType.api;
          severity = ErrorSeverity.medium;
        } else if (statusCode >= 500) {
          type = ErrorType.serverError;
          severity = ErrorSeverity.high;
          isRetryable = true;
        }
    }

    return AppError(
      message: message,
      userFriendlyMessage: userFriendlyMessage,
      type: type,
      severity: severity,
      code: statusCode.toString(),
      isRetryable: isRetryable,
    );
  }

  /// Handle network exceptions
  static AppError handleNetworkError(dynamic error) {
    String message = error.toString();
    String userFriendlyMessage = 'Network error. Please check your connection.';
    ErrorType type = ErrorType.network;
    ErrorSeverity severity = ErrorSeverity.medium;
    bool isRetryable = true;

    if (message.contains('SocketException') ||
        message.contains('Network is unreachable')) {
      userFriendlyMessage =
          'No internet connection. Please check your network and try again.';
      type = ErrorType.noInternet;
      severity = ErrorSeverity.high;
    } else if (message.contains('TimeoutException')) {
      userFriendlyMessage = 'Request timed out. Please try again.';
      type = ErrorType.timeout;
      severity = ErrorSeverity.medium;
    } else if (message.contains('HandshakeException')) {
      userFriendlyMessage = 'Secure connection failed. Please try again.';
      type = ErrorType.network;
      severity = ErrorSeverity.medium;
    }

    return AppError(
      message: message,
      userFriendlyMessage: userFriendlyMessage,
      type: type,
      severity: severity,
      isRetryable: isRetryable,
    );
  }

  /// Handle validation errors
  static AppError handleValidationError(String field, String reason) {
    return AppError(
      message: 'Validation error for $field: $reason',
      userFriendlyMessage: 'Please check your input: $reason',
      type: ErrorType.validation,
      severity: ErrorSeverity.low,
      details: {'field': field, 'reason': reason},
    );
  }

  /// Handle configuration errors
  static AppError handleConfigurationError(String config) {
    return AppError(
      message: 'Configuration error: $config not found',
      userFriendlyMessage: 'App configuration error. Please contact support.',
      type: ErrorType.configuration,
      severity: ErrorSeverity.critical,
      details: {'config': config},
    );
  }

  /// Handle unknown errors
  static AppError handleUnknownError(dynamic error) {
    return AppError(
      message: 'Unknown error: $error',
      userFriendlyMessage: 'An unexpected error occurred. Please try again.',
      type: ErrorType.unknown,
      severity: ErrorSeverity.medium,
      isRetryable: true,
    );
  }

  /// Retry mechanism for retryable operations
  static Future<T> retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = _maxRetries,
    Duration delay = _retryDelay,
    bool Function(AppError)? shouldRetry,
  }) async {
    int attempts = 0;
    AppError? lastError;

    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (error) {
        lastError = _categorizeError(error);
        attempts++;

        if (!lastError.isRetryable ||
            (shouldRetry != null && !shouldRetry(lastError))) {
          break;
        }

        if (attempts < maxRetries) {
          await Future.delayed(delay * attempts); // Exponential backoff
        }
      }
    }

    throw lastError ?? handleUnknownError('Retry failed');
  }

  /// Categorize error based on type
  static AppError _categorizeError(dynamic error) {
    if (error is AppError) return error;
    if (error is http.Response) return handleHttpError(error);
    if (error.toString().contains('SocketException') ||
        error.toString().contains('Network')) {
      return handleNetworkError(error);
    }
    return handleUnknownError(error);
  }

  /// Show error dialog to user
  static void showErrorDialog(
    BuildContext context,
    AppError error, {
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              getErrorIcon(error.type),
              color: getErrorColor(error.severity),
            ),
            const SizedBox(width: 8),
            Text(getErrorTitle(error.type)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(error.userFriendlyMessage),
            if (error.details != null) ...[
              const SizedBox(height: 8),
              Text(
                'Details: ${error.details}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
        actions: [
          if (onDismiss != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDismiss();
              },
              child: const Text('Dismiss'),
            ),
          if (error.isRetryable && onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Retry'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show error snackbar
  static void showErrorSnackBar(
    BuildContext context,
    AppError error, {
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              getErrorIcon(error.type),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(error.userFriendlyMessage)),
          ],
        ),
        backgroundColor: getErrorColor(error.severity),
        duration: Duration(
            seconds: error.severity == ErrorSeverity.critical ? 10 : 4),
        action: error.isRetryable && onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Get error icon based on type
  static IconData getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.network:
      case ErrorType.noInternet:
        return Icons.wifi_off;
      case ErrorType.api:
      case ErrorType.serverError:
        return Icons.error_outline;
      case ErrorType.validation:
        return Icons.warning;
      case ErrorType.authentication:
        return Icons.lock;
      case ErrorType.permission:
        return Icons.block;
      case ErrorType.timeout:
        return Icons.timer_off;
      case ErrorType.configuration:
        return Icons.settings;
      case ErrorType.unknown:
        return Icons.help_outline;
    }
  }

  /// Get error color based on severity
  static Color getErrorColor(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return Colors.orange;
      case ErrorSeverity.medium:
        return Colors.amber;
      case ErrorSeverity.high:
        return Colors.red;
      case ErrorSeverity.critical:
        return Colors.red.shade800;
    }
  }

  /// Get error title based on type
  static String getErrorTitle(ErrorType type) {
    switch (type) {
      case ErrorType.network:
      case ErrorType.noInternet:
        return 'Connection Error';
      case ErrorType.api:
        return 'API Error';
      case ErrorType.serverError:
        return 'Server Error';
      case ErrorType.validation:
        return 'Input Error';
      case ErrorType.authentication:
        return 'Authentication Error';
      case ErrorType.permission:
        return 'Permission Error';
      case ErrorType.timeout:
        return 'Timeout Error';
      case ErrorType.configuration:
        return 'Configuration Error';
      case ErrorType.unknown:
        return 'Error';
    }
  }

  /// Log error for debugging
  static void logError(AppError error, {String? context}) {
    print('${context != null ? '[$context] ' : ''}${error.toString()}');
    // In production, you would send this to a logging service
  }

  /// Generic error handler (alias for _categorizeError)
  static AppError handleError(dynamic error) {
    return _categorizeError(error);
  }
}
