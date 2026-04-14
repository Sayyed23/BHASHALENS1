import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Note: ProcessingBackend enum is now defined in translation_history_entry.dart
import 'package:bhashalens_app/models/translation_history_entry.dart';

/// Network status
enum NetworkStatus {
  offline,
  wifi,
  cellular,
}

/// Data usage preference
enum DataUsagePreference {
  offlineOnly,
  wifiOnly,
  cellularAllowed,
}

/// Request complexity level
enum ComplexityLevel {
  simple,
  moderate,
  complex,
}

/// Routing context for decision making
class RoutingContext {
  final NetworkStatus networkStatus;
  final int batteryLevel;
  final DataUsagePreference userPreference;
  final ComplexityLevel requestComplexity;

  const RoutingContext({
    required this.networkStatus,
    required this.batteryLevel,
    required this.userPreference,
    required this.requestComplexity,
  });
}

/// Routing context for translation requests
class TranslationRoutingContext extends RoutingContext {
  const TranslationRoutingContext({
    required super.networkStatus,
    required super.batteryLevel,
    required super.userPreference,
    required super.requestComplexity,
  });
}

/// Routing context for assistance requests (Explain, Chat, Grammar)
class AssistanceRoutingContext extends RoutingContext {
  const AssistanceRoutingContext({
    required super.networkStatus,
    required super.batteryLevel,
    required super.userPreference,
    required super.requestComplexity,
  });
}

/// Routing context for simplification requests
class SimplificationRoutingContext extends RoutingContext {
  const SimplificationRoutingContext({
    required super.networkStatus,
    required super.batteryLevel,
    required super.userPreference,
    required super.requestComplexity,
  });
}

/// Smart Hybrid Router - decides between on-device and cloud processing
/// Implements the routing logic defined in the design document
class SmartHybridRouter {
  final Connectivity _connectivity;

  // Configurable thresholds
  final int batteryThreshold;
  final Duration cloudTimeout;

  SmartHybridRouter({
    Connectivity? connectivity,
    this.batteryThreshold = 20,
    this.cloudTimeout = const Duration(seconds: 5),
  })  : _connectivity = connectivity ?? Connectivity();

  /// Determine processing backend for translation requests
  Future<ProcessingBackend> routeTranslation(RoutingContext context) async {
    return _makeRoutingDecision(context);
  }

  /// Determine processing backend for assistance requests
  Future<ProcessingBackend> routeAssistance(RoutingContext context) async {
    return _makeRoutingDecision(context);
  }

  /// Determine processing backend for simplification requests
  Future<ProcessingBackend> routeSimplification(RoutingContext context) async {
    return _makeRoutingDecision(context);
  }

  /// Core routing decision logic
  /// Follows the decision tree from the design document
  Future<ProcessingBackend> _makeRoutingDecision(
    RoutingContext context,
  ) async {
    debugPrint('### SMART_ROUTER_GEMINI_STRICT ### kIsWeb: $kIsWeb');
    
    // Rule 0: If web environment, ALWAYS use Gemini as ML Kit is not supported
    if (kIsWeb) {
      debugPrint('### SMART_ROUTER_GEMINI_STRICT ### Web environment detected, enforcing Gemini for all requests.');
      return ProcessingBackend.gemini;
    }

    // Helper to determine if we should use ML Kit or Gemini
    ProcessingBackend mlKitOrGemini(String ruleName) {
      return ProcessingBackend.mlKit;
    }

    // Rule 1: If network is offline
    if (context.networkStatus == NetworkStatus.offline) {
      debugPrint('### SMART_ROUTER_GEMINI_STRICT ### Rule 1: Offline');
      return mlKitOrGemini('1');
    }

    // Rule 2: If user preference is OFFLINE_ONLY
    if (context.userPreference == DataUsagePreference.offlineOnly) {
      debugPrint('### SMART_ROUTER_GEMINI_STRICT ### Rule 2: OfflineOnlyPref');
      return mlKitOrGemini('2');
    }

    // Rule 3: If battery < threshold
    if (context.batteryLevel < batteryThreshold) {
      debugPrint('### SMART_ROUTER_GEMINI_STRICT ### Rule 3: LowBattery');
      return mlKitOrGemini('3');
    }

    // Rule 4: If user preference is WIFI_ONLY and network is CELLULAR
    if (context.userPreference == DataUsagePreference.wifiOnly &&
        context.networkStatus == NetworkStatus.cellular) {
       debugPrint('### SMART_ROUTER_GEMINI_STRICT ### Rule 4: WifiOnlyOnCellular');
      return mlKitOrGemini('4');
    }

    // Rule 5: If request complexity is SIMPLE → ML_KIT (only for standard translation)
    if (context.requestComplexity == ComplexityLevel.simple && 
        context is TranslationRoutingContext) {
      debugPrint('### SMART_ROUTER_GEMINI_STRICT ### Rule 5: SimpleTranslation');
      return mlKitOrGemini('5');
    }

    // Rule 6: Prefer GEMINI for AI modes or complex tasks, or as default cloud backend
    if (context is AssistanceRoutingContext || 
        context is SimplificationRoutingContext ||
        context.requestComplexity == ComplexityLevel.complex ||
        context.requestComplexity == ComplexityLevel.moderate) {
      debugPrint('### SMART_ROUTER_GEMINI_STRICT ### Complex/AI Mode → GEMINI');
      return ProcessingBackend.gemini;
    }

    // Default: ML_KIT for simple mobile requests, GEMINI for others
    debugPrint('### SMART_ROUTER_GEMINI_STRICT ### DefaultCase');
    return mlKitOrGemini('default');
  }

