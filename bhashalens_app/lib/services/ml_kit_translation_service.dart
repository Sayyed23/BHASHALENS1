import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';

class MlKitTranslationService {
  // Singleton pattern
  static final MlKitTranslationService _instance =
      MlKitTranslationService._internal();

  factory MlKitTranslationService() {
    return _instance;
  }

  MlKitTranslationService._internal();

  final _modelManager = OnDeviceTranslatorModelManager();
  final _languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);

  /// Translates text from source language to target language.
  /// Returns null if translation fails.
  /// Note: ML Kit models are primarily designed for translation TO English.
  /// For non-English to non-English translation, we use a two-step process via English.
  Future<String?> translate({
    required String text,
    required String sourceLanguage, // e.g., 'en', 'hi'
    required String targetLanguage,
  }) async {
    try {
      final sourceLang = _getTranslateLanguage(sourceLanguage);
      final targetLang = _getTranslateLanguage(targetLanguage);

      if (sourceLang == null || targetLang == null) {
        debugPrint('Unsupported language: $sourceLanguage -> $targetLanguage');
        return null; // Unsupported language
      }

      // If source and target are the same, return original text
      if (sourceLang == targetLang) {
        return text;
      }

      // Check if both models are available
      // (These were previously checked here, but now checked inside the translation paths for better logging)

      // Direct translation (works best when one language is English)
      if (sourceLang == TranslateLanguage.english ||
          targetLang == TranslateLanguage.english) {
        // Check if the non-English model is available
        final nonEnglishLang = sourceLang == TranslateLanguage.english
            ? targetLanguage
            : sourceLanguage;

        if (!(await isModelDownloaded(nonEnglishLang))) {
          debugPrint(
              'ML Kit: Model NOT downloaded for non-English language: $nonEnglishLang');
          return null;
        }

        debugPrint(
            'ML Kit: Starting direct translation ($sourceLanguage -> $targetLanguage)');
        final onDeviceTranslator = OnDeviceTranslator(
          sourceLanguage: sourceLang,
          targetLanguage: targetLang,
        );

        final String response = await onDeviceTranslator.translateText(text);
        await onDeviceTranslator.close();
        debugPrint(
            'ML Kit: Direct translation success. Result length: ${response.length}');
        return response;
      }

      // For non-English to non-English translation, use two-step process via English
      debugPrint(
          'ML Kit: Starting two-step translation ($sourceLanguage -> en -> $targetLanguage)');

      // Step 1: Source language -> English
      if (!(await isModelDownloaded(sourceLanguage))) {
        debugPrint('ML Kit: Source model not downloaded: $sourceLanguage');
        return null;
      }

      final toEnglishTranslator = OnDeviceTranslator(
        sourceLanguage: sourceLang,
        targetLanguage: TranslateLanguage.english,
      );

      final englishText = await toEnglishTranslator.translateText(text);
      await toEnglishTranslator.close();

      if (englishText.isEmpty) {
        debugPrint(
            'ML Kit: Failed to translate to intermediate English: $sourceLanguage -> en');
        return null;
      }
      debugPrint(
          'ML Kit: Intermediate English translation success. Length: ${englishText.length}');

      // Step 2: English -> Target language
      if (!(await isModelDownloaded(targetLanguage))) {
        debugPrint('ML Kit: Target model not downloaded: $targetLanguage');
        return null;
      }

      if (!(await isModelDownloaded('en'))) {
        debugPrint(
            'ML Kit: English model not downloaded (required for intermediate step)');
        return null;
      }

      final fromEnglishTranslator = OnDeviceTranslator(
        sourceLanguage: TranslateLanguage.english,
        targetLanguage: targetLang,
      );

      final finalResult =
          await fromEnglishTranslator.translateText(englishText);
      await fromEnglishTranslator.close();
      debugPrint(
          'ML Kit: Final step translation success ($sourceLanguage -> $targetLanguage). Result length: ${finalResult.length}');

      return finalResult;
    } catch (e) {
      debugPrint(
          'Error translating with ML Kit ($sourceLanguage -> $targetLanguage): $e');
      return null;
    }
  }

  /// Extracts text from image file using ML Kit Text Recognition.
  /// Uses script-specific recognizers for best accuracy.
  /// For languages without native OCR script support (Tamil, Telugu, etc.),
  /// tries multiple recognizers and picks the best result.
  Future<String> extractTextFromFile(File file,
      {String languageCode = 'en'}) async {
    try {
      final inputImage = InputImage.fromFile(file);
      final script = _getScriptForLanguage(languageCode);

      // If the language has native script support, use it directly
      if (script != null) {
        return await _recognizeWithScript(inputImage, script);
      }

      // For unsupported scripts (Tamil, Telugu, etc.), try multiple recognizers
      // and pick the result with the most text extracted
      debugPrint(
          'No native OCR script for $languageCode, trying fallback recognizers');

      final results = <String>[];

      // Try Devanagari (closest Indic script recognizer)
      final devanagariResult = await _recognizeWithScript(
          inputImage, TextRecognitionScript.devanagiri);
      if (devanagariResult.isNotEmpty &&
          !devanagariResult.startsWith('Error')) {
        results.add(devanagariResult);
      }

      // Try Latin (works for transliterated text)
      final latinResult =
          await _recognizeWithScript(inputImage, TextRecognitionScript.latin);
      if (latinResult.isNotEmpty && !latinResult.startsWith('Error')) {
        results.add(latinResult);
      }

      if (results.isEmpty) {
        return '';
      }

      // Return the result with the most extracted text
      results.sort((a, b) => b.length.compareTo(a.length));
      return results.first;
    } catch (e) {
      debugPrint('Error extracting text from file: $e');
      return 'Error extracting text';
    }
  }

  /// Recognize text from an image using a specific script recognizer.
  Future<String> _recognizeWithScript(
      InputImage inputImage, TextRecognitionScript script) async {
    final recognizer = TextRecognizer(script: script);
    try {
      final result = await recognizer.processImage(inputImage);
      final text = result.text.trim();
      return text;
    } catch (e) {
      debugPrint('Error with script $script: $e');
      return '';
    } finally {
      await recognizer.close();
    }
  }

  /// Returns the appropriate TextRecognitionScript for a given language code.
  /// Returns null if the language's script is not natively supported by ML Kit.
  /// ML Kit supports: Latin, Devanagari, Chinese, Japanese, Korean.
  /// Tamil, Telugu, Bengali, Gujarati, Kannada scripts are NOT natively supported.
  TextRecognitionScript? _getScriptForLanguage(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'hi': // Hindi
      case 'mr': // Marathi
      case 'sa': // Sanskrit
        return TextRecognitionScript.devanagiri;
      case 'zh': // Chinese
        return TextRecognitionScript.chinese;
      case 'ja': // Japanese
        return TextRecognitionScript.japanese;
      case 'ko': // Korean
        return TextRecognitionScript.korean;
      case 'ru': // Russian uses Cyrillic, ML Kit lacks a dedicated Cyrillic recognizer
      case 'ar': // Arabic
        return null; // Trigger multi-recognizer fallback
      // Latin-script languages
      case 'en':
      case 'es':
      case 'fr':
      case 'de':
      case 'it':
      case 'pt':
        return TextRecognitionScript.latin;
      // Indian languages without native OCR script support
      case 'ta': // Tamil
      case 'te': // Telugu
      case 'bn': // Bengali
      case 'gu': // Gujarati
      case 'kn': // Kannada
      case 'pa': // Punjabi
      case 'ml': // Malayalam
      case 'ur': // Urdu
        return null; // Will trigger multi-recognizer fallback
      default:
        return TextRecognitionScript.latin;
    }
  }

  /// Check if a language has native OCR script support in ML Kit.
  /// Languages without native support will use fallback recognizers.
  bool isOcrScriptSupported(String languageCode) {
    return _getScriptForLanguage(languageCode) != null;
  }

  /// Release resources
  Future<void> dispose() async {
    await _languageIdentifier.close();
  }

  /// Identifies the language of the given text offline.
  /// Returns the language code (e.g., 'en', 'hi') or 'und' if unidentified.
  Future<String> identifyLanguage(String text) async {
    try {
      if (text.trim().isEmpty) return 'und';
      final languageCode = await _languageIdentifier.identifyLanguage(text);
      debugPrint('ML Kit Offline Identified Language: $languageCode');
      return languageCode;
    } catch (e) {
      debugPrint('Error identifying language with ML Kit: $e');
      return 'und';
    }
  }

  /// Downloads the translation model for the given language code.
  /// Also ensures English model is available for bidirectional translation.
  Future<bool> downloadModel(String languageCode) async {
    try {
      final lang = _getTranslateLanguage(languageCode);
      if (lang == null) return false;

      // Always ensure English model is available for two-step translation
      if (lang != TranslateLanguage.english) {
        final englishAvailable = await isModelDownloaded('en');
        if (!englishAvailable) {
          debugPrint('Downloading English model for bidirectional translation');
          await _modelManager.downloadModel('en');
        }
      }

      final success = await _modelManager.downloadModel(_getBcp47Code(lang));
      if (success) {
        debugPrint('Successfully downloaded model for $languageCode');
      } else {
        debugPrint('Failed to download model for $languageCode');
      }

      return success;
    } catch (e) {
      debugPrint('Error downloading model for $languageCode: $e');
      return false;
    }
  }

  /// Deletes the translation model for the given language code.
  Future<bool> deleteModel(String languageCode) async {
    try {
      final lang = _getTranslateLanguage(languageCode);
      if (lang == null) return false;

      return await _modelManager.deleteModel(_getBcp47Code(lang));
    } catch (e) {
      debugPrint('Error deleting model for $languageCode: $e');
      return false;
    }
  }

  /// Checks if bidirectional translation is possible between two languages.
  Future<bool> canTranslateBidirectionally(
      String sourceLanguage, String targetLanguage) async {
    try {
      final sourceLang = _getTranslateLanguage(sourceLanguage);
      final targetLang = _getTranslateLanguage(targetLanguage);

      if (sourceLang == null || targetLang == null) {
        return false;
      }

      // If either language is English, only need one model
      if (sourceLang == TranslateLanguage.english ||
          targetLang == TranslateLanguage.english) {
        final nonEnglishLang = sourceLang == TranslateLanguage.english
            ? targetLanguage
            : sourceLanguage;
        return await isModelDownloaded(nonEnglishLang);
      }

      // For non-English to non-English, need both models plus English
      final sourceAvailable = await isModelDownloaded(sourceLanguage);
      final targetAvailable = await isModelDownloaded(targetLanguage);
      final englishAvailable = await isModelDownloaded('en');

      return sourceAvailable && targetAvailable && englishAvailable;
    } catch (e) {
      debugPrint('Error checking bidirectional translation capability: $e');
      return false;
    }
  }

  /// Gets missing models required for bidirectional translation.
  Future<List<String>> getMissingModelsForTranslation(
      String sourceLanguage, String targetLanguage) async {
    final missingModels = <String>[];

    try {
      final sourceLang = _getTranslateLanguage(sourceLanguage);
      final targetLang = _getTranslateLanguage(targetLanguage);

      if (sourceLang == null || targetLang == null) {
        return missingModels;
      }

      // Check source model
      if (!(await isModelDownloaded(sourceLanguage))) {
        missingModels.add(sourceLanguage);
      }

      // Check target model (skip if same as source to avoid duplicates)
      if (sourceLanguage != targetLanguage &&
          !(await isModelDownloaded(targetLanguage))) {
        missingModels.add(targetLanguage);
      }

      // For non-English to non-English translation, English is required
      if (sourceLang != TranslateLanguage.english &&
          targetLang != TranslateLanguage.english &&
          !(await isModelDownloaded('en')) &&
          !missingModels.contains('en')) {
        missingModels.add('en');
      }

      return missingModels;
    } catch (e) {
      debugPrint('Error getting missing models: $e');
      return missingModels;
    }
  }

  Future<bool> isModelDownloaded(String languageCode) async {
    try {
      final lang = _getTranslateLanguage(languageCode);
      if (lang == null) {
        debugPrint(
            'isModelDownloaded: Unsupported language code: $languageCode');
        return false;
      }

      final bcpCode = _getBcp47Code(lang);
      if (bcpCode.isEmpty) {
        debugPrint('isModelDownloaded: No BCP47 mapping for $lang');
        return false;
      }

      final isDownloaded = await _modelManager.isModelDownloaded(bcpCode);
      debugPrint(
          'isModelDownloaded: $languageCode ($bcpCode) -> $isDownloaded');
      return isDownloaded;
    } catch (e) {
      debugPrint('Error checking model status for $languageCode: $e');
      return false;
    }
  }

  /// Returns a list of language codes for downloaded models.
  Future<List<String>> getDownloadedModels() async {
    try {
      // Iterate over supported languages and check status
      final List<String> downloaded = [];
      // Use a set of BCP47 codes we care about to avoid redundant checks
      final codesToCheck = <String>{};
      for (var l in getSupportedLanguages()) {
        final lang = _getTranslateLanguage(l['code']!);
        if (lang != null) {
          final bcp = _getBcp47Code(lang);
          if (bcp.isNotEmpty) codesToCheck.add(bcp);
        }
      }

      for (var bcp in codesToCheck) {
        if (await _modelManager.isModelDownloaded(bcp)) {
          downloaded.add(bcp);
        }
      }
      return downloaded;
    } catch (e) {
      debugPrint('Error getting downloaded models: $e');
      return [];
    }
  }

  /// Helper to map string codes to TranslateLanguage enum.
  TranslateLanguage? _getTranslateLanguage(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'en':
      case 'english':
        return TranslateLanguage.english;
      case 'hi':
      case 'hindi':
        return TranslateLanguage.hindi;
      case 'mr':
      case 'marathi':
        return TranslateLanguage.marathi;
      case 'ta':
      case 'tamil':
        return TranslateLanguage.tamil;
      case 'te':
      case 'telugu':
        return TranslateLanguage.telugu;
      case 'bn':
      case 'bengali':
        return TranslateLanguage.bengali;
      case 'gu':
      case 'gujarati':
        return TranslateLanguage.gujarati;
      case 'kn':
      case 'kannada':
        return TranslateLanguage.kannada;
      case 'ur':
      case 'urdu':
        return TranslateLanguage.urdu;
      case 'es':
      case 'spanish':
        return TranslateLanguage.spanish;
      case 'fr':
      case 'french':
        return TranslateLanguage.french;
      case 'de':
      case 'german':
        return TranslateLanguage.german;
      case 'it':
      case 'italian':
        return TranslateLanguage.italian;
      case 'pt':
      case 'portuguese':
        return TranslateLanguage.portuguese;
      case 'ru':
      case 'russian':
        return TranslateLanguage.russian;
      case 'ja':
      case 'japanese':
        return TranslateLanguage.japanese;
      case 'ko':
      case 'korean':
        return TranslateLanguage.korean;
      case 'zh':
      case 'chinese':
        return TranslateLanguage.chinese;
      case 'ar':
      case 'arabic':
        return TranslateLanguage.arabic;
      case 'pa':
      case 'punjabi':
        // Punjabi is not supported for offline translation in ML Kit
        return null;
      case 'ml':
      case 'malayalam':
        // Malayalam is not supported for offline translation in ML Kit
        return null;
      default:
        // Try to find by BCP47 code
        for (var lang in TranslateLanguage.values) {
          if (_getBcp47Code(lang) == languageCode) {
            return lang;
          }
        }
        return null;
    }
  }

  String _getBcp47Code(TranslateLanguage lang) {
    switch (lang) {
      case TranslateLanguage.afrikaans:
        return 'af';
      case TranslateLanguage.albanian:
        return 'sq';
      case TranslateLanguage.arabic:
        return 'ar';
      case TranslateLanguage.belarusian:
        return 'be';
      case TranslateLanguage.bulgarian:
        return 'bg';
      case TranslateLanguage.bengali:
        return 'bn';
      case TranslateLanguage.catalan:
        return 'ca';
      case TranslateLanguage.chinese:
        return 'zh';
      case TranslateLanguage.croatian:
        return 'hr';
      case TranslateLanguage.czech:
        return 'cs';
      case TranslateLanguage.danish:
        return 'da';
      case TranslateLanguage.dutch:
        return 'nl';
      case TranslateLanguage.english:
        return 'en';
      case TranslateLanguage.esperanto:
        return 'eo';
      case TranslateLanguage.estonian:
        return 'et';
      case TranslateLanguage.finnish:
        return 'fi';
      case TranslateLanguage.french:
        return 'fr';
      case TranslateLanguage.galician:
        return 'gl';
      case TranslateLanguage.georgian:
        return 'ka';
      case TranslateLanguage.german:
        return 'de';
      case TranslateLanguage.greek:
        return 'el';
      case TranslateLanguage.gujarati:
        return 'gu';
      case TranslateLanguage.haitian:
        return 'ht';
      case TranslateLanguage.hebrew:
        return 'he';
      case TranslateLanguage.hindi:
        return 'hi';
      case TranslateLanguage.hungarian:
        return 'hu';
      case TranslateLanguage.icelandic:
        return 'is';
      case TranslateLanguage.indonesian:
        return 'id';
      case TranslateLanguage.irish:
        return 'ga';
      case TranslateLanguage.italian:
        return 'it';
      case TranslateLanguage.japanese:
        return 'ja';
      case TranslateLanguage.kannada:
        return 'kn';
      case TranslateLanguage.korean:
        return 'ko';
      case TranslateLanguage.lithuanian:
        return 'lt';
      case TranslateLanguage.latvian:
        return 'lv';
      case TranslateLanguage.macedonian:
        return 'mk';
      case TranslateLanguage.marathi:
        return 'mr';
      case TranslateLanguage.malay:
        return 'ms';
      case TranslateLanguage.maltese:
        return 'mt';
      case TranslateLanguage.norwegian:
        return 'no';
      case TranslateLanguage.persian:
        return 'fa';
      case TranslateLanguage.polish:
        return 'pl';
      case TranslateLanguage.portuguese:
        return 'pt';
      case TranslateLanguage.romanian:
        return 'ro';
      case TranslateLanguage.russian:
        return 'ru';
      case TranslateLanguage.slovak:
        return 'sk';
      case TranslateLanguage.slovenian:
        return 'sl';
      case TranslateLanguage.spanish:
        return 'es';
      case TranslateLanguage.swahili:
        return 'sw';
      case TranslateLanguage.swedish:
        return 'sv';
      case TranslateLanguage.tamil:
        return 'ta';
      case TranslateLanguage.telugu:
        return 'te';
      case TranslateLanguage.thai:
        return 'th';
      case TranslateLanguage.turkish:
        return 'tr';
      case TranslateLanguage.ukrainian:
        return 'uk';
      case TranslateLanguage.urdu:
        return 'ur';
      case TranslateLanguage.vietnamese:
        return 'vi';
      case TranslateLanguage.welsh:
        return 'cy';
      default:
        return ''; // Return empty for unhandled languages to avoid false positives
    }
  }

  // Expose supported languages for UI
  List<Map<String, String>> getSupportedLanguages() {
    return [
      {'code': 'en', 'name': 'English'},
      {'code': 'hi', 'name': 'Hindi'},
      {'code': 'mr', 'name': 'Marathi'},
      {'code': 'bn', 'name': 'Bengali'},
      {'code': 'ta', 'name': 'Tamil'},
      {'code': 'te', 'name': 'Telugu'},
      {'code': 'gu', 'name': 'Gujarati'},
      {'code': 'kn', 'name': 'Kannada'},
      {'code': 'ur', 'name': 'Urdu'},
      {'code': 'es', 'name': 'Spanish'},
      {'code': 'fr', 'name': 'French'},
      {'code': 'de', 'name': 'German'},
      {'code': 'it', 'name': 'Italian'},
      {'code': 'pt', 'name': 'Portuguese'},
      {'code': 'ru', 'name': 'Russian'},
      {'code': 'ja', 'name': 'Japanese'},
      {'code': 'ko', 'name': 'Korean'},
      {'code': 'zh', 'name': 'Chinese'},
      {'code': 'ar', 'name': 'Arabic'},
    ];
  }
}
