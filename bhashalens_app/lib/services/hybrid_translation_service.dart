import 'package:bhashalens_app/models/translation_history_entry.dart';
import 'package:bhashalens_app/services/smart_hybrid_router.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'ml_kit_translation_service.dart';
import 'gemini_service.dart';
import 'local_storage_service.dart';
import 'package:bhashalens_app/debug_session_log.dart';

/// Unified translation service that routes between on-device and cloud
class HybridTranslationService {
  final MlKitTranslationService _onDeviceTranslation;
  final GeminiService _onDeviceLLM;
  final LocalStorageService _localStorageService;

  HybridTranslationService({
    required LocalStorageService localStorageService,
    MlKitTranslationService? onDeviceTranslation,
    GeminiService? onDeviceLLM,
  })  : _localStorageService = localStorageService,
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
    debugPrint('HybridTranslationService: Translating text: $sourceText');
    // Determine if we should use offline ML Kit or online Gemini
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOffline = connectivityResult.contains(ConnectivityResult.none);

    final backend =
        isOffline ? ProcessingBackend.mlKit : ProcessingBackend.gemini;
    debugPrint('HybridTranslationService: Decision: ${backend.name}');
    final startTime = DateTime.now();
    // #region agent log
    DebugSessionLog.log(
      'hybrid_translation_service.dart:translateText',
      'backend_routed',
      data: {'backend': backend.name},
      hypothesisId: 'H3',
    );
    // #endregion

