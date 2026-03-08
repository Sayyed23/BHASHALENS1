import 'package:flutter/foundation.dart';
import 'aws_api_gateway_client.dart';

class MonitoringService {
  MonitoringService({required AwsApiGatewayClient apiClient});

  void logEvent(String name, {Map<String, dynamic>? parameters}) {
    debugPrint('Monitoring: Event $name with params $parameters');
    // In a real implementation, we could send this to CloudWatch or another analytics service
    // For now, let's assume we can optionally send critical events via API Gateway
    if (parameters != null && parameters['is_critical'] == true) {
      debugPrint('Critical event: $name');
      // In a real implementation, we could send this to a dedicated logging service
    }
  }

  void logError(String message, {StackTrace? stackTrace}) {
    debugPrint('Monitoring: Error $message');
    if (stackTrace != null) debugPrint(stackTrace.toString());
  }

  void logPerformance(String action, int durationMs) {
    debugPrint('Monitoring: Performance $action took ${durationMs}ms');
  }
}
