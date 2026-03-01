import 'dart:async';
import 'package:flutter/foundation.dart';

/// Retry policy for cloud requests with exponential backoff
class RetryPolicy {
  final int maxAttempts;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;
  final bool Function(Exception)? shouldRetry;

  const RetryPolicy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 10),
    this.shouldRetry,
  });

  /// Default retry policy for cloud requests
  static const RetryPolicy defaultPolicy = RetryPolicy(
    maxAttempts: 3,
    initialDelay: Duration(seconds: 1),
    backoffMultiplier: 2.0,
    maxDelay: Duration(seconds: 10),
  );

  /// Execute a function with retry logic
  Future<T> execute<T>(Future<T> Function() operation) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (true) {
      attempt++;
      
      try {
        return await operation();
      } catch (e) {
        final isLastAttempt = attempt >= maxAttempts;
        final shouldRetryError = shouldRetry?.call(e as Exception) ?? 
            _defaultShouldRetry(e);

        if (isLastAttempt || !shouldRetryError) {
          debugPrint('Retry failed after $attempt attempts: $e');
          rethrow;
        }

        debugPrint('Attempt $attempt failed, retrying in ${delay.inSeconds}s: $e');
        
        await Future.delayed(delay);
        
        // Calculate next delay with exponential backoff
        delay = Duration(
          milliseconds: (delay.inMilliseconds * backoffMultiplier).toInt(),
        );
        
        // Cap at max delay
        if (delay > maxDelay) {
          delay = maxDelay;
        }
      }
    }
  }

  /// Default logic to determine if an error should be retried
  bool _defaultShouldRetry(dynamic error) {
    // Retry on network errors and server errors (5xx)
    if (error is TimeoutException) return true;
    
    // Check if it's an AWS API exception with retryable status
    if (error.toString().contains('Network error')) return true;
    if (error.toString().contains('status: 5')) return true; // 5xx errors
    if (error.toString().contains('status: 429')) return true; // Rate limit
    
    return false;
  }
}

/// Timeout configuration for cloud requests
class TimeoutConfig {
  final Duration requestTimeout;
  final Duration connectionTimeout;

  const TimeoutConfig({
    this.requestTimeout = const Duration(seconds: 5),
    this.connectionTimeout = const Duration(seconds: 3),
  });

  /// Default timeout configuration
  static const TimeoutConfig defaultConfig = TimeoutConfig(
    requestTimeout: Duration(seconds: 5),
    connectionTimeout: Duration(seconds: 3),
  );

  /// Relaxed timeout for complex operations
  static const TimeoutConfig relaxed = TimeoutConfig(
    requestTimeout: Duration(seconds: 10),
    connectionTimeout: Duration(seconds: 5),
  );
}

/// Extension to add timeout and retry to futures
extension RetryExtension<T> on Future<T> {
  /// Add retry logic to a future
  Future<T> withRetry([RetryPolicy policy = RetryPolicy.defaultPolicy]) {
    return policy.execute(() => this);
  }

  /// Add timeout with custom duration
  Future<T> withTimeout(Duration duration) {
    return timeout(
      duration,
      onTimeout: () => throw TimeoutException(
        'Operation timed out after ${duration.inSeconds}s',
      ),
    );
  }
}
