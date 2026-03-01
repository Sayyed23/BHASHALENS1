import 'package:flutter/foundation.dart';
import 'package:bhashalens_app/models/language_pair.dart';
import 'package:bhashalens_app/models/translation_result.dart';
import 'package:bhashalens_app/models/translation_history_entry.dart';
import 'package:bhashalens_app/models/cached_translation.dart';
import 'package:bhashalens_app/services/translation_engine.dart';
import 'package:bhashalens_app/services/tflite_translation_engine.dart';
import 'package:bhashalens_app/services/local_storage_service.dart';

/// Offline translation service with caching and history management
/// Integrates TranslationEngine with LocalStorage for production-ready offline translation
class OfflineTranslationService {
  final TranslationEngine _engine;
  final LocalStorageService _storage;

  // Singleton pattern
  static final OfflineTranslationService _instance =
      OfflineTranslationService._internal(
    TFLiteTranslationEngine(),
    LocalStorageService(),
  );

  factory OfflineTranslationService() => _instance;

  OfflineTranslationService._internal(this._engine, this._storage);

  /// Translate text with caching and history
  Future<TranslationResult> translate({
    required String text,
    required Language sourceLang,
    required Language targetLang,
    bool saveToHistory = true,
    bool useCache = true,
  }) async {
    try {
      // Check cache first if enabled
      if (useCache) {
        final cached = await _storage.getCachedTranslation(
          sourceText: text,
          sourceLang: sourceLang,
          targetLang: targetLang,
        );

        if (cached != null) {
          debugPrint('Using cached translation');
          return TranslationResult(
            translatedText: cached.translatedText,
            confidence: cached.confidence,
            processingTimeMs: 0,
            backend: ProcessingBackend.onDevice,
            success: true,
          );
        }
      }

      // Perform translation
      final result = await _engine.translate(
        text: text,
        sourceLang: sourceLang,
        targetLang: targetLang,
      );

      if (!result.success) {
        return result;
      }

      // Cache the result
      if (useCache) {
        await _storage.cacheTranslation(
          sourceText: text,
          sourceLang: sourceLang,
          targetLang: targetLang,
          translatedText: result.translatedText,
          confidence: result.confidence,
        );
      }

      // Save to history if enabled
      if (saveToHistory) {
        await _storage.saveTranslation(
          TranslationHistoryEntry(
            sourceText: text,
            translatedText: result.translatedText,
            sourceLang: sourceLang,
            targetLang: targetLang,
            mode: TranslationMode.text,
            backend: result.backend,
            confidence: result.confidence,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      }

      return result;
    } catch (e) {
      debugPrint('Translation service error: $e');
      return TranslationResult.failure(
        error: e.toString(),
        backend: ProcessingBackend.onDevice,
        processingTimeMs: 0,
      );
    }
  }

  /// Initialize translation engine for a language pair
  Future<void> initializeLanguagePair(LanguagePair pair) async {
    await _engine.initialize(pair);
  }

  /// Check if a language pair is available
  Future<bool> isLanguagePairAvailable(LanguagePair pair) async {
    return await _engine.isLanguagePairAvailable(pair);
  }

  /// Get all supported language pairs
  List<LanguagePair> getSupportedLanguagePairs() {
    return _engine.getSupportedLanguagePairs();
  }

  /// Get translation history
  Future<List<TranslationHistoryEntry>> getHistory({
    int limit = 100,
    int offset = 0,
  }) async {
    return await _storage.getTranslationHistory(
      limit: limit,
      offset: offset,
    );
  }

  /// Search translation history
  Future<List<TranslationHistoryEntry>> searchHistory(String query) async {
    return await _storage.searchTranslationHistory(query);
  }

  /// Clear translation history
  Future<void> clearHistory({int? beforeTimestamp}) async {
    await _storage.deleteTranslationHistory(beforeTimestamp: beforeTimestamp);
  }

  /// Get model size for a language pair
  Future<int> getModelSize(LanguagePair pair) async {
    return await _engine.getModelSize(pair);
  }

  /// Check if model is loaded in memory
  bool isModelLoaded(LanguagePair pair) {
    return _engine.isModelLoaded(pair);
  }

  /// Release resources
  void dispose() {
    _engine.release();
  }
}
