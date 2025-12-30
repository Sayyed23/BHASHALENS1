import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OpenRouterService {
  final String? apiKey;
  final String _baseUrl = 'https://openrouter.ai/api/v1';
  // Using gpt-4o for best performance/vision capabilities as requested
  final String _model = 'openai/gpt-4o'; 
  
  bool _isInitialized = false;

  OpenRouterService({this.apiKey}) {
    if (apiKey != null && apiKey!.isNotEmpty) {
      initialize();
    }
  }

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    if (apiKey == null || apiKey!.isEmpty) {
      debugPrint('OpenRouter API key not found');
      return false;
    }

    _isInitialized = true;
    return true;
  }

  bool get isInitialized => _isInitialized;

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        // Optional: Add site URL/Name for OpenRouter rankings
        'HTTP-Referer': 'https://bhashalens.app', 
        'X-Title': 'BhashaLens',
      };

  // Extract text from image using GPT-4o Vision
  Future<String> extractTextFromImage(Uint8List imageBytes) async {
    if (!_isInitialized) {
      throw Exception('OpenRouter service not initialized');
    }

    try {
      final base64Image = base64Encode(imageBytes);
      
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: _headers,
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'Extract all visible, readable text from this image. Return ONLY the extracted textual content, without any additional formatting, explanations, or conversational filler. If no clear text is found, respond solely with "No text detected".'
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image'
                  }
                }
              ]
            }
          ],
          'temperature': 0.1, // Low temperature for factual extraction
          'max_tokens': 1000, // Limit response size to save credits
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        debugPrint('OpenRouter Extracted text: $content');
        return content.trim();
      } else {
        debugPrint('OpenRouter Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to extract text: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error extracting text from image: $e');
      throw Exception('Failed to extract text from image: $e');
    }
  }

  // Translate text
  Future<String> translateText(
    String text,
    String targetLanguage, {
    String? sourceLanguage,
  }) async {
    if (!_isInitialized) {
      throw Exception('OpenRouter service not initialized');
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

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: _headers,
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'user',
              'content': prompt
            }
          ],
          'temperature': 0.3,
          'max_tokens': 1000, // Limit response size
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        debugPrint('OpenRouter Translation: $content');
        return content.trim();
      } else {
        debugPrint('OpenRouter Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to translate text: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error translating text: $e');
      throw Exception('Failed to translate text: $e');
    }
  }

  // Detect language
  Future<String> detectLanguage(String text) async {
    if (!_isInitialized) {
      throw Exception('OpenRouter service not initialized');
    }

    try {
      final prompt =
          'Detect the language of this text and return only the language name in English:\n\n$text';

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: _headers,
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'user',
              'content': prompt
            }
          ],
          'temperature': 0.0,
          'max_tokens': 50, // Only need a language name
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        return content.trim();
      } else {
        debugPrint('OpenRouter Error: ${response.statusCode} - ${response.body}');
        return 'Unknown';
      }
    } catch (e) {
      debugPrint('Error detecting language: $e');
      return 'Unknown';
    }
  }

  // Supported languages (Same as GeminiService for consistency)
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
}
