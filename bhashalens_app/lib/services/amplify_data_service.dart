import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';

class AmplifyDataService {
  bool _isConfigured = false;

  Future<void> configureAmplify(String amplifyOutputsJson) async {
    if (_isConfigured) return;

    try {
      final api = AmplifyAPI();
      
      await Amplify.addPlugin(api);
      
      if (amplifyOutputsJson.isNotEmpty) {
        // configuration happens in main.dart or setup phase
      }
      _isConfigured = true;
      safePrint('Amplify Analytics & API successfully configured');
    } on Exception catch (e) {
      safePrint('Error configuring Amplify: $e');
    }
  }

  // Generic function to query GraphQL data in Gen 2 (for custom functions returning AWSJSON)
  Future<List<Map<String, dynamic>>> queryTable(String document, {Map<String, dynamic>? variables}) async {
    try {
      final request = GraphQLRequest<String>(
        document: document,
        variables: variables ?? const <String, dynamic>{},
      );

      final response = await Amplify.API.query(request: request).response;
      
      if (response.data != null) {
        final Map<String, dynamic> data = jsonDecode(response.data!);
        if (data.isEmpty) return [];
        
        final key = data.keys.first;
        var queryResult = data[key];
        
        // Custom functions often return AWSJSON encoded as string
        if (queryResult is String) {
          try {
            queryResult = jsonDecode(queryResult);
          } catch (e) {
            safePrint('Error decoding AWSJSON: $e');
          }
        }
        
        if (queryResult is Map<String, dynamic>) {
          // If the backend returns { items: [...] }
          if (queryResult.containsKey('items')) {
            return (queryResult['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          }
          // If the backend returns a single item
          if (queryResult.containsKey('item')) {
             return [queryResult['item'] as Map<String, dynamic>];
          }
          return [queryResult];
        } else if (queryResult is List) {
          return queryResult.cast<Map<String, dynamic>>();
        }
        return [];
      } else {
        safePrint('GraphQL Query failed: ${response.errors}');
        return [];
      }
    } on ApiException catch (e) {
      safePrint('GraphQL Query Exception: $e');
      return [];
    }
  }

  // --- History ---

  Future<List<Map<String, dynamic>>> getTranslationHistory() async {
    const query = '''
      query GetHistory(\$page: Int, \$pageSize: Int) {
        getHistory(page: \$page, pageSize: \$pageSize)
      }
    ''';
    return await queryTable(query, variables: {'page': 1, 'pageSize': 100});
  }

  Future<void> saveHistoryItem(Map<String, dynamic> item) async {
    const query = '''
      mutation AddHistoryItem(
        \$sourceText: String!, 
        \$sourceLang: String!, 
        \$targetText: String!, 
        \$targetLang: String!, 
        \$timestamp: Int!, 
        \$type: String
      ) {
        addHistoryItem(
          sourceText: \$sourceText, 
          sourceLang: \$sourceLang, 
          targetText: \$targetText, 
          targetLang: \$targetLang, 
          timestamp: \$timestamp, 
          type: \$type
        )
      }
    ''';
    await queryTable(query, variables: {
      'sourceText': item['originalText'] ?? '',
      'sourceLang': item['fromLanguage'] ?? '',
      'targetText': item['translatedText'] ?? '',
      'targetLang': item['toLanguage'] ?? '',
      'timestamp': item['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      'type': item['type'] ?? 'translation'
    });
  }

  Future<void> deleteHistoryItem(String id) async {
    const query = '''
      mutation DeleteHistoryItem(\$id: String!) {
        deleteHistoryItem(id: \$id)
      }
    ''';
    await queryTable(query, variables: {'id': id});
  }

  // --- Saved Translations ---

  Future<List<Map<String, dynamic>>> getSavedTranslations() async {
    const query = '''
      query GetSavedTranslations(\$page: Int, \$pageSize: Int) {
        getSavedTranslations(page: \$page, pageSize: \$pageSize)
      }
    ''';
    return await queryTable(query, variables: {'page': 1, 'pageSize': 100});
  }

  Future<void> saveTranslation(Map<String, dynamic> item) async {
    const query = '''
      mutation SaveTranslation(
        \$translation_id: String!, 
        \$source_text: String!, 
        \$source_lang: String!, 
        \$translated_text: String!, 
        \$target_lang: String!, 
        \$tags: [String!]
      ) {
        saveTranslation(
          translation_id: \$translation_id, 
          source_text: \$source_text, 
          source_lang: \$source_lang, 
          translated_text: \$translated_text, 
          target_lang: \$target_lang, 
          tags: \$tags
        )
      }
    ''';
    
    await queryTable(query, variables: {
      'translation_id': item['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'source_text': item['originalText'] ?? '',
      'source_lang': item['fromLanguage'] ?? 'Auto',
      'translated_text': item['translatedText'] ?? '',
      'target_lang': item['toLanguage'] ?? 'Auto',
      'tags': [item['category'] ?? 'General'],
    });
  }

  Future<void> deleteSavedTranslation(String id) async {
    const query = '''
      mutation DeleteSavedTranslation(\$id: String!) {
        deleteSavedTranslation(id: \$id)
      }
    ''';
    await queryTable(query, variables: {'id': id});
  }
}

// Global instance for simple access similar to other services
final amplifyDataService = AmplifyDataService();
