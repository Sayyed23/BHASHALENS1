import 'package:flutter/foundation.dart';
import 'smart_hybrid_router.dart';
import 'aws_cloud_service.dart';
import 'ml_kit_translation_service.dart';
import 'gemini_service.dart';
import 'local_storage_service.dart';

/// Unified translation service that routes between on-device and cloud
class HybridTranslationService {
  final SmartHybridRouter _router;
  final AwsCloudService _cloudService;
  final MlKitTranslationService _onDeviceTranslation;
  final GeminiService _onDeviceLLM;
  final LocalStorageService _localStorageService;

  HybridTranslationService({
    SmartHybridRouter? router,
    required AwsCloudService cloudService,
    required LocalStorageService localStorageService,
    MlKitTranslationService? onDeviceTranslation,
    GeminiService? onDeviceLLM,
  })  : _router = router ?? SmartHybridRouter(),
        _cloudService = cloudService,
        _localStorageService = localStorageService,
        _onDeviceTranslation = onDeviceTranslation ?? MlKitTranslationService(),
        _onDeviceLLM = onDeviceLLM ??
            GeminiService(localStorageService: localStorageService);

  /// Translate text with hybrid routing
  Future<HybridTranslationResult> translateText({
    required String sourceText,
    required String sourceLang,
    required String targetLang,
    DataUsagePreference? userPreference,
    String? userId,
  }) async {
    final context = await _router.createContext(
      text: sourceText,
      userPreference: userPreference,
    );

    final backend = await _router.routeTranslation(context);
    final startTime = DateTime.now();

    try {
      if (backend == ProcessingBackend.awsBedrock) {
        // Try AWS Bedrock
        final cloudResult = await _cloudService.translateText(
          sourceText: sourceText,
          sourceLang: sourceLang,
          targetLang: targetLang,
          userId: userId,
        );

        if (cloudResult.success) {
          return HybridTranslationResult(
            translatedText: cloudResult.translatedText,
            confidence: cloudResult.confidence,
            backend: ProcessingBackend.awsBedrock,
            processingTimeMs: cloudResult.processingTimeMs,
            success: true,
          );
        }
        debugPrint('AWS Bedrock translation failed, falling back to Gemini...');
      }

      if (backend == ProcessingBackend.awsBedrock ||
          backend == ProcessingBackend.gemini) {
        // Try Gemini (either as primary choice or fallback from Bedrock)
        try {
          final geminiResult = await _onDeviceLLM.translateText(
            sourceText,
            targetLang,
          );

          final processingTime = DateTime.now().difference(startTime);

          final result = HybridTranslationResult(
            translatedText: geminiResult,
            confidence: 0.90, // Gemini estimated confidence
            backend: ProcessingBackend.gemini,
            processingTimeMs: processingTime.inMilliseconds,
            success: true,
          );

          // Save to local history for sync
          _saveToLocalHistory(
            sourceText: sourceText,
            targetText: geminiResult,
            sourceLang: sourceLang,
            targetLang: targetLang,
            backend: 'gemini',
          );

          return result;
        } catch (e) {
          debugPrint(
              'Gemini translation failed: $e, falling back to ML Kit...');
        }
      }

      // Use ML Kit translation (either as primary choice or fallback from Gemini)
      final onDeviceResult = await _onDeviceTranslation.translate(
        text: sourceText,
        sourceLanguage: sourceLang,
        targetLanguage: targetLang,
      );

      final processingTime = DateTime.now().difference(startTime);
      final translatedText = onDeviceResult ?? '';

      final result = HybridTranslationResult(
        translatedText: translatedText,
        confidence: 0.85, // ML Kit doesn't provide confidence
        backend: ProcessingBackend.mlKit,
        processingTimeMs: processingTime.inMilliseconds,
        success: true,
      );

      // Save to local history for sync
      if (translatedText.isNotEmpty) {
        _saveToLocalHistory(
          sourceText: sourceText,
          targetText: translatedText,
          sourceLang: sourceLang,
          targetLang: targetLang,
          backend: 'ml_kit',
        );
      }

      return result;
    } catch (e) {
      debugPrint('Translation error: $e');
      return HybridTranslationResult(
        translatedText: '',
        confidence: 0.0,
        backend: backend,
        processingTimeMs: DateTime.now().difference(startTime).inMilliseconds,
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Grammar check with hybrid routing
  Future<HybridGrammarResult> checkGrammar({
    required String text,
    required String language,
    DataUsagePreference? userPreference,
    String? userId,
  }) async {
    final context = await _router.createContext(
      text: text,
      userPreference: userPreference,
    );

    final backend = await _router.routeAssistance(context);
    final startTime = DateTime.now();

    try {
      if (backend == ProcessingBackend.awsBedrock) {
        // Try AWS Bedrock first
        final cloudResult = await _cloudService.checkGrammar(
          text: text,
          language: language,
          userId: userId,
        );

        if (cloudResult.success) {
          return HybridGrammarResult(
            response: cloudResult.response,
            corrections: cloudResult.corrections,
            backend: ProcessingBackend.awsBedrock,
            processingTimeMs: cloudResult.processingTimeMs,
            success: true,
          );
        }

        debugPrint('AWS Bedrock grammar check failed, falling back to Gemini');
      }

      // Use Gemini (either as primary choice or fallback)
      final onDeviceResult = await _onDeviceLLM.refineText(
        text,
        style: 'polite', // Default to polite for grammar corrections
      );

      final processingTime = DateTime.now().difference(startTime);

      return HybridGrammarResult(
        response: onDeviceResult,
        corrections: [], // Gemini returns text, not structured corrections
        backend: ProcessingBackend.gemini,
        processingTimeMs: processingTime.inMilliseconds,
        success: true,
      );
    } catch (e) {
      debugPrint('Grammar check error: $e');
      return HybridGrammarResult(
        response: '',
        corrections: [],
        backend: backend,
        processingTimeMs: DateTime.now().difference(startTime).inMilliseconds,
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Simplify text with hybrid routing
  Future<HybridSimplificationResult> simplifyText({
    required String text,
    required String targetComplexity,
    required String language,
    bool includeExplanation = false,
    DataUsagePreference? userPreference,
    String? userId,
  }) async {
    final context = await _router.createContext(
      text: text,
      userPreference: userPreference,
    );

    final backend = await _router.routeSimplification(context);
    final startTime = DateTime.now();

    try {
      if (backend == ProcessingBackend.awsBedrock) {
        // Try AWS Bedrock first
        final cloudResult = await _cloudService.simplifyText(
          text: text,
          targetComplexity: targetComplexity,
          language: language,
          includeExplanation: includeExplanation,
          userId: userId,
        );

        if (cloudResult.success) {
          return HybridSimplificationResult(
            simplifiedText: cloudResult.simplifiedText,
            explanation: cloudResult.explanation,
            backend: ProcessingBackend.awsBedrock,
            processingTimeMs: cloudResult.processingTimeMs,
            success: true,
          );
        }

        debugPrint('AWS Bedrock simplification failed, falling back to Gemini');
      }

      // Use Gemini
      final onDeviceResult = await _onDeviceLLM.explainAndSimplify(
        text,
        simplicity: targetComplexity,
        targetLanguage: language,
      );

      final processingTime = DateTime.now().difference(startTime);

      return HybridSimplificationResult(
        simplifiedText: onDeviceResult,
        explanation: null,
        backend: ProcessingBackend.gemini,
        processingTimeMs: processingTime.inMilliseconds,
        success: true,
      );
    } catch (e) {
      debugPrint('Simplification error: $e');
      return HybridSimplificationResult(
        simplifiedText: '',
        explanation: null,
        backend: backend,
        processingTimeMs: DateTime.now().difference(startTime).inMilliseconds,
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Chat with assistant with hybrid routing
  Future<String> chat({
    required String message,
    List<Map<String, String>>? history,
    String? language,
    DataUsagePreference? userPreference,
    String? userId,
  }) async {
    final context = await _router.createContext(
      text: message,
      history: history,
      userPreference: userPreference,
    );

    final backend = await _router.routeAssistance(context);

    try {
      if (backend == ProcessingBackend.awsBedrock) {
        final response = await _cloudService.practiceConversation(
          userMessage: message,
          language: language ?? 'English',
          conversationHistory: history ?? [],
          userId: userId,
        );
        if (response.success) {
          return response.response;
        }
      }

      // Fallback to Gemini
      final result = await _onDeviceLLM.refineText(message);
      return result;
    } catch (e) {
      debugPrint('Hybrid chat failed, falling back to Gemini');
      try {
        return await _onDeviceLLM.refineText(message);
      } catch (fallbackError) {
        debugPrint('Gemini fallback also failed: $fallbackError');
        return 'Chat service is currently unavailable. Please try again later.';
      }
    }
  }

  /// Explain text with hybrid routing
  Future<Map<String, dynamic>> explainText({
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
    DataUsagePreference? userPreference,
    String? userId,
  }) async {
    final context = await _router.createContext(
      text: text,
      userPreference: userPreference,
    );

    final backend = await _router.routeAssistance(context);

    try {
      if (backend == ProcessingBackend.awsBedrock) {
        try {
          return await _cloudService.explainText(
            text: text,
            targetLanguage: targetLanguage,
            sourceLanguage: sourceLanguage,
            userId: userId,
          );
        } catch (e) {
          debugPrint('AWS Bedrock explain failed, falling back to Gemini');
        }
      }

      // Fallback to Gemini
      final result = await _onDeviceLLM.explainAndSimplify(
        text,
        targetLanguage: targetLanguage,
      );
      return {
        'explanation': result,
        'model': 'gemini-on-device',
        'backend': 'gemini',
      };
    } catch (e) {
      debugPrint('Hybrid explain failed: $e');
      return {
        'explanation': 'Explanation failed to generate.',
        'model': 'error',
        'backend': 'error',
      };
    }
  }

  /// Dispose resources
  void dispose() {
    _router.dispose();
  }

  /// Helper to save offline translations to local history for cloud synchronization
  void _saveToLocalHistory({
    required String sourceText,
    required String targetText,
    required String sourceLang,
    required String targetLang,
    required String backend,
    String? category,
  }) {
    _localStorageService.insertTranslation({
      'originalText': sourceText,
      'translatedText': targetText,
      'sourceLanguage': sourceLang,
      'targetLanguage': targetLang,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'isSynced': 0, // Mark for sync
      'category': category ?? 'General',
    }).catchError((e) {
      debugPrint('Error saving local history for sync: $e');
      return 0;
    });
  }
}

/// Result classes for hybrid operations

class HybridTranslationResult {
  final String translatedText;
  final double confidence;
  final ProcessingBackend backend;
  final int processingTimeMs;
  final bool success;
  final String? error;

  HybridTranslationResult({
    required this.translatedText,
    required this.confidence,
    required this.backend,
    required this.processingTimeMs,
    required this.success,
    this.error,
  });
}

class HybridGrammarResult {
  final String response;
  final List<Map<String, dynamic>> corrections;
  final ProcessingBackend backend;
  final int processingTimeMs;
  final bool success;
  final String? error;

  HybridGrammarResult({
    required this.response,
    required this.corrections,
    required this.backend,
    required this.processingTimeMs,
    required this.success,
    this.error,
  });
}

class HybridSimplificationResult {
  final String simplifiedText;
  final String? explanation;
  final ProcessingBackend backend;
  final int processingTimeMs;
  final bool success;
  final String? error;

  HybridSimplificationResult({
    required this.simplifiedText,
    this.explanation,
    required this.backend,
    required this.processingTimeMs,
    required this.success,
    this.error,
  });
}
