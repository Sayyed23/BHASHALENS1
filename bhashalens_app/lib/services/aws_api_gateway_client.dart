import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'retry_policy.dart';

/// Client to communicate with Amplify Gen 2 Backend GraphQL Endpoints
class AwsApiGatewayClient extends ChangeNotifier {
  final RetryPolicy retryPolicy;
  bool _isConfigured = false;

  AwsApiGatewayClient({
    this.retryPolicy = RetryPolicy.defaultPolicy,
  });

  bool get isEnabled => _isConfigured;

  Future<void> configure(String amplifyConfig) async {
    if (_isConfigured) return;
    try {
      await Amplify.addPlugin(AmplifyAPI());
      await Amplify.configure(amplifyConfig);
      _isConfigured = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error configuring Amplify: $e');
    }
  }

  /// Helper to convert string to GraphQL API request
  GraphQLRequest<String> _createPostRequest(String document, Map<String, dynamic> variables) {
    return GraphQLRequest<String>(
      document: document,
      variables: variables,
    );
  }

  /// Handles generic GraphQL Request execution with retries and error handling
  Future<Map<String, dynamic>> _executeRequest(String operationName, GraphQLRequest<String> request) async {
    if (!isEnabled) {
      throw AwsApiException('AWS cloud integration is not enabled or configured.', statusCode: 0);
    }
    return retryPolicy.execute(() async {
      try {
        final operation = Amplify.API.query(request: request);
        final response = await operation.response;

        final data = response.data;
        if (data != null) {
          final Map<String, dynamic> parsedData = jsonDecode(data);
          return parsedData[operationName] != null ? jsonDecode(parsedData[operationName] as String) as Map<String, dynamic> : parsedData;
        }

        if (response.errors.isNotEmpty) {
          throw AwsApiException(response.errors.first.message, statusCode: 500);
        }

        return <String, dynamic>{'success': true};
      } on ApiException catch (e) {
         throw AwsApiException('API Exception: ${e.message}', statusCode: 500, originalError: e);
      } catch (e) {
         throw AwsApiException('Unexpected Error: $e', statusCode: 0, originalError: e);
      }
    });
  }

   // --- History Endpoints ---

  Future<Map<String, dynamic>> getHistory({
    int page = 1,
    int pageSize = 20,
    String? startDate,
    String? endDate,
  }) async {
    const document = '''
      query GetHistory(\$page: Int, \$pageSize: Int, \$startDate: String, \$endDate: String) {
        getHistory(page: \$page, pageSize: \$pageSize, startDate: \$startDate, endDate: \$endDate)
      }
    ''';
    final variables = {
      'page': page,
      'pageSize': pageSize,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
    };
    return _executeRequest('getHistory', _createPostRequest(document, variables));
  }

  Future<Map<String, dynamic>> deleteHistoryItem(String id) async {
    const document = '''
      mutation DeleteHistoryItem(\$id: String!) {
        deleteHistoryItem(id: \$id)
      }
    ''';
    return _executeRequest('deleteHistoryItem', _createPostRequest(document, {'id': id}));
  }

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
    const document = '''
      mutation AddHistoryItem(\$sourceText: String!, \$sourceLang: String!, \$targetText: String!, \$targetLang: String!, \$timestamp: Int, \$type: String, \$backend: String, \$processingTime: Int) {
        addHistoryItem(sourceText: \$sourceText, sourceLang: \$sourceLang, targetText: \$targetText, targetLang: \$targetLang, timestamp: \$timestamp, type: \$type, backend: \$backend, processingTime: \$processingTime)
      }
    ''';
    final variables = {
      'sourceText': sourceText,
      'sourceLang': sourceLang,
      'targetText': targetText,
      'targetLang': targetLang,
      if (timestamp != null) 'timestamp': timestamp,
      if (type != null) 'type': type,
      if (backend != null) 'backend': backend,
      if (processingTime != null) 'processingTime': processingTime,
    };
    return _executeRequest('addHistoryItem', _createPostRequest(document, variables));
  }

  // --- Saved Translations Endpoints ---

  Future<Map<String, dynamic>> getSavedTranslations({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
     const document = '''
      query GetSavedTranslations(\$page: Int, \$pageSize: Int, \$search: String) {
        getSavedTranslations(page: \$page, pageSize: \$pageSize, search: \$search)
      }
    ''';
    final variables = {
      'page': page,
      'pageSize': pageSize,
      if (search != null) 'search': search,
    };
    return _executeRequest('getSavedTranslations', _createPostRequest(document, variables));
  }

  Future<Map<String, dynamic>> saveTranslation({
    required String translationId,
    required String sourceText,
    required String sourceLang,
    required String translatedText,
    required String targetLang,
    List<String>? tags,
  }) async {
     const document = '''
      mutation SaveTranslation(\$translation_id: String!, \$source_text: String!, \$source_lang: String!, \$translated_text: String!, \$target_lang: String!, \$tags: [String]) {
        saveTranslation(translation_id: \$translation_id, source_text: \$source_text, source_lang: \$source_lang, translated_text: \$translated_text, target_lang: \$target_lang, tags: \$tags)
      }
    ''';
    final variables = {
      'translation_id': translationId,
      'source_text': sourceText,
      'source_lang': sourceLang,
      'translated_text': translatedText,
      'target_lang': targetLang,
      if (tags != null) 'tags': tags,
    };
    return _executeRequest('saveTranslation', _createPostRequest(document, variables));
  }

  Future<Map<String, dynamic>> deleteSavedTranslation(String id) async {
     const document = '''
      mutation DeleteSavedTranslation(\$id: String!) {
        deleteSavedTranslation(id: \$id)
      }
    ''';
    return _executeRequest('deleteSavedTranslation', _createPostRequest(document, {'id': id}));
  }

  // --- Preferences Endpoints ---

  Future<Map<String, dynamic>> getPreferences() async {
    const document = '''
      query GetPreferences {
        getPreferences
      }
    ''';
    return _executeRequest('getPreferences', _createPostRequest(document, {}));
  }

  Future<Map<String, dynamic>> updatePreferences(Map<String, dynamic> preferences) async {
     const document = '''
      mutation UpdatePreferences(\$preferences: AWSJSON!) {
        updatePreferences(preferences: \$preferences)
      }
    ''';
    return _executeRequest('updatePreferences', _createPostRequest(document, {'preferences': jsonEncode(preferences)}));
  }

  // --- Export Endpoint ---

  Future<Map<String, dynamic>> exportData({
    required String exportType,
    required String format,
    String? startDate,
    String? endDate,
  }) async {
     const document = '''
      mutation ExportData(\$exportType: String!, \$format: String!, \$startDate: String, \$endDate: String) {
        exportData(exportType: \$exportType, format: \$format, startDate: \$startDate, endDate: \$endDate)
      }
    ''';
    final variables = {
      'exportType': exportType,
      'format': format,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
    };
    return _executeRequest('exportData', _createPostRequest(document, variables));
  }
}

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

  @override
  String toString() {
    return 'AwsApiException: $message (status: $statusCode)';
  }
}
