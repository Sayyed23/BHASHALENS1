import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'retry_policy.dart';
import 'package:bhashalens_app/debug_session_log.dart';

/// API Gateway client for AWS cloud services
/// Handles communication with AWS Lambda functions via API Gateway
class AwsApiGatewayClient {
  final String baseUrl;
  final String region;
  final bool _enableCloud;
  final Duration timeout;
  final http.Client _httpClient;
  final FirebaseAuth _auth;
  final RetryPolicy retryPolicy;

  AwsApiGatewayClient({
    String? baseUrl,
    String? region,
    bool? enableCloud,
    this.timeout = const Duration(seconds: 5),
    http.Client? httpClient,
    FirebaseAuth? auth,
    this.retryPolicy = RetryPolicy.defaultPolicy,
  })  : baseUrl = baseUrl ??
            (dotenv.isInitialized
                ? dotenv.env['AWS_API_GATEWAY_URL'] ?? ''
                : ''),
        region = region ??
            (dotenv.isInitialized
                ? dotenv.env['AWS_REGION'] ?? 'us-east-1'
                : 'us-east-1'),
        _enableCloud = enableCloud ??
            (dotenv.isInitialized
                ? dotenv.env['AWS_ENABLE_CLOUD']?.toLowerCase() == 'true'
                : false),
        _httpClient = httpClient ?? http.Client(),
        _auth = auth ?? FirebaseAuth.instance;

