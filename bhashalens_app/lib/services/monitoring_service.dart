import 'package:flutter/foundation.dart';

class MonitoringService {
  MonitoringService();

  void logEvent(String name, {Map<String, dynamic>? parameters}) {
    debugPrint('Monitoring: Event $name with params $parameters');
    if (parameters != null && parameters['is_critical'] == true) {
      debugPrint('Critical event: $name');
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
