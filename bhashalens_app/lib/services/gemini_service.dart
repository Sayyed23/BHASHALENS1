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
  Future<String> extractTextFromImage(Uint8List imageBytes) async {
    if (!_isInitialized) {
      throw Exception('Gemini service not initialized');
    }

    try {
      final content = [
        Content.multi([
          TextPart(
            'Extract all visible, readable text from this image. Return ONLY the extracted textual content, without any additional formatting, explanations, or conversational filler. If no clear text is found, respond solely with "No text detected".',
          ),
          DataPart('image/jpeg', imageBytes),
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
      debugPrint('Gemini Translation Prompt: $prompt');
      final response = await _model.generateContent(content);
      final translation = response.text ?? 'Translation failed';
      debugPrint('Gemini Translation Raw Response: ${response.text}');

      debugPrint('Translation: $translation');
      return translation.trim();
    } catch (e) {
      debugPrint('Error translating text: $e');
      throw Exception('Failed to translate text: $e');
    }
  }

  // OCR and translate in one operation
  Future<Map<String, String>> ocrAndTranslate(
    Uint8List imageBytes,
    String targetLanguage, {
    String? sourceLanguage,
  }) async {
    try {
      // First extract text
      final extractedText = await extractTextFromImage(imageBytes);

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

  // Refine text to be more confident/professional
  Future<String> refineText(String text, {String style = 'confident'}) async {
    if (!_isInitialized) {
      throw Exception('Gemini service not initialized');
    }

    try {
      String prompt;
      if (style == 'auto') {
        prompt =
            'Analyze the context of the following text. Rewrite it using the most appropriate tone (Confident, Professional, Polite, or Direct). IMPORTANT: Use simple, clear, and universally understandable English suitable for non-native speakers. Avoid complex jargon unless necessary. Input: $text';
      } else {
        prompt =
            'Rewrite the following text to sound more $style. IMPORTANT: Use simple, clear, and universally understandable English suitable for non-native speakers. Keep it concise. Input: $text';
      }

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final refinedText = response.text ?? 'Refinement failed';

      return refinedText.trim();
    } catch (e) {
      debugPrint('Error refining text: $e');
      throw Exception('Failed to refine text: $e');
    }
  }

  // Explain and Simplify text
  Future<String> explainAndSimplify(
    String text, {
    String simplicity = 'Simple',
    String targetLanguage = 'English',
  }) async {
    if (!_isInitialized) {
      throw Exception('Gemini service not initialized');
    }

    try {
      final prompt =
          'Explain the following text in $simplicity language, translated into $targetLanguage. Break it down into key points if necessary. Avoid jargon. Input: $text';
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final simplifiedText = response.text ?? 'Simplification failed';

      return simplifiedText.trim();
    } catch (e) {
      debugPrint('Error simplifying text: $e');
      throw Exception('Failed to simplify text: $e');
    }
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