  /// Check if AWS cloud integration is enabled
  bool get isEnabled {
    return _enableCloud && baseUrl.isNotEmpty;
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
      // #region agent log
      DebugSessionLog.log(
        'aws_api_gateway_client.dart:_post',
        'api_request_start',
        data: {'endpoint': endpoint},
        hypothesisId: 'H2',
      );
      // #endregion

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
          // #region agent log
          DebugSessionLog.log(
            'aws_api_gateway_client.dart:_post',
            'api_request_success',
            data: {'endpoint': endpoint, 'statusCode': response.statusCode},
            hypothesisId: 'H2',
          );
          // #endregion
          if (response.body.isEmpty) {
            return <String, dynamic>{'success': true};
          }
          return jsonDecode(response.body) as Map<String, dynamic>;
        } else {
          // #region agent log
          DebugSessionLog.log(
            'aws_api_gateway_client.dart:_post',
            'api_request_failed',
            data: {
              'endpoint': endpoint,
              'statusCode': response.statusCode,
              'body': response.body.length > 200
                  ? '${response.body.substring(0, 200)}...'
                  : response.body,
            },
            hypothesisId: 'H2',
          );
          // #endregion
          throw AwsApiException(
            'API request failed: ${response.body}',
            statusCode: response.statusCode,
            responseBody: response.body,
          );
        }
      } catch (e) {
        if (e is AwsApiException) {
          // #region agent log
          DebugSessionLog.log(
            'aws_api_gateway_client.dart:_post',
            'api_request_error',
            data: {'endpoint': endpoint, 'error': e.toString()},
            hypothesisId: 'H2',
          );
          // #endregion
          rethrow;
        }
        throw AwsApiException(
          'Network error: ${e.toString()}',
          statusCode: 0,
          originalError: e,
        );
      }
    });
  }

  /// Generic GET request handler
  Future<Map<String, dynamic>> _get(
    String endpoint, {
    Map<String, String>? queryParameters,
  }) async {
    if (!isEnabled) {
      throw AwsApiException(
        'AWS cloud integration is not enabled',
        statusCode: 0,
      );
    }

    return retryPolicy.execute(() async {
      final uri = Uri.parse('$baseUrl$endpoint');
      final url = uri.replace(queryParameters: queryParameters);
      // #region agent log
      DebugSessionLog.log(
        'aws_api_gateway_client.dart:_get',
        'api_request_start',
        data: {'endpoint': endpoint},
        hypothesisId: 'H2',
      );
      // #endregion

      final headers = await _buildHeaders();

      try {
        final response = await _httpClient
            .get(
              url,
              headers: headers,
            )
            .timeout(timeout);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          // #region agent log
          DebugSessionLog.log(
            'aws_api_gateway_client.dart:_get',
            'api_request_success',
            data: {'endpoint': endpoint, 'statusCode': response.statusCode},
            hypothesisId: 'H2',
          );
          // #endregion
          return jsonDecode(response.body) as Map<String, dynamic>;
        } else {
          // #region agent log
          DebugSessionLog.log(
            'aws_api_gateway_client.dart:_get',
            'api_request_failed',
            data: {
              'endpoint': endpoint,
              'statusCode': response.statusCode,
            },
            hypothesisId: 'H2',
          );
          // #endregion
          throw AwsApiException(
            'API request failed: ${response.body}',
            statusCode: response.statusCode,
            responseBody: response.body,
          );
        }
      } catch (e) {
        if (e is AwsApiException) {
          // #region agent log
          DebugSessionLog.log(
            'aws_api_gateway_client.dart:_get',
            'api_request_error',
            data: {'endpoint': endpoint, 'error': e.toString()},
            hypothesisId: 'H2',
          );
          // #endregion
          rethrow;
        }
        throw AwsApiException(
          'Network error: ${e.toString()}',
          statusCode: 0,
          originalError: e,
        );
      }
    });
  }

  /// Generic DELETE request handler
  Future<Map<String, dynamic>> _delete(String endpoint) async {
    if (!isEnabled) {
      throw AwsApiException(
        'AWS cloud integration is not enabled',
        statusCode: 0,
      );
    }

    return retryPolicy.execute(() async {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _buildHeaders();

      try {
        final response = await _httpClient
            .delete(
              url,
              headers: headers,
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

  /// Generic PUT request handler
  Future<Map<String, dynamic>> _put(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    if (!isEnabled) {
      throw AwsApiException(
        'AWS cloud integration is not enabled',
        statusCode: 0,
      );
    }

    return retryPolicy.execute(() async {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _buildHeaders();

      try {
        final response = await _httpClient
            .put(
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

  // --- History Endpoints ---

  /// GET request to fetch translation history
  Future<Map<String, dynamic>> getHistory({
    int page = 1,
    int pageSize = 20,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
    };
    return _get('/history', queryParameters: queryParams);
  }

  /// DELETE request to remove a specific history item
  Future<Map<String, dynamic>> deleteHistoryItem(String id) async {
    return _delete('/history/$id');
  }

  /// POST request to manually add a history item (manual sync)
  Future<Map<String, dynamic>> addHistoryItem({
    required String sourceText,
    required String sourceLang,
    required String targetText,
    required String targetLang,
    int? timestamp,
    String? type,
    String? backend,
    int? processingTime,
  }) async {
    return _post(
      '/history',
      body: {
        'sourceText': sourceText,
        'sourceLang': sourceLang,
        'targetText': targetText,
        'targetLang': targetLang,
        if (timestamp != null) 'timestamp': timestamp,
        if (type != null) 'type': type,
        if (backend != null) 'backend': backend,
        if (processingTime != null) 'processingTime': processingTime,
      },
    );
  }

  // --- Saved Translations Endpoints ---

  /// GET request to fetch saved translations
  Future<Map<String, dynamic>> getSavedTranslations({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      if (search != null) 'search': search,
    };
    return _get('/saved', queryParameters: queryParams);
  }

  /// POST request to save a translation
  Future<Map<String, dynamic>> saveTranslation({
    required String translationId,
    required String sourceText,
    required String sourceLang,
    required String translatedText,
    required String targetLang,
    List<String>? tags,
  }) async {
    return _post(
      '/saved',
      body: {
        'translation_id': translationId,
        'source_text': sourceText,
        'source_lang': sourceLang,
        'translated_text': translatedText,
        'target_lang': targetLang,
        if (tags != null) 'tags': tags,
      },
    );
  }

  /// DELETE request to remove a saved translation
  Future<Map<String, dynamic>> deleteSavedTranslation(String id) async {
    return _delete('/saved/$id');
  }

  // --- Preferences Endpoints ---

  /// GET request to fetch user preferences
  Future<Map<String, dynamic>> getPreferences() async {
    return _get('/preferences');
  }

  /// PUT request to update user preferences
  Future<Map<String, dynamic>> updatePreferences(
      Map<String, dynamic> preferences) async {
    return _put(
      '/preferences',
      body: {
        'preferences': preferences,
      },
    );
  }

  // --- Export Endpoint ---

  /// POST request to export data
  Future<Map<String, dynamic>> exportData({
    required String exportType,
    required String format,
    String? startDate,
    String? endDate,
  }) async {
    return _post(
      '/export',
      body: {
        'exportType': exportType,
        'format': format,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      },
    );
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
