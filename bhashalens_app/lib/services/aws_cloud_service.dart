import 'aws_api_gateway_client.dart';
import 'circuit_breaker.dart';

/// Cloud service for AWS-enhanced translation and assistance
/// Provides high-level interface for cloud-augmented features
/// [DEPRECATED] AI features moved to GeminiService
class AwsCloudService {
  final AwsApiGatewayClient _apiClient;
  final CircuitBreaker _circuitBreaker;

  AwsCloudService({
    AwsApiGatewayClient? apiClient,
    CircuitBreaker? circuitBreaker,
  })  : _apiClient = apiClient ?? AwsApiGatewayClient(),
        _circuitBreaker = circuitBreaker ??
            CircuitBreakerRegistry().getOrCreate(
              'aws-cloud-service',
              failureThreshold: 5,
              timeout: const Duration(seconds: 5),
              resetTimeout: const Duration(seconds: 30),
            );

  /// Check if cloud service is available
  bool get isAvailable => _apiClient.isEnabled && !_circuitBreaker.isOpen;

  /// Dispose resources
  void dispose() {
    _apiClient.dispose();
    _circuitBreaker.dispose();
  }
}
