import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class MlKitTranslationService {
  // Singleton pattern
  static final MlKitTranslationService _instance =
      MlKitTranslationService._internal();

  factory MlKitTranslationService() {
    return _instance;
  }

  MlKitTranslationService._internal();

  final _modelManager = OnDeviceTranslatorModelManager();
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

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
      final sourceModelAvailable = await isModelDownloaded(sourceLanguage);
      final targetModelAvailable = await isModelDownloaded(targetLanguage);

      // Direct translation (works best when one language is English)
      if (sourceLang == TranslateLanguage.english || targetLang == TranslateLanguage.english) {
        final onDeviceTranslator = OnDeviceTranslator(
          sourceLanguage: sourceLang,
          targetLanguage: targetLang,
        );

        final String response = await onDeviceTranslator.translateText(text);
        await onDeviceTranslator.close();
        return response;
      }

      // For non-English to non-English translation, use two-step process via English
      // Step 1: Source language -> English
      if (!sourceModelAvailable) {
        debugPrint('Source language model not available: $sourceLanguage');
        return null;
      }

      final toEnglishTranslator = OnDeviceTranslator(
        sourceLanguage: sourceLang,
        targetLanguage: TranslateLanguage.english,
      );

      final englishText = await toEnglishTranslator.translateText(text);
      await toEnglishTranslator.close();

      if (englishText.isEmpty) {
        debugPrint('Failed to translate to English: $sourceLanguage -> en');
        return null;
      }

      // Step 2: English -> Target language
      if (!targetModelAvailable) {
        debugPrint('Target language model not available: $targetLanguage');
        return null;
      }

      final fromEnglishTranslator = OnDeviceTranslator(
        sourceLanguage: TranslateLanguage.english,
        targetLanguage: targetLang,
      );

      final finalResult = await fromEnglishTranslator.translateText(englishText);
      await fromEnglishTranslator.close();

      return finalResult;
    } catch (e) {
      debugPrint('Error translating with ML Kit: $e');
      return null;
    }
  }

  /// Extracts text from image file using ML Kit Text Recognition.
  Future<String> extractTextFromFile(File file) async {
    try {
      final inputImage = InputImage.fromFile(file);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text.trim();
    } catch (e) {
      debugPrint('Error extracting text from file: $e');
      return 'Error extracting text';
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
  Future<bool> canTranslateBidirectionally(String sourceLanguage, String targetLanguage) async {
    try {
      final sourceLang = _getTranslateLanguage(sourceLanguage);
      final targetLang = _getTranslateLanguage(targetLanguage);

      if (sourceLang == null || targetLang == null) {
        return false;
      }

      // If either language is English, only need one model
      if (sourceLang == TranslateLanguage.english || targetLang == TranslateLanguage.english) {
        final nonEnglishLang = sourceLang == TranslateLanguage.english ? targetLanguage : sourceLanguage;
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
  Future<List<String>> getMissingModelsForTranslation(String sourceLanguage, String targetLanguage) async {
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

      // Check target model
      if (!(await isModelDownloaded(targetLanguage))) {
        missingModels.add(targetLanguage);
      }

      // For non-English to non-English translation, English is required
      if (sourceLang != TranslateLanguage.english && 
          targetLang != TranslateLanguage.english && 
          !(await isModelDownloaded('en'))) {
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
      if (lang == null) return false;

      return await _modelManager.isModelDownloaded(_getBcp47Code(lang));
    } catch (e) {
      debugPrint('Error checking model status for $languageCode: $e');
      return false;
    }
  }

  /// Returns a list of language codes for downloaded models.
  Future<List<String>> getDownloadedModels() async {
    try {
      // Iterate over supported languages and check status
      List<String> downloaded = [];
      // Check common languages to avoid checking hundreds if expensive,
      // or check all in TranslateLanguage.values
      for (var lang in TranslateLanguage.values) {
        if (await _modelManager.isModelDownloaded(_getBcp47Code(lang))) {
          downloaded.add(_getBcp47Code(lang));
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
      case 'es':
      case 'spanish':
        return TranslateLanguage.spanish;
      case 'fr':
      case 'french':
        return TranslateLanguage.french;
      // Add more as needed
      default:
        // Try to find by code
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
      // case TranslateLanguage.malayalam: return 'ml'; // Removed as it causes error
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
        return 'en';
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
