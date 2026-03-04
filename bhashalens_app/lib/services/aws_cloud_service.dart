import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'aws_api_gateway_client.dart';
import 'circuit_breaker.dart';

/// Cloud service for AWS-enhanced translation and assistance
/// Provides high-level interface for cloud-augmented features
class AwsCloudService {
  final AwsApiGatewayClient _apiClient;
  final CircuitBreaker _circuitBreaker;

  AwsCloudService({
    AwsApiGatewayClient? apiClient,
    CircuitBreaker? circuitBreaker,
  })  : _apiClient = apiClient ?? AwsApiGatewayClient(),
        _circuitBreaker = circuitBreaker ??
            CircuitBreakerRegistry().getOrCreate(
              'aws-cloud-service',
              failureThreshold: 5,
              timeout: const Duration(seconds: 5),
              resetTimeout: const Duration(seconds: 30),
            );

  /// Check if cloud service is available
  bool get isAvailable => _apiClient.isEnabled && !_circuitBreaker.isOpen;

  /// Cloud-enhanced translation using AWS Bedrock
  Future<CloudTranslationResult> translateText({
    required String sourceText,
    required String sourceLang,
    required String targetLang,
    String? userId,
  }) async {
    try {
      final startTime = DateTime.now();
      
      final response = await _circuitBreaker.execute(() => _apiClient.translate(
        sourceText: sourceText,
        sourceLang: sourceLang,
        targetLang: targetLang,
        userId: userId,
      ));

      final processingTime = DateTime.now().difference(startTime);

      return CloudTranslationResult(
        translatedText: response['translated_text'] as String,
        confidence: (response['confidence'] as num?)?.toDouble() ?? 0.0,
        model: response['model'] as String? ?? 'unknown',
        processingTimeMs: response['processing_time_ms'] as int? ?? 
            processingTime.inMilliseconds,
        success: true,
      );
    } on CircuitBreakerOpenException catch (e) {
      debugPrint('Circuit breaker open: $e');
      return CloudTranslationResult(
        translatedText: '',
        confidence: 0.0,
        model: '',
        processingTimeMs: 0,
        success: false,
        error: 'Service temporarily unavailable',
      );
    } on AwsApiException catch (e) {
      debugPrint('Cloud translation failed: $e');
      return CloudTranslationResult(
        translatedText: '',
        confidence: 0.0,
        model: '',
        processingTimeMs: 0,
        success: false,
        error: e.message,
      );
    }
  }

  /// Cloud-enhanced grammar checking
  Future<CloudGrammarResult> checkGrammar({
    required String text,
    required String language,
    String? userId,
  }) async {
    try {
      final startTime = DateTime.now();
      
      final response = await _apiClient.assist(
        requestType: 'grammar',
        text: text,
        language: language,
        userId: userId,
      );

      final processingTime = DateTime.now().difference(startTime);
      final metadata = response['metadata'] as Map<String, dynamic>? ?? {};

      return CloudGrammarResult(
        response: response['response'] as String,
        corrections: (metadata['corrections'] as List?)
                ?.map((c) => c as Map<String, dynamic>)
                .toList() ??
            [],
        processingTimeMs: response['processing_time_ms'] as int? ?? 
            processingTime.inMilliseconds,
        success: true,
      );
    } on AwsApiException catch (e) {
      debugPrint('Cloud grammar check failed: $e');
      return CloudGrammarResult(
        response: '',
        corrections: [],
        processingTimeMs: 0,
        success: false,
        error: e.message,
      );
    }
  }

  /// Cloud-enhanced Q&A
  Future<CloudQAResult> answerQuestion({
    required String question,
    required String language,
    String? context,
    String? userId,
  }) async {
    try {
      final startTime = DateTime.now();
      
      final response = await _apiClient.assist(
        requestType: 'qa',
        text: question,
        language: language,
        context: context,
        userId: userId,
      );

      final processingTime = DateTime.now().difference(startTime);
      final metadata = response['metadata'] as Map<String, dynamic>? ?? {};

      return CloudQAResult(
        answer: response['response'] as String,
        confidence: (metadata['confidence'] as num?)?.toDouble() ?? 0.0,
        sources: (metadata['sources'] as List?)
                ?.map((s) => s as String)
                .toList() ??
            [],
        processingTimeMs: response['processing_time_ms'] as int? ?? 
            processingTime.inMilliseconds,
        success: true,
      );
    } on AwsApiException catch (e) {
      debugPrint('Cloud Q&A failed: $e');
      return CloudQAResult(
        answer: '',
        confidence: 0.0,
        sources: [],
        processingTimeMs: 0,
        success: false,
        error: e.message,
      );
    }
  }

  /// Cloud-enhanced conversation practice
  Future<CloudConversationResult> practiceConversation({
    required String userMessage,
    required String language,
    required List<Map<String, String>> conversationHistory,
    String? userId,
  }) async {
    try {
      final startTime = DateTime.now();
      
      final response = await _apiClient.assist(
        requestType: 'conversation',
        text: userMessage,
        language: language,
        conversationHistory: conversationHistory,
        userId: userId,
      );

      final processingTime = DateTime.now().difference(startTime);
      final metadata = response['metadata'] as Map<String, dynamic>? ?? {};

      return CloudConversationResult(
        response: response['response'] as String,
        suggestedFollowUps: (metadata['suggested_follow_ups'] as List?)
                ?.map((s) => s as String)
                .toList() ??
            [],
        processingTimeMs: response['processing_time_ms'] as int? ?? 
            processingTime.inMilliseconds,
        success: true,
      );
    } on AwsApiException catch (e) {
      debugPrint('Cloud conversation failed: $e');
      return CloudConversationResult(
        response: '',
        suggestedFollowUps: [],
        processingTimeMs: 0,
        success: false,
        error: e.message,
      );
    }
  }

