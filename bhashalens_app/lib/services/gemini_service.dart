import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:bhashalens_app/services/local_storage_service.dart';

class GeminiService {
  final String? apiKey;
  final LocalStorageService localStorageService;
  late GenerativeModel _model;
  late GenerativeModel _visionModel;
  bool _isInitialized = false;

  GeminiService({this.apiKey, required this.localStorageService}) {
    if (apiKey != null && apiKey!.isNotEmpty) {
      initialize();
    }
  }

  Future<void> _lastLimitCheck = Future.value();

  Future<void> _checkAndIncrementLimit() async {
    final previous = _lastLimitCheck;
    final completer = Completer<void>();
    _lastLimitCheck = completer.future;

    try {
      await previous;
    } catch (_) {
      // Process next even if previous failed
    }

    try {
      final count = await localStorageService.getApiUsageCount();
      if (count >= 20) {
        throw Exception(
          'API usage limit reached (20/20). Please contact support or upgrade.',
        );
      }
      await localStorageService.incrementApiUsageCount();
    } finally {
      completer.complete();
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
        model: 'gemini-2.0-flash',
        apiKey: apiKey!,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 2048,
        ),
      );

      _visionModel = GenerativeModel(
        model: 'gemini-2.0-flash',
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
      await _checkAndIncrementLimit();

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

      await _checkAndIncrementLimit();

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

      await _checkAndIncrementLimit();

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
      await _checkAndIncrementLimit();

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
      await _checkAndIncrementLimit();

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final language = response.text ?? 'Unknown';

      return language.trim();
    } catch (e) {
      debugPrint('Error detecting language: $e');
      return 'Unknown';
    }
  }

  // Explain with rich context (JSON output)
  Future<Map<String, dynamic>> explainTextWithContext(
    String text, {
    String targetLanguage = 'English',
  }) async {
    if (!_isInitialized) {
      throw Exception('Gemini service not initialized');
    }

    try {
      final prompt =
          'Analyze the following text provided in any language. '
          'Target Language for translation and explanation: $targetLanguage. '
          'Return a valid JSON object with the following keys and no markdown formatting: '
          '{'
          '"translation": "String - The text translated to $targetLanguage", '
          '"analysis": "String - A brief contextual summary of what is happening or being said (e.g., The patient is describing...)", '
          '"meaning": "String - A simplified explanation of what the text means in $targetLanguage", '
          '"suggested_questions": ["String", "String"] - A list of 2-3 relevant follow-up questions for the user to ask", '
          '"when_to_use": "String - A brief recommendation on when to use this phrase", '
          '"tone": "String - The tone of the text (e.g., Formal, Casual, Urgent)", '
          '"situational_context": ["String", "String"] - A list of 2-3 specific situational details or implications", '
          '"cultural_insight": "String - A brief insight into the cultural nuance (if any). If none, provide a general context note.", '
          '"safety_note": "String - (Optional) Any safety warnings, urgency, or legal implications. Return null or empty string if not applicable."'
          '} '
          'Input Text: "$text"';

      await _checkAndIncrementLimit();

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final responseText = response.text;

      if (responseText == null) {
        throw Exception('Empty response from Gemini');
      }

      // Clean up markdown code blocks if present
      String jsonString = responseText.trim();
      if (jsonString.startsWith('```json')) {
        jsonString = jsonString.replaceAll('```json', '').replaceAll('```', '');
      } else if (jsonString.startsWith('```')) {
        jsonString = jsonString.replaceAll('```', '');
      }

      debugPrint('Gemini Context Response: $jsonString');

      try {
        final Map<String, dynamic> data = jsonDecode(jsonString);
        return data;
      } catch (e) {
        debugPrint('Failed to decode JSON: $e');
        // Fallback to basic map if JSON fails
        return {
          'translation': 'Could not analyze context',
          'meaning': responseText,
          'when_to_use': 'General',
          'tone': 'Neutral',
          'situational_context': [],
          'cultural_insight': 'N/A',
          'safety_note': null,
        };
      }
    } catch (e) {
      debugPrint('Error explaining with context: $e');
      throw Exception('Failed to explain text: $e');
    }
  }

  // Get Basic Guide for a context
  Future<Map<String, dynamic>> getBasicGuide(
    String context,
    String language,
  ) async {
    if (!_isInitialized) {
      throw Exception('Gemini service not initialized');
    }

    try {
      final prompt =
          'Create a "Basic Guide" for someone visiting a "$context". Language: $language. '
          'Return a JSON object with these keys (no markdown): '
          '{'
          '"etiquette": ["String", "String"], '
          '"opening_phrase": "String (Polite opening in target language)", '
          '"documents": ["String", "String"], '
          '"steps": ["String", "String"]'
          '}';

      await _checkAndIncrementLimit();

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final responseText = response.text;

      if (responseText == null) {
        throw Exception('Empty response from Gemini');
      }

      String jsonString = responseText.trim();
      if (jsonString.startsWith('```json')) {
        jsonString = jsonString.replaceAll('```json', '').replaceAll('```', '');
      } else if (jsonString.startsWith('```')) {
        jsonString = jsonString.replaceAll('```', '');
      }

      return jsonDecode(jsonString);
    } catch (e) {
      debugPrint('Error getting basic guide: $e');
      return {
        'etiquette': ['Be polite', 'Wait for your turn'],
        'opening_phrase': 'Hello',
        'documents': ['ID Proof'],
        'steps': ['Queuing', 'Speaking'],
      };
    }
  }

  // Start a Roleplay Session
  ChatSession? _currentChatSession;

  Future<String> startRoleplay(
    String context,
    String goal,
    String language,
  ) async {
    if (!_isInitialized) {
      throw Exception('Gemini service not initialized');
    }
    final systemPrompt =
        'You are functioning as a person in a "$context". The user has the goal: "$goal". '
        'You should roleplay this situation naturally. '
        'IMPORTANT: Respond in the SAME LANGUAGE that the user speaks to you. If they speak Hindi, respond in Hindi. If English, respond in English. '
        'Keep your responses concise and realistic. Do not break character. '
        'If the user makes a mistake, gently guide them but stay in character.';

    _currentChatSession = _model.startChat(
      history: [Content.text(systemPrompt)],
    );

    try {
      await _checkAndIncrementLimit();
      final response = await _currentChatSession!.sendMessage(
        Content.text(
          "Start the conversation with a generic greeting suitable for this role.",
        ),
      );
      return response.text ?? "Hello, how can I help you?";
    } catch (e) {
      debugPrint("Error fetching initial greeting: $e");
      return "Hello, how can I help you?";
    }
  }

  // Chat with Assistant
  Future<String> chatWithAssistant(String message) async {
    if (!_isInitialized || _currentChatSession == null) {
      throw Exception('Chat session not initialized');
    }

    try {
      await _checkAndIncrementLimit();
      final response = await _currentChatSession!.sendMessage(
        Content.text(message),
      );
      return response.text ?? '...';
    } catch (e) {
      debugPrint('Error in chat: $e');
      return 'Sorry, I assumed you said something else.';
    }
  }
}
