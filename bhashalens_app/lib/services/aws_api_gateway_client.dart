import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'retry_policy.dart';

/// API Gateway client for AWS cloud services
/// Handles communication with AWS Lambda functions via API Gateway
class AwsApiGatewayClient {
  final String baseUrl;
  final String region;
  final Duration timeout;
  final http.Client _httpClient;
  final FirebaseAuth _auth;
  final RetryPolicy retryPolicy;

  AwsApiGatewayClient({
    String? baseUrl,
    String? region,
    this.timeout = const Duration(seconds: 5),
    http.Client? httpClient,
    FirebaseAuth? auth,
    this.retryPolicy = RetryPolicy.defaultPolicy,
  })  : baseUrl = baseUrl ?? dotenv.env['AWS_API_GATEWAY_URL'] ?? '',
        region = region ?? dotenv.env['AWS_REGION'] ?? 'us-east-1',
        _httpClient = httpClient ?? http.Client(),
        _auth = auth ?? FirebaseAuth.instance;

  /// Check if AWS cloud integration is enabled
  bool get isEnabled {
    final enabled = dotenv.env['AWS_ENABLE_CLOUD']?.toLowerCase() == 'true';
    return enabled && baseUrl.isNotEmpty;
  }

  /// POST request to translation endpoint
  Future<Map<String, dynamic>> translate({
    required String sourceText,
    required String sourceLang,
    required String targetLang,
    String? userId,
  }) async {
    return _post(
      '/translate',
      body: {
        'source_text': sourceText,
        'source_lang': sourceLang,
        'target_lang': targetLang,
        if (userId != null) 'user_id': userId,
      },
    );
  }

  /// POST request to assistance endpoint
  Future<Map<String, dynamic>> assist({
    required String requestType,
    required String text,
    required String language,
    String? context,
    List<Map<String, String>>? conversationHistory,
    String? userId,
  }) async {
    return _post(
      '/assist',
      body: {
        'request_type': requestType,
        'text': text,
        'language': language,
        if (context != null) 'context': context,
        if (conversationHistory != null)
          'conversation_history': conversationHistory,
        if (userId != null) 'user_id': userId,
      },
    );
  }

  /// POST request to simplification endpoint
  Future<Map<String, dynamic>> simplify({
    required String text,
    required String targetComplexity,
    required String language,
    bool explain = false,
    String? userId,
  }) async {
    return _post(
      '/simplify',
      body: {
        'text': text,
        'target_complexity': targetComplexity,
        'language': language,
        'explain': explain,
        if (userId != null) 'user_id': userId,
      },
    );
  }

  /// Generic POST request handler
  Future<Map<String, dynamic>> _post(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    if (!isEnabled) {
      throw AwsApiException(
        'AWS cloud integration is not enabled',
        statusCode: 0,
      );
    }

    // Execute with retry policy
    return retryPolicy.execute(() async {
      final url = Uri.parse('$baseUrl$endpoint');
      
      // Get Firebase ID token for authentication
      final headers = await _buildHeaders();
      
      try {
        final response = await _httpClient
            .post(
              url,
              headers: headers,
              body: jsonEncode(body),
            )
            .timeout(timeout);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        } else {
          throw AwsApiException(
            'API request failed: ${response.body}',
            statusCode: response.statusCode,
            responseBody: response.body,
          );
        }
      } catch (e) {
        if (e is AwsApiException) rethrow;
        throw AwsApiException(
          'Network error: ${e.toString()}',
          statusCode: 0,
          originalError: e,
        );
      }
    });
  }

  /// Build request headers with authentication
  Future<Map<String, String>> _buildHeaders() async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add Firebase ID token if user is authenticated
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final idToken = await user.getIdToken();
        if (idToken != null) {
          headers['Authorization'] = 'Bearer $idToken';
        }
      } catch (e) {
        // Continue without auth token if retrieval fails
        // This allows anonymous usage to fall back to on-device processing
      }
    }

    return headers;
  }

  /// Close the HTTP client
  void dispose() {
    _httpClient.close();
  }
}

/// Custom exception for AWS API errors
class AwsApiException implements Exception {
  final String message;
  final int statusCode;
  final String? responseBody;
  final dynamic originalError;

  AwsApiException(
    this.message, {
    required this.statusCode,
    this.responseBody,
    this.originalError,
  });

  bool get isNetworkError => statusCode == 0;
  bool get isServerError => statusCode >= 500;
  bool get isClientError => statusCode >= 400 && statusCode < 500;
  bool get isTimeout => originalError is http.ClientException;

  @override
  String toString() {
    return 'AwsApiException: $message (status: $statusCode)';
  }
}
