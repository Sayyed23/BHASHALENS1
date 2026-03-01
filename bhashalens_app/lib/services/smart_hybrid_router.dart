import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'aws_cloud_service.dart';

/// Processing backend options
enum ProcessingBackend {
  onDevice,
  awsCloud,
}

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

/// Smart Hybrid Router - decides between on-device and cloud processing
/// Implements the routing logic defined in the design document
class SmartHybridRouter {
  final AwsCloudService _cloudService;
  final Connectivity _connectivity;
  
  // Configurable thresholds
  final int batteryThreshold;
  final Duration cloudTimeout;

  SmartHybridRouter({
    AwsCloudService? cloudService,
    Connectivity? connectivity,
    this.batteryThreshold = 20,
    this.cloudTimeout = const Duration(seconds: 5),
  })  : _cloudService = cloudService ?? AwsCloudService(),
        _connectivity = connectivity ?? Connectivity();

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
    // Rule 1: If network is offline → ON_DEVICE
    if (context.networkStatus == NetworkStatus.offline) {
      debugPrint('Router: Offline → ON_DEVICE');
      return ProcessingBackend.onDevice;
    }

    // Rule 2: If user preference is OFFLINE_ONLY → ON_DEVICE
    if (context.userPreference == DataUsagePreference.offlineOnly) {
      debugPrint('Router: User preference offline-only → ON_DEVICE');
      return ProcessingBackend.onDevice;
    }

    // Rule 3: If battery < threshold → ON_DEVICE
    if (context.batteryLevel < batteryThreshold) {
      debugPrint('Router: Low battery (${context.batteryLevel}%) → ON_DEVICE');
      return ProcessingBackend.onDevice;
    }

    // Rule 4: If user preference is WIFI_ONLY and network is CELLULAR → ON_DEVICE
    if (context.userPreference == DataUsagePreference.wifiOnly &&
        context.networkStatus == NetworkStatus.cellular) {
      debugPrint('Router: WiFi-only preference with cellular → ON_DEVICE');
      return ProcessingBackend.onDevice;
    }

    // Rule 5: If request complexity is SIMPLE → ON_DEVICE
    if (context.requestComplexity == ComplexityLevel.simple) {
      debugPrint('Router: Simple request → ON_DEVICE');
      return ProcessingBackend.onDevice;
    }

    // Rule 6: If cloud service is unavailable → ON_DEVICE
    if (!_cloudService.isAvailable) {
      debugPrint('Router: Cloud unavailable → ON_DEVICE');
      return ProcessingBackend.onDevice;
    }

    // Rule 7: If request complexity is COMPLEX and network available → AWS_CLOUD
    if (context.requestComplexity == ComplexityLevel.complex) {
      debugPrint('Router: Complex request with network → AWS_CLOUD');
      return ProcessingBackend.awsCloud;
    }

    // Default: ON_DEVICE for moderate complexity
    debugPrint('Router: Default (moderate) → ON_DEVICE');
    return ProcessingBackend.onDevice;
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
    // TODO: Implement battery level detection using battery_plus package
    // For now, return 100 to not block cloud usage
    return 100;
  }

  /// Create routing context from current device state
  Future<RoutingContext> createContext({
    required String text,
    String? context,
    List<dynamic>? history,
    DataUsagePreference? userPreference,
  }) async {
    final networkStatus = await getNetworkStatus();
    final batteryLevel = await getBatteryLevel();
    final complexity = estimateComplexity(
      text: text,
      context: context,
      history: history,
    );

    return RoutingContext(
      networkStatus: networkStatus,
      batteryLevel: batteryLevel,
      userPreference: userPreference ?? DataUsagePreference.cellularAllowed,
      requestComplexity: complexity,
    );
  }

  /// Dispose resources
  void dispose() {
    _cloudService.dispose();
  }
}