  /// Cloud-enhanced text simplification
  Future<CloudSimplificationResult> simplifyText({
    required String text,
    required String targetComplexity,
    required String language,
    bool includeExplanation = false,
    String? userId,
  }) async {
    try {
      final startTime = DateTime.now();
      
      final response = await _apiClient.simplify(
        text: text,
        targetComplexity: targetComplexity,
        language: language,
        explain: includeExplanation,
        userId: userId,
      );

      final processingTime = DateTime.now().difference(startTime);

      return CloudSimplificationResult(
        simplifiedText: response['simplified_text'] as String,
        explanation: response['explanation'] as String?,
        complexityReduction: 
            (response['complexity_reduction'] as num?)?.toDouble() ?? 0.0,
        processingTimeMs: response['processing_time_ms'] as int? ?? 
            processingTime.inMilliseconds,
        success: true,
      );
    } on AwsApiException catch (e) {
      debugPrint('Cloud simplification failed: $e');
      return CloudSimplificationResult(
        simplifiedText: '',
        explanation: null,
        complexityReduction: 0.0,
        processingTimeMs: 0,
        success: false,
        error: e.message,
      );
    }
  }

  /// Cloud-enhanced text explanation/analysis
  Future<Map<String, dynamic>> explainText({
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
    String? userId,
  }) async {
    try {
      final response = await answerQuestion(
        question: "Explain the following text in detail. Provide context, key terms, and cultural nuances if applicable. Text: $text",
        language: targetLanguage,
        context: "The source language is ${sourceLanguage ?? 'unknown'}.",
        userId: userId,
      );

      if (response.success) {
        // Parse the answer into a map if possible, or return as 'explanation'
        return {
          'explanation': response.answer,
          'confidence': response.confidence,
          'sources': response.sources,
          'model': 'aws-bedrock',
        };
      }
      throw Exception(response.error ?? 'Unknown error');
    } catch (e) {
      debugPrint('Aws explainText failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getBasicGuide(String situation, String language) async {
    final prompt = "Provide a basic cultural and linguistic guide for a $situation situation in $language. Return as JSON with 'cultural_tips' (list), 'common_phrases' (list of {phrase, translation}), and 'etiquette' (string).";
    
    try {
      final response = await answerQuestion(
        question: prompt,
        language: language,
        userId: null,
      );
      
      if (response.success) {
        try {
          // Attempt to parse JSON from the response
          final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(response.answer);
          if (jsonMatch != null) {
            final jsonStr = jsonMatch.group(0)!;
            return jsonDecode(jsonStr);
          }
          
          // Fallback: If no JSON structure found, try parsing the whole answer
          return jsonDecode(response.answer);
        } catch (e) {
          debugPrint('JSON parsing failed for guide: $e. Falling back to default guide.');
        }
      }
      return {
        'cultural_tips': ['Be polite and respectful', 'Observe local customs and dress codes'],
        'common_phrases': [
          {'phrase': 'Help', 'translation': 'Madad'},
          {'phrase': 'Thank you', 'translation': 'Vaada'},
        ],
        'etiquette': 'General professional and respectful etiquette'
      };
    } catch (e) {
      debugPrint('Aws getBasicGuide error: $e');
      return {
        'cultural_tips': ['Error loading guide'],
        'common_phrases': [],
        'etiquette': 'N/A'
      };
    }
  }

  Future<String> startRoleplay(String situation, String goal, String language) async {
    final response = await practiceConversation(
      userMessage: "Let's start the roleplay. Situation: $situation. My goal: $goal.",
      language: language,
      conversationHistory: [],
      userId: null,
    );
    return response.success ? response.response : "I'm ready for our conversation.";
  }

  /// Dispose resources
  void dispose() {
    _apiClient.dispose();
    _circuitBreaker.dispose();
  }
}

/// Result classes for cloud operations

class CloudTranslationResult {
  final String translatedText;
  final double confidence;
  final String model;
  final int processingTimeMs;
  final bool success;
  final String? error;

  CloudTranslationResult({
    required this.translatedText,
    required this.confidence,
    required this.model,
    required this.processingTimeMs,
    required this.success,
    this.error,
  });
}

class CloudGrammarResult {
  final String response;
  final List<Map<String, dynamic>> corrections;
  final int processingTimeMs;
  final bool success;
  final String? error;

  CloudGrammarResult({
    required this.response,
    required this.corrections,
    required this.processingTimeMs,
    required this.success,
    this.error,
  });
}

class CloudQAResult {
  final String answer;
  final double confidence;
  final List<String> sources;
  final int processingTimeMs;
  final bool success;
  final String? error;

  CloudQAResult({
    required this.answer,
    required this.confidence,
    required this.sources,
    required this.processingTimeMs,
    required this.success,
    this.error,
  });
}

class CloudConversationResult {
  final String response;
  final List<String> suggestedFollowUps;
  final int processingTimeMs;
  final bool success;
  final String? error;

  CloudConversationResult({
    required this.response,
    required this.suggestedFollowUps,
    required this.processingTimeMs,
    required this.success,
    this.error,
  });
}

class CloudSimplificationResult {
  final String simplifiedText;
  final String? explanation;
  final double complexityReduction;
  final int processingTimeMs;
  final bool success;
  final String? error;

  CloudSimplificationResult({
    required this.simplifiedText,
    this.explanation,
    required this.complexityReduction,
    required this.processingTimeMs,
    required this.success,
    this.error,
  });
}
