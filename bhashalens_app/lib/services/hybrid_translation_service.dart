import 'package:flutter/foundation.dart';
import 'smart_hybrid_router.dart';
import 'aws_cloud_service.dart';
import 'ml_kit_translation_service.dart';
import 'gemini_service.dart';
import 'sarvam_service.dart';
import 'local_storage_service.dart';

/// Unified translation service that routes between on-device and cloud
class HybridTranslationService {
  final SmartHybridRouter _router;
  final AwsCloudService _cloudService;
  final SarvamService _sarvamService;
  final MlKitTranslationService _onDeviceTranslation;
  final GeminiService _onDeviceLLM;

  HybridTranslationService({
    SmartHybridRouter? router,
    required AwsCloudService cloudService,
    required SarvamService sarvamService,
    required LocalStorageService localStorageService,
    MlKitTranslationService? onDeviceTranslation,
    GeminiService? onDeviceLLM,
  })  : _router = router ?? SmartHybridRouter(),
        _cloudService = cloudService,
        _sarvamService = sarvamService,
        _onDeviceTranslation = onDeviceTranslation ?? MlKitTranslationService(),
        _onDeviceLLM = onDeviceLLM ?? GeminiService(localStorageService: localStorageService);

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
      if (backend == ProcessingBackend.awsCloud) {
        // Try AWS cloud
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
            backend: ProcessingBackend.awsCloud,
            processingTimeMs: cloudResult.processingTimeMs,
            success: true,
          );
        }
        debugPrint('AWS Cloud translation failed, falling back...');
      } else if (backend == ProcessingBackend.sarvam) {
        // Try Sarvam cloud
        try {
          final sarvamResult = await _sarvamService.translateText(
            sourceText,
            _sarvamService.mapLanguageCode(targetLang),
            sourceLanguage: sourceLang == 'auto' ? null : _sarvamService.mapLanguageCode(sourceLang),
          );

          final processingTime = DateTime.now().difference(startTime);

          return HybridTranslationResult(
            translatedText: sarvamResult,
            confidence: 0.95,
            backend: ProcessingBackend.sarvam,
            processingTimeMs: processingTime.inMilliseconds,
            success: true,
          );
        } catch (e) {
          debugPrint('Sarvam translation failed: $e');
        }
      }

      // Use on-device translation
      final onDeviceResult = await _onDeviceTranslation.translate(
        text: sourceText,
        sourceLanguage: sourceLang,
        targetLanguage: targetLang,
      );

      final processingTime = DateTime.now().difference(startTime);

      return HybridTranslationResult(
        translatedText: onDeviceResult ?? '',
        confidence: 0.85, // ML Kit doesn't provide confidence
        backend: ProcessingBackend.onDevice,
        processingTimeMs: processingTime.inMilliseconds,
        success: true,
      );
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
      if (backend == ProcessingBackend.awsCloud) {
        // Try cloud first
        final cloudResult = await _cloudService.checkGrammar(
          text: text,
          language: language,
          userId: userId,
        );

        if (cloudResult.success) {
          return HybridGrammarResult(
            response: cloudResult.response,
            corrections: cloudResult.corrections,
            backend: ProcessingBackend.awsCloud,
            processingTimeMs: cloudResult.processingTimeMs,
            success: true,
          );
        }

        debugPrint('Cloud grammar check failed, falling back to on-device');
      }

      // Use on-device LLM (Gemini)
      final onDeviceResult = await _onDeviceLLM.refineText(
        text,
        style: 'polite', // Default to polite for grammar corrections
      );

      final processingTime = DateTime.now().difference(startTime);

      return HybridGrammarResult(
        response: onDeviceResult,
        corrections: [], // Gemini returns text, not structured corrections
        backend: ProcessingBackend.onDevice,
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
      if (backend == ProcessingBackend.awsCloud) {
        // Try cloud first
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
            backend: ProcessingBackend.awsCloud,
            processingTimeMs: cloudResult.processingTimeMs,
            success: true,
          );
        }

        debugPrint('Cloud simplification failed, falling back to on-device');
      }

      // Use on-device LLM (Gemini)
      final onDeviceResult = await _onDeviceLLM.explainAndSimplify(
        text,
        simplicity: targetComplexity,
        targetLanguage: language,
      );

      final processingTime = DateTime.now().difference(startTime);

      return HybridSimplificationResult(
        simplifiedText: onDeviceResult,
        explanation: null,
        backend: ProcessingBackend.onDevice,
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
      if (backend == ProcessingBackend.awsCloud) {
        final response = await _cloudService.practiceConversation(
          userMessage: message,
          language: language ?? 'English',
          conversationHistory: history ?? [],
          userId: userId,
        );
        return response.success ? response.response : 'Error in cloud conversation';
      } else if (backend == ProcessingBackend.sarvam) {
        return await _sarvamService.chatWithAssistant(message, history: history);
      }

      // On-device fallback
      final result = await _onDeviceLLM.refineText(message);
      return result;
    } catch (e) {
      debugPrint('Hybrid chat failed, falling back to Sarvam');
      return await _sarvamService.chatWithAssistant(message, history: history);
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
      if (backend == ProcessingBackend.awsCloud) {
        return await _cloudService.explainText(
          text: text,
          targetLanguage: targetLanguage,
          sourceLanguage: sourceLanguage,
          userId: userId,
        );
      } else if (backend == ProcessingBackend.sarvam) {
        return await _sarvamService.explainText(
          text,
          targetLanguage: _sarvamService.mapLanguageCode(targetLanguage),
          sourceLanguage: sourceLanguage != null ? _sarvamService.mapLanguageCode(sourceLanguage) : null,
        );
      }

      // On-device fallback
      final result = await _onDeviceLLM.explainAndSimplify(
        text,
        targetLanguage: targetLanguage,
      );
      return {
        'explanation': result,
        'model': 'gemini-on-device',
        'backend': 'onDevice',
      };
    } catch (e) {
      debugPrint('Hybrid explain failed, falling back to Sarvam');
      return await _sarvamService.explainText(
        text,
        targetLanguage: _sarvamService.mapLanguageCode(targetLanguage),
        sourceLanguage: sourceLanguage != null ? _sarvamService.mapLanguageCode(sourceLanguage) : null,
      );
    }
  }

  /// Dispose resources
  void dispose() {
    _router.dispose();
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