  /// Get current network status
  Future<NetworkStatus> getNetworkStatus() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();

      if (connectivityResult.contains(ConnectivityResult.none)) {
        return NetworkStatus.offline;
      } else if (connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.ethernet)) {
        return NetworkStatus.wifi;
      } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
        return NetworkStatus.cellular;
      } else {
        return NetworkStatus.offline;
      }
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return NetworkStatus.offline;
    }
  }

  /// Estimate request complexity based on input characteristics
  ComplexityLevel estimateComplexity({
    required String text,
    String? context,
    List<dynamic>? history,
  }) {
    // Simple heuristics for complexity estimation
    final textLength = text.length;
    final hasContext = context != null && context.isNotEmpty;
    final hasHistory = history != null && history.isNotEmpty;

    // Complex: Long text with context/history
    if (textLength > 500 || (textLength > 200 && (hasContext || hasHistory))) {
      return ComplexityLevel.complex;
    }

    // Moderate: Medium text or has context
    if (textLength > 100 || hasContext || hasHistory) {
      return ComplexityLevel.moderate;
    }

    // Simple: Short text without context
    return ComplexityLevel.simple;
  }

  /// Get battery level (placeholder - requires platform-specific implementation)
  /// Returns 100 by default (assumes full battery)
  Future<int> getBatteryLevel() async {
    return 100;
  }

  /// Create routing context from current device state
  Future<RoutingContext> createContext({
    required String text,
    String? context,
    List<dynamic>? history,
    DataUsagePreference? userPreference,
    String mode = 'translation',
  }) async {
    final networkStatus = await getNetworkStatus();
    final batteryLevel = await getBatteryLevel();
    final complexity = estimateComplexity(
      text: text,
      context: context,
      history: history,
    );

    if (mode == 'assistance' || mode == 'explain') {
      return AssistanceRoutingContext(
        networkStatus: networkStatus,
        batteryLevel: batteryLevel,
        userPreference: userPreference ?? DataUsagePreference.cellularAllowed,
        requestComplexity: complexity,
      );
    } else if (mode == 'simplification' || mode == 'simplify') {
      return SimplificationRoutingContext(
        networkStatus: networkStatus,
        batteryLevel: batteryLevel,
        userPreference: userPreference ?? DataUsagePreference.cellularAllowed,
        requestComplexity: complexity,
      );
    }

    return TranslationRoutingContext(
      networkStatus: networkStatus,
      batteryLevel: batteryLevel,
      userPreference: userPreference ?? DataUsagePreference.cellularAllowed,
      requestComplexity: complexity,
    );
  }

  /// Dispose resources
  void dispose() {
    // No-op for now as connectivity doesn't need explicit dispose here in this way
  }
}
