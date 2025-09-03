import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final String? apiKey;
  late GenerativeModel _model;
  late GenerativeModel _visionModel;
  bool _isInitialized = false;

  GeminiService({this.apiKey}) {
    if (apiKey != null && apiKey!.isNotEmpty) {
      initialize();
    }
  }

  // Initialize the Gemini service with API key
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      if (apiKey == null || apiKey!.isEmpty) {
        debugPrint('Gemini API key not found');
        return false;
      }

      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey!,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 2048,
        ),
      );

      _visionModel = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey!,
        generationConfig: GenerationConfig(
          temperature: 0.3,
          topK: 32,
          topP: 1,
          maxOutputTokens: 2048,
        ),
      );

      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Error initializing Gemini service: $e');
      return false;
    }
  }

  // Check if service is initialized
  bool get isInitialized => _isInitialized;

  // Extract text from image using Gemini Vision
  Future<String> extractTextFromImage(File imageFile) async {
    if (!_isInitialized) {
      throw Exception('Gemini service not initialized');
    }

    try {
      final bytes = await imageFile.readAsBytes();
      final content = [
        Content.multi([
          TextPart(
            'Extract all the text from this image. Return only the extracted text without any additional formatting or explanations. If no text is found, return "No text detected".',
          ),
          DataPart('image/jpeg', bytes),
        ]),
      ];

      final response = await _visionModel.generateContent(content);
      final text = response.text ?? 'No text detected';

      debugPrint('Extracted text: $text');
      return text.trim();
    } catch (e) {
      debugPrint('Error extracting text from image: $e');
      throw Exception('Failed to extract text from image: $e');
    }
  }

  // Translate text using Gemini
  Future<String> translateText(
    String text,
    String targetLanguage, {
    String? sourceLanguage,
  }) async {
    if (!_isInitialized) {
      throw Exception('Gemini service not initialized');
    }

    try {
      String prompt;
      if (sourceLanguage != null) {
        prompt =
            'You are a professional translator. Translate the following text from $sourceLanguage to $targetLanguage. Maintain the original meaning, tone, and context. Only return the translated text, nothing else:\n\n$text';
      } else {
        prompt =
            'You are a professional translator. Translate the following text to $targetLanguage. Maintain the original meaning, tone, and context. Only return the translated text, nothing else:\n\n$text';
      }

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final translation = response.text ?? 'Translation failed';

      debugPrint('Translation: $translation');
      return translation.trim();
    } catch (e) {
      debugPrint('Error translating text: $e');
      throw Exception('Failed to translate text: $e');
    }
  }

  // OCR and translate in one operation
  Future<Map<String, String>> ocrAndTranslate(
    File imageFile,
    String targetLanguage, {
    String? sourceLanguage,
  }) async {
    try {
      // First extract text
      final extractedText = await extractTextFromImage(imageFile);

      if (extractedText.isEmpty || extractedText == 'No text detected') {
        return {
          'extractedText': extractedText,
          'translatedText': 'No text to translate',
          'sourceLanguage': sourceLanguage ?? 'Unknown',
          'targetLanguage': targetLanguage,
        };
      }

      // Then translate the extracted text
      final translatedText = await translateText(
        extractedText,
        targetLanguage,
        sourceLanguage: sourceLanguage,
      );

      return {
        'extractedText': extractedText,
        'translatedText': translatedText,
        'sourceLanguage': sourceLanguage ?? 'Auto-detected',
        'targetLanguage': targetLanguage,
      };
    } catch (e) {
      debugPrint('Error in OCR and translate: $e');
      throw Exception('Failed to process image: $e');
    }
  }

  // Get supported languages
  List<Map<String, String>> getSupportedLanguages() {
    return [
      {'code': 'en', 'name': 'English'},
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
      {'code': 'hi', 'name': 'Hindi'},
      {'code': 'bn', 'name': 'Bengali'},
      {'code': 'te', 'name': 'Telugu'},
      {'code': 'ta', 'name': 'Tamil'},
      {'code': 'ml', 'name': 'Malayalam'},
      {'code': 'kn', 'name': 'Kannada'},
      {'code': 'gu', 'name': 'Gujarati'},
      {'code': 'pa', 'name': 'Punjabi'},
      {'code': 'ur', 'name': 'Urdu'},
    ];
  }

  // Detect language of text
  Future<String> detectLanguage(String text) async {
    if (!_isInitialized) {
      throw Exception('Gemini service not initialized');
    }

    try {
      final prompt =
          'Detect the language of this text and return only the language name in English:\n\n$text';
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final language = response.text ?? 'Unknown';

      return language.trim();
    } catch (e) {
      debugPrint('Error detecting language: $e');
      return 'Unknown';
    }
  }
}
