import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:bhashalens_app/services/smart_hybrid_router.dart';
import 'package:bhashalens_app/services/aws_cloud_service.dart';

import 'hybrid_router_test.mocks.dart';

@GenerateMocks([AwsCloudService, Connectivity])
void main() {
  late SmartHybridRouter router;
  late MockAwsCloudService mockCloudService;
  late MockConnectivity mockConnectivity;

  setUp(() {
    mockCloudService = MockAwsCloudService();
    mockConnectivity = MockConnectivity();
    router = SmartHybridRouter(
      cloudService: mockCloudService,
      connectivity: mockConnectivity,
    );

    // Default mock behavior
    when(mockCloudService.isAvailable).thenReturn(true);
  });

  group('SmartHybridRouter - Routing Logic', () {
    test('routes simple request to ML Kit', () async {
      const context = RoutingContext(
        networkStatus: NetworkStatus.wifi,
        batteryLevel: 100,
        userPreference: DataUsagePreference.cellularAllowed,
        requestComplexity: ComplexityLevel.simple,
      );

      final result = await router.routeTranslation(context);
      expect(result, equals(ProcessingBackend.mlKit));
    });

    test('routes complex request to AWS Bedrock', () async {
      const context = RoutingContext(
        networkStatus: NetworkStatus.wifi,
        batteryLevel: 100,
        userPreference: DataUsagePreference.cellularAllowed,
        requestComplexity: ComplexityLevel.complex,
      );

      final result = await router.routeTranslation(context);
      expect(result, equals(ProcessingBackend.awsBedrock));
    });

    test('routes moderate request to Gemini', () async {
      const context = RoutingContext(
        networkStatus: NetworkStatus.wifi,
        batteryLevel: 100,
        userPreference: DataUsagePreference.cellularAllowed,
        requestComplexity: ComplexityLevel.moderate,
      );

      final result = await router.routeTranslation(context);
      expect(result, equals(ProcessingBackend.gemini));
    });

    test('routes to ML Kit when offline', () async {
      const context = RoutingContext(
        networkStatus: NetworkStatus.offline,
        batteryLevel: 100,
        userPreference: DataUsagePreference.cellularAllowed,
        requestComplexity: ComplexityLevel.complex,
      );

      final result = await router.routeTranslation(context);
      expect(result, equals(ProcessingBackend.mlKit));
    });

    test('respects user preference (offlineOnly)', () async {
      const context = RoutingContext(
        networkStatus: NetworkStatus.wifi,
        batteryLevel: 100,
        userPreference: DataUsagePreference.offlineOnly,
        requestComplexity: ComplexityLevel.complex,
      );

      final result = await router.routeTranslation(context);
      expect(result, equals(ProcessingBackend.mlKit));
    });

    test('routes to ML Kit when cloud service is unavailable', () async {
      when(mockCloudService.isAvailable).thenReturn(false);

      const context = RoutingContext(
        networkStatus: NetworkStatus.wifi,
        batteryLevel: 100,
        userPreference: DataUsagePreference.cellularAllowed,
        requestComplexity: ComplexityLevel.complex,
      );

      final result = await router.routeTranslation(context);
      expect(result, equals(ProcessingBackend.mlKit));
    });
  });

  group('SmartHybridRouter - Complexity Estimation', () {
    test('estimates short text as simple', () {
      final level = router.estimateComplexity(text: 'Hello');
      expect(level, equals(ComplexityLevel.simple));
    });

    test('estimates long text as complex', () {
      final longText = 'A' * 600;
      final level = router.estimateComplexity(text: longText);
      expect(level, equals(ComplexityLevel.complex));
    });

    test('estimates medium text with context as complex', () {
      final midText = 'A' * 250;
      final level =
          router.estimateComplexity(text: midText, context: 'Some context');
      expect(level, equals(ComplexityLevel.complex));
    });
  });
}
