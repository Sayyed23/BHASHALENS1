import 'package:flutter/foundation.dart';
import 'smart_hybrid_router.dart';
import 'aws_cloud_service.dart';
import 'ml_kit_translation_service.dart';
import 'gemini_service.dart';

/// Unified translation service that routes between on-device and cloud
class HybridTranslationService {
  final SmartHybridRouter _router;
  final AwsCloudService _cloudService;
  final MlKitTranslationService _onDeviceTranslation;
  final GeminiService _onDeviceLLM;

  HybridTranslationService({
    SmartHybridRouter? router,
    AwsCloudService? cloudService,
    MlKitTranslationService? onDeviceTranslation,
    GeminiService? onDeviceLLM,
  })  : _router = router ?? SmartHybridRouter(),
        _cloudService = cloudService ?? AwsCloudService(),
        _onDeviceTranslation = onDeviceTranslation ?? MlKitTranslationService(),
        _onDeviceLLM = onDeviceLLM ?? GeminiService();

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
        // Try cloud first
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

        // Cloud failed, fall back to on-device
        debugPrint('Cloud translation failed, falling back to on-device');
      }

      // Use on-device translation
      final onDeviceResult = await _onDeviceTranslation.translateText(
        sourceText,
        sourceLang,
        targetLang,
      );

      final processingTime = DateTime.now().difference(startTime);

      return HybridTranslationResult(
        translatedText: onDeviceResult,
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
      final prompt = 'Check the grammar of the following $language text and '
          'provide corrections:\n\n$text';
      final onDeviceResult = await _onDeviceLLM.generateContent(prompt);

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
      final prompt = 'Simplify the following $language text to a '
          '$targetComplexity level:\n\n$text';
      final onDeviceResult = await _onDeviceLLM.generateContent(prompt);

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
