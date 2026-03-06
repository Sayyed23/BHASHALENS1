import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bhashalens_app/services/aws_api_gateway_client.dart';
import 'package:bhashalens_app/services/retry_policy.dart';

// Generate mock classes
import 'aws_api_gateway_client_test.mocks.dart';

@GenerateMocks([http.Client, FirebaseAuth, User])
void main() {
  late AwsApiGatewayClient client;
  late MockClient mockHttpClient;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;

  setUp(() {
    mockHttpClient = MockClient();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();

    // Setup mock auth behavior
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.getIdToken())
        .thenAnswer((_) async => 'mocked-firebase-token');

    client = AwsApiGatewayClient(
      baseUrl: 'https://api.test.com',
      region: 'us-east-1',
      enableCloud: true,
      httpClient: mockHttpClient,
      auth: mockAuth,
      retryPolicy:
          const RetryPolicy(maxAttempts: 1), // Disable retries for simpler tests
    );
  });

  group('AwsApiGatewayClient', () {
    test('translate success', () async {
      final responseBody = {'translated_text': 'Hola', 'model': 'test-model'};

      when(mockHttpClient.post(
        Uri.parse('https://api.test.com/translate'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(jsonEncode(responseBody), 200));

      final result = await client.translate(
        sourceText: 'Hello',
        sourceLang: 'en',
        targetLang: 'es',
        userId: 'user123',
      );

      expect(result['translated_text'], 'Hola');

      // Verify headers
      final captured = verify(mockHttpClient.post(
        any,
        headers: captureAnyNamed('headers'),
        body: anyNamed('body'),
      )).captured;

      final headers = captured.first as Map<String, String>;
      expect(headers['Authorization'], 'Bearer mocked-firebase-token');
    });

    test('getHistory success', () async {
      final responseBody = {'items': [], 'total': 0};

      when(mockHttpClient.get(
        any,
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(jsonEncode(responseBody), 200));

      final result = await client.getHistory(page: 1, pageSize: 10);

      expect(result['items'], isEmpty);

      final captured = verify(mockHttpClient.get(
        captureAny,
        headers: anyNamed('headers'),
      )).captured;

      final url = captured.first as Uri;
      expect(url.path, '/history');
      expect(url.queryParameters['page'], '1');
      expect(url.queryParameters['pageSize'], '10');
    });

    test('error handling', () async {
      when(mockHttpClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('Internal Server Error', 500));

      expect(
        () => client.translate(
          sourceText: 'Hello',
          sourceLang: 'en',
          targetLang: 'es',
        ),
        throwsA(isA<AwsApiException>()
            .having((e) => e.statusCode, 'statusCode', 500)
            .having((e) => e.isServerError, 'isServerError', isTrue)),
      );
    });

    test('timeout handling', () async {
      when(mockHttpClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenThrow(http.ClientException('Timeout'));

      expect(
        () => client.translate(
          sourceText: 'Hello',
          sourceLang: 'en',
          targetLang: 'es',
        ),
        throwsA(isA<AwsApiException>()
            .having((e) => e.isNetworkError, 'isNetworkError', isTrue)),
      );
    });
  });
}
