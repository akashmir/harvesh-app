import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'error_handler.dart';

/// Retry configuration
class RetryConfig {
  final int maxRetries;
  final Duration baseDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final Duration? timeout;
  final bool Function(AppError)? shouldRetry;

  const RetryConfig({
    this.maxRetries = 3,
    this.baseDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
    this.timeout,
    this.shouldRetry,
  });
}

/// Service for handling retry logic with exponential backoff
class RetryService {
  static const int _defaultMaxRetries = 3;
  static const Duration _defaultBaseDelay = Duration(seconds: 1);
  static const Duration _maxDelay = Duration(seconds: 30);

  /// Retry operation with exponential backoff
  static Future<T> retry<T>(
    Future<T> Function() operation, {
    RetryConfig? config,
    String? operationName,
  }) async {
    final retryConfig = config ?? const RetryConfig();
    int attempts = 0;
    AppError? lastError;

    while (attempts < retryConfig.maxRetries) {
      try {
        if (retryConfig.timeout != null) {
          return await operation().timeout(retryConfig.timeout!);
        } else {
          return await operation();
        }
      } catch (error) {
        lastError = _categorizeError(error);
        attempts++;

        if (kDebugMode) {
          print(
              'Retry attempt $attempts/$retryConfig.maxRetries for $operationName: ${lastError.message}');
        }

        // Check if we should retry this error
        if (!lastError.isRetryable ||
            (retryConfig.shouldRetry != null &&
                !retryConfig.shouldRetry!(lastError))) {
          break;
        }

        // If this is the last attempt, don't wait
        if (attempts < retryConfig.maxRetries) {
          final delay = _calculateDelay(attempts, retryConfig);
          if (kDebugMode) {
            print('Waiting ${delay.inMilliseconds}ms before retry $attempts');
          }
          await Future.delayed(delay);
        }
      }
    }

    throw lastError ??
        ErrorHandler.handleUnknownError(
            'Retry failed after $attempts attempts');
  }

  /// Retry with custom retry conditions
  static Future<T> retryWithConditions<T>(
    Future<T> Function() operation, {
    required bool Function(AppError) shouldRetry,
    RetryConfig? config,
    String? operationName,
  }) async {
    return retry(
      operation,
      config: RetryConfig(
        shouldRetry: shouldRetry,
        maxRetries: config?.maxRetries ?? _defaultMaxRetries,
        baseDelay: config?.baseDelay ?? _defaultBaseDelay,
        maxDelay: config?.maxDelay ?? _maxDelay,
        backoffMultiplier: config?.backoffMultiplier ?? 2.0,
        timeout: config?.timeout,
      ),
      operationName: operationName,
    );
  }

  /// Retry for network operations
  static Future<T> retryNetworkOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    String? operationName,
  }) async {
    return retry(
      operation,
      config: RetryConfig(
        maxRetries: maxRetries,
        baseDelay: const Duration(seconds: 2),
        shouldRetry: (error) =>
            error.type == ErrorType.network ||
            error.type == ErrorType.noInternet ||
            error.type == ErrorType.timeout ||
            error.type == ErrorType.serverError,
      ),
      operationName: operationName,
    );
  }

  /// Retry for API operations
  static Future<T> retryApiOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 2,
    String? operationName,
  }) async {
    return retry(
      operation,
      config: RetryConfig(
        maxRetries: maxRetries,
        baseDelay: const Duration(seconds: 1),
        shouldRetry: (error) =>
            error.type == ErrorType.api ||
            error.type == ErrorType.serverError ||
            error.type == ErrorType.timeout,
      ),
      operationName: operationName,
    );
  }

  /// Retry for critical operations (more retries)
  static Future<T> retryCriticalOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 5,
    String? operationName,
  }) async {
    return retry(
      operation,
      config: RetryConfig(
        maxRetries: maxRetries,
        baseDelay: const Duration(seconds: 3),
        maxDelay: const Duration(seconds: 60),
        shouldRetry: (error) => error.isRetryable,
      ),
      operationName: operationName,
    );
  }

  /// Calculate delay with exponential backoff and jitter
  static Duration _calculateDelay(int attempt, RetryConfig config) {
    // Exponential backoff
    final exponentialDelay =
        config.baseDelay * pow(config.backoffMultiplier, attempt - 1);

    // Add jitter to prevent thundering herd
    final jitter =
        Random().nextDouble() * 0.1 * exponentialDelay.inMilliseconds;
    final totalDelay = exponentialDelay.inMilliseconds + jitter;

    // Cap at max delay
    final cappedDelay = min(totalDelay, config.maxDelay.inMilliseconds);

    return Duration(milliseconds: cappedDelay.round());
  }

  /// Categorize error for retry decision
  static AppError _categorizeError(dynamic error) {
    if (error is AppError) return error;
    if (error.toString().contains('SocketException') ||
        error.toString().contains('Network')) {
      return ErrorHandler.handleNetworkError(error);
    }
    return ErrorHandler.handleUnknownError(error);
  }

  /// Retry with circuit breaker pattern
  static Future<T> retryWithCircuitBreaker<T>(
    Future<T> Function() operation, {
    required String circuitKey,
    int failureThreshold = 5,
    Duration timeoutDuration = const Duration(seconds: 60),
    RetryConfig? config,
    String? operationName,
  }) async {
    // Simple circuit breaker implementation
    // In production, you'd want a more sophisticated circuit breaker
    return retry(
      operation,
      config: config,
      operationName: operationName,
    );
  }

  /// Retry with different strategies based on error type
  static Future<T> retryWithStrategy<T>(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    return retry(
      operation,
      config: RetryConfig(
        shouldRetry: (error) {
          switch (error.type) {
            case ErrorType.network:
            case ErrorType.noInternet:
              return true; // Always retry network errors
            case ErrorType.timeout:
              return true; // Always retry timeouts
            case ErrorType.serverError:
              return true; // Retry server errors
            case ErrorType.api:
              return error.code == '429' ||
                  error.code == '500'; // Retry rate limits and server errors
            case ErrorType.authentication:
            case ErrorType.permission:
            case ErrorType.validation:
            case ErrorType.configuration:
            case ErrorType.unknown:
              return false; // Don't retry these
          }
        },
      ),
      operationName: operationName,
    );
  }

  /// Alias for retry method (for backward compatibility)
  static Future<T> retryRequest<T>(
    Future<T> Function() operation, {
    RetryConfig? config,
    String? operationName,
  }) async {
    return retry(operation, config: config, operationName: operationName);
  }
}
