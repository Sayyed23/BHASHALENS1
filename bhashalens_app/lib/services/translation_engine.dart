import 'package:bhashalens_app/models/language_pair.dart';
import 'package:bhashalens_app/models/translation_result.dart';

/// Abstract interface for translation engines
/// Supports offline-first translation with quantized models
abstract class TranslationEngine {
  /// Initialize the engine with a specific language pair
  /// Downloads and loads the model if not already available
  Future<void> initialize(LanguagePair languagePair);

  /// Translate text from source to target language
  /// Returns TranslationResult with translated text and metadata
  Future<TranslationResult> translate({
    required String text,
    required Language sourceLang,
    required Language targetLang,
  });

  /// Check if a language pair is available for translation
  /// Returns true if the model is downloaded and ready
  Future<bool> isLanguagePairAvailable(LanguagePair pair);

  /// Get list of all supported language pairs
  List<LanguagePair> getSupportedLanguagePairs();

  /// Release resources and cleanup
  void release();

  /// Get model size for a language pair (in bytes)
  Future<int> getModelSize(LanguagePair pair);

  /// Check if model is currently loaded in memory
  bool isModelLoaded(LanguagePair pair);
}
