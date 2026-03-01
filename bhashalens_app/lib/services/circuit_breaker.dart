import 'dart:async';
import 'package:flutter/foundation.dart';

/// Circuit breaker states
enum CircuitState {
  closed,  // Normal operation, requests pass through
  open,    // Circuit is open, requests fail fast
  halfOpen // Testing if service has recovered
}

/// Circuit breaker to prevent cascading failures
/// Implements the circuit breaker pattern for cloud service calls
class CircuitBreaker {
  final String name;
  final int failureThreshold;
  final Duration timeout;
  final Duration resetTimeout;
  
  CircuitState _state = CircuitState.closed;
  int _failureCount = 0;
  int _successCount = 0;
  DateTime? _lastFailureTime;
  Timer? _resetTimer;

  CircuitBreaker({
    required this.name,
    this.failureThreshold = 5,
    this.timeout = const Duration(seconds: 5),
    this.resetTimeout = const Duration(seconds: 30),
  });

  /// Get current circuit state
  CircuitState get state => _state;

  /// Get failure count
  int get failureCount => _failureCount;

  /// Check if circuit is open
  bool get isOpen => _state == CircuitState.open;

  /// Execute an operation through the circuit breaker
  Future<T> execute<T>(Future<T> Function() operation) async {
    // Check if circuit should transition from open to half-open
    if (_state == CircuitState.open) {
      if (_shouldAttemptReset()) {
        _transitionToHalfOpen();
      } else {
        throw CircuitBreakerOpenException(
          'Circuit breaker "$name" is open',
          failureCount: _failureCount,
        );
      }
    }

    try {
      final result = await operation().timeout(timeout);
      _onSuccess();
      return result;
    } catch (e) {
      _onFailure();
      rethrow;
    }
  }

  /// Handle successful operation
  void _onSuccess() {
    _failureCount = 0;
    
    if (_state == CircuitState.halfOpen) {
      _successCount++;
      // After 2 successful calls in half-open, close the circuit
      if (_successCount >= 2) {
        _transitionToClosed();
      }
    }
  }

  /// Handle failed operation
  void _onFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();
    _successCount = 0;

    if (_state == CircuitState.halfOpen) {
      // Failure in half-open state immediately opens circuit
      _transitionToOpen();
    } else if (_failureCount >= failureThreshold) {
      _transitionToOpen();
    }
  }

  /// Check if enough time has passed to attempt reset
  bool _shouldAttemptReset() {
    if (_lastFailureTime == null) return false;
    
    final timeSinceLastFailure = DateTime.now().difference(_lastFailureTime!);
    return timeSinceLastFailure >= resetTimeout;
  }

  /// Transition to closed state
  void _transitionToClosed() {
    debugPrint('Circuit breaker "$name": CLOSED');
    _state = CircuitState.closed;
    _failureCount = 0;
    _successCount = 0;
    _resetTimer?.cancel();
  }

  /// Transition to open state
  void _transitionToOpen() {
    debugPrint('Circuit breaker "$name": OPEN (failures: $_failureCount)');
    _state = CircuitState.open;
    
    // Schedule automatic transition to half-open
    _resetTimer?.cancel();
    _resetTimer = Timer(resetTimeout, () {
      if (_state == CircuitState.open) {
        _transitionToHalfOpen();
      }
    });
  }

  /// Transition to half-open state
  void _transitionToHalfOpen() {
    debugPrint('Circuit breaker "$name": HALF-OPEN (testing recovery)');
    _state = CircuitState.halfOpen;
    _successCount = 0;
  }

  /// Manually reset the circuit breaker
  void reset() {
    _transitionToClosed();
  }

  /// Dispose resources
  void dispose() {
    _resetTimer?.cancel();
  }
}

/// Exception thrown when circuit breaker is open
class CircuitBreakerOpenException implements Exception {
  final String message;
  final int failureCount;

  CircuitBreakerOpenException(this.message, {required this.failureCount});

  @override
  String toString() => 'CircuitBreakerOpenException: $message';
}

/// Circuit breaker registry to manage multiple circuit breakers
class CircuitBreakerRegistry {
  static final CircuitBreakerRegistry _instance = 
      CircuitBreakerRegistry._internal();
  
  factory CircuitBreakerRegistry() => _instance;
  
  CircuitBreakerRegistry._internal();

  final Map<String, CircuitBreaker> _breakers = {};

  /// Get or create a circuit breaker
  CircuitBreaker getOrCreate(
    String name, {
    int failureThreshold = 5,
    Duration timeout = const Duration(seconds: 5),
    Duration resetTimeout = const Duration(seconds: 30),
  }) {
    return _breakers.putIfAbsent(
      name,
      () => CircuitBreaker(
        name: name,
        failureThreshold: failureThreshold,
        timeout: timeout,
        resetTimeout: resetTimeout,
      ),
    );
  }

  /// Get circuit breaker by name
  CircuitBreaker? get(String name) => _breakers[name];

  /// Reset all circuit breakers
  void resetAll() {
    for (final breaker in _breakers.values) {
      breaker.reset();
    }
  }

  /// Get status of all circuit breakers
  Map<String, CircuitState> getStatus() {
    return Map.fromEntries(
      _breakers.entries.map((e) => MapEntry(e.key, e.value.state)),
    );
  }

  /// Dispose all circuit breakers
  void dispose() {
    for (final breaker in _breakers.values) {
      breaker.dispose();
    }
    _breakers.clear();
  }
}