    try {
      if (backend == ProcessingBackend.gemini) {
        // Strictly use Gemini as requested by the user
        debugPrint(
            'HybridTranslationService: Executing Gemini Translation (Strict Mode)');
        try {
          final geminiResult = await _onDeviceLLM.translateText(
            sourceText,
            targetLang,
            sourceLanguage: sourceLang, // Pass source lang if available
          );

          final processingTime = DateTime.now().difference(startTime);

          final result = HybridTranslationResult(
            translatedText: geminiResult,
            confidence: 0.95, // Improved confidence estimate for Gemini
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
          debugPrint('Gemini translation failed: $e');
          // Fall back to ML Kit if Gemini fails, unless it's strictly online-only
        }
      }

      // On web, ML Kit is unavailable — return error instead of silent failure
      if (kIsWeb) {
        return HybridTranslationResult(
          translatedText: '',
          confidence: 0.0,
          backend: ProcessingBackend.gemini,
          processingTimeMs: DateTime.now().difference(startTime).inMilliseconds,
          success: false,
          error: 'Translation failed. Please check your internet connection and try again.',
        );
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

      // #region agent log
      DebugSessionLog.log(
        'hybrid_translation_service.dart:translateText',
        'translate_done',
        data: {'backend': 'mlKit', 'success': translatedText.isNotEmpty},
        hypothesisId: 'H3',
      );
      // #endregion
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
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOffline = connectivityResult.contains(ConnectivityResult.none);
    final backend =
        isOffline ? ProcessingBackend.mlKit : ProcessingBackend.gemini;
    final startTime = DateTime.now();

    try {
      // Use Gemini (Strict Mode for Online)
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
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOffline = connectivityResult.contains(ConnectivityResult.none);

    final startTime = DateTime.now();
    try {
      // Strictly use Gemini for online, or provide info if offline
      if (isOffline) {
        return HybridSimplificationResult(
          simplifiedText:
              'Simplification requires an internet connection for advanced processing. Please connect and try again.',
          explanation: null,
          backend: ProcessingBackend.mlKit,
          processingTimeMs: 0,
          success: false,
          error: 'Offline',
        );
      }

      debugPrint(
          'HybridTranslationService: Executing Gemini Simplification (Strict Mode)');
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
        backend: ProcessingBackend.gemini,
        processingTimeMs: DateTime.now().difference(startTime).inMilliseconds,
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Chat with assistant with hybrid routing
  Future<HybridChatResult> chat({
    required String message,
    List<Map<String, String>>? history,
    String? language,
    DataUsagePreference? userPreference,
    String? userId,
  }) async {
    try {
      // Strictly use Gemini
      debugPrint('HybridTranslationService: Executing Gemini Chat (Strict Mode)');
      final result = await _onDeviceLLM.refineText(message);
      return HybridChatResult(
        response: result,
        backend: ProcessingBackend.gemini,
        success: true,
      );
    } catch (e) {
      debugPrint('Hybrid chat failed, falling back to Gemini');
      try {
        final result = await _onDeviceLLM.refineText(message);
        return HybridChatResult(
          response: result,
          backend: ProcessingBackend.gemini,
          success: true,
        );
      } catch (fallbackError) {
        debugPrint('Gemini fallback also failed: $fallbackError');
        return HybridChatResult(
          response:
              'Chat service is currently unavailable. Please try again later.',
          backend: ProcessingBackend.error,
          success: false,
          error: fallbackError.toString(),
        );
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
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOffline = connectivityResult.contains(ConnectivityResult.none);

    try {
      if (isOffline) {
        throw Exception('Explanation requires an internet connection.');
      }

      // Strictly use Gemini
      debugPrint('HybridTranslationService: Executing Gemini Explain (Strict Mode)');
      final jsonResponse = await _onDeviceLLM.explainTextWithContext(
        text,
        targetLanguage: targetLanguage,
        sourceLanguage: sourceLanguage,
      );

      jsonResponse['model'] = 'gemini-strict';
      jsonResponse['backend'] = 'gemini';
      if (!jsonResponse.containsKey('translation') ||
          jsonResponse['translation'] == null) {
        jsonResponse['translation'] = 'N/A';
      }
      if (!jsonResponse.containsKey('meaning') ||
          jsonResponse['meaning'] == null) {
        jsonResponse['meaning'] = jsonResponse.containsKey('explanation')
            ? jsonResponse['explanation']
            : 'Meaning unavailable.';
      }

      return jsonResponse;
    } catch (e) {
      debugPrint('Hybrid explain failed: $e');
      return {
        'explanation': 'Explanation failed to generate.',
        'model': 'error',
        'backend': 'error',
      };
    }
  }

  /// High-level orchestration for complex AI tasks (Claude + Gemini)
  Future<HybridOrchestrationResult> orchestrate({
    required String text,
    required String mode,
    required String language,
    String? complexity,
    String? situationalContext,
    DataUsagePreference? userPreference,
    String? userId,
  }) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOffline = connectivityResult.contains(ConnectivityResult.none);

    final startTime = DateTime.now();
    try {
      if (isOffline) {
        return HybridOrchestrationResult(
          response: 'Orchestration requires an internet connection.',
          claudeBase: 'N/A',
          backend: ProcessingBackend.mlKit,
          processingTimeMs: 0,
          success: false,
          error: 'Offline',
        );
      }

      // Strictly use Gemini
      debugPrint(
          'HybridTranslationService: Executing Gemini Orchestration (Strict Mode) - mode=$mode, language=$language');
      String resultText = '';

      if (mode == 'explain') {
        final explanation = await _onDeviceLLM.explainTextWithContext(text,
            targetLanguage: language);
        // Return the full rich explanation
        resultText = explanation['meaning'] ??
            explanation['explanation'] ??
            'Explanation unavailable.';
      } else if (mode == 'simplify') {
        resultText = await _onDeviceLLM.explainAndSimplify(text,
            simplicity: complexity ?? 'simple', targetLanguage: language);
      } else {
        resultText = await _onDeviceLLM.refineText(text);
      }

      debugPrint('Gemini orchestration result (${resultText.length} chars)');

      return HybridOrchestrationResult(
        response: resultText,
        claudeBase: 'N/A (Strict Gemini)',
        backend: ProcessingBackend.gemini,
        processingTimeMs: DateTime.now().difference(startTime).inMilliseconds,
        success: true,
      );
    } catch (e) {
      debugPrint('Hybrid orchestration failed: $e');
      return HybridOrchestrationResult(
        response: 'Service unavailable.',
        claudeBase: '',
        backend: ProcessingBackend.gemini,
        processingTimeMs: 0,
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Dispose resources
  void dispose() {
    // No-op
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

/// Result of hybrid chat with backend indicator
class HybridChatResult {
  final String response;
  final ProcessingBackend backend;
  final bool success;
  final String? error;

  HybridChatResult({
    required this.response,
    required this.backend,
    required this.success,
    this.error,
  });
}

class HybridOrchestrationResult {
  final String response;
  final String claudeBase;
  final ProcessingBackend backend;
  final int processingTimeMs;
  final bool success;
  final String? error;

  HybridOrchestrationResult({
    required this.response,
    required this.claudeBase,
    required this.backend,
    required this.processingTimeMs,
    required this.success,
    this.error,
  });
}
