import 'package:flutter_test/flutter_test.dart';
import 'package:bhashalens_app/services/aws_api_gateway_client.dart';
import 'package:bhashalens_app/services/retry_policy.dart';

void main() {
  late AwsApiGatewayClient client;

  setUp(() {
    client = AwsApiGatewayClient(
      retryPolicy: const RetryPolicy(maxAttempts: 1),
    );
  });

  group('AwsApiGatewayClient', () {
    test('Initialization', () {
      expect(client.isEnabled, isFalse);
    });

    // Note: These tests are placeholders. 
    // Testing Amplify-integrated services usually requires integration tests or specific mocks 
    // for the Amplify singleton which are beyond the scope of this migration's immediate fix.
    
    test('translate call fails when not initialized', () async {
      expect(
        () => client.translate(
          sourceText: 'Hello',
          sourceLang: 'en',
          targetLang: 'es',
        ),
        throwsA(isA<AwsApiException>()),
      );
    });
  });
}
