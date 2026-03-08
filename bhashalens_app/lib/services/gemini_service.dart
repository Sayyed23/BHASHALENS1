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

  GeminiService({this.apiKey, required this.localStorageService});
  // Initialization is deferred to explicit `initialize()` call
  // to avoid fire-and-forget async in constructor

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
        model: 'gemini-2.5-flash',
        apiKey: apiKey!,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 2048,
        ),
      );

      _visionModel = GenerativeModel(
        model: 'gemini-2.5-flash',
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
      final String targetName = _getLanguageName(targetLanguage);
      // Treat 'auto' as null - we don't want "from Auto-detect" in prompts
      final String? sourceName =
          (sourceLanguage != null && sourceLanguage != 'auto')
              ? _getLanguageName(sourceLanguage)
              : null;

      String prompt;
      if (sourceName != null) {
        prompt =
            'You are a professional translator. Translate the following text from $sourceName to $targetName. Maintain the original meaning, tone, and context. Only return the translated text, nothing else:\n\n$text';
      } else {
        prompt =
            'You are a professional translator. Translate the following text to $targetName. Maintain the original meaning, tone, and context. Only return the translated text, nothing else:\n\n$text';
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

  String _getLanguageName(String code) {
    if (code == 'auto') return 'Auto-detect';
    final languages = getSupportedLanguages();
    try {
      return languages.firstWhere((lang) => lang['code'] == code)['name'] ??
          code;
    } catch (e) {
      return code;
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
      final String targetLanguageName = _getLanguageName(targetLanguage);
      final prompt =
          'You are an expert language teacher and translation assistant. '
          'Your task is to analyze the following text module by module (sentence by sentence or phrase by phrase). '
          'For EACH module, you MUST provide a PROPER EXPLANATION in very SIMPLE terms (ELI5, MAXIMUM 1 SHORT SENTENCE), and a DIRECT TRANSLATION into $targetLanguageName. '
          'Format your response concisely as pure proper sentences for every module, like this:\n\n'
          '🔹 [The original text segment]\n'
          '🔸 [Direct translation in $targetLanguageName]\n'
          '💡 [A very short, simple, jargon-free explanation in $targetLanguageName (Max 1 sentence)]\n'
          '---\n\n'
          'Do NOT append labels like "**Original:**", "**Translation:**", or "**Explanation:**". Just output the pure sentence directly next to the icon.\n'
          'Your ENTIRE explanation and translation MUST be written in $targetLanguageName. '
          'Do NOT respond in English unless $targetLanguageName IS English. '
          'Provide the formatted response directly without any introductory preamble.\n\n'
          'Input text: $text';
      await _checkAndIncrementLimit();

      final content = [Content.text(prompt)];
      debugPrint('Gemini Simplify Prompt (target: $targetLanguageName)');
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
          'Detect the language of the following text. Return ONLY the name of the language (e.g., "Hindi", "English", "Marathi") as a single word or short phrase. Do NOT include any explanations, conversational filler, or formatting. If you are unsure, respond with "Unknown".\n\nText: $text';
      await _checkAndIncrementLimit();

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final language = response.text ?? 'Unknown';

      return language
          .split('\n')
          .first
          .trim()
          .replaceAll(RegExp(r'[^a-zA-Z\s]'), '');
    } catch (e) {
      debugPrint('Error detecting language: $e');
      return 'Unknown';
    }
  }

  // Explain with rich context (JSON output)
  Future<Map<String, dynamic>> explainTextWithContext(
    String text, {
    String targetLanguage = 'English',
    String? sourceLanguage,
  }) async {
    if (!_isInitialized) {
      throw Exception('Gemini service not initialized');
    }

    try {
      final String targetLanguageName = _getLanguageName(targetLanguage);
      final String? sourceLanguageName = sourceLanguage != null ? _getLanguageName(sourceLanguage) : null;
      
      String prompt = 'You are a language explanation expert. Analyze the following text. ';
      if (sourceLanguageName != null && sourceLanguageName != 'Auto-detect') {
        prompt += 'The input text is in $sourceLanguageName. ';
      } else {
        prompt += 'The input text may be in any language. ';
      }

      prompt +=
          'IMPORTANT: Your ENTIRE response (ALL fields including meaning, analysis, cultural_insight, etc.) '
          'MUST be written in $targetLanguageName. Do NOT respond in English unless $targetLanguageName IS English. '
          'You MUST provide detailed, meaningful answers for ALL fields. Do not leave any field empty or use generic placeholders like "N/A".\n'
          'The "meaning" field MUST provide a CLEAN, CLEAR, and EASY TO UNDERSTAND explanation module by module. '
          'Avoid technical jargon and keep it simple (ELI5 - Explain Like I\'m Five).\n'
          'Do NOT append labels like "**Original:**" or "**Translation:**". Just output the pure sentence directly.\n'
          'Return a valid JSON object with the following keys and no markdown formatting outside the JSON: '
          '{'
          '"translation": "String - The translation of the FULL text to $targetLanguageName", '
          '"analysis": "String - A brief contextual summary IN $targetLanguageName (1-2 sentences). Who is speaking? What is the main topic?", '
          '"meaning": "String - A detailed module-by-module breakdown. For every part of the text, format it concisely as pure proper sentences like this:\\n\\n🔹 [text]\\n🔸 [translation in $targetLanguageName]\\n💡 [very short, simple ELI5 explanation in $targetLanguageName (MAX 1 SENTENCE)]\\n---", '
          '"suggested_questions": ["String IN $targetLanguageName", "String IN $targetLanguageName"], '
          '"instructions": "String IN $targetLanguageName - Provide proper, step-by-step instructions or advice based on the text. CLEAR and EASY TO READ.", '
          '"when_to_use": "String IN $targetLanguageName - Describe exactly when and how to use this phrase", '
          '"tone": "String IN $targetLanguageName - Describe the tone (e.g. Formal, Polite, Casual)", '
          '"situational_context": ["String IN $targetLanguageName - Situation 1", "String IN $targetLanguageName - Situation 2"], '
          '"cultural_insight": "String IN $targetLanguageName - Important cultural note or fact", '
          '"safety_note": "String IN $targetLanguageName or null"'
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
        'You are a helpful language coach assisting the user in practicing for a specific scenario: "$context" (Goal: "$goal"). '
        'The user will speak to you as if they are in that situation. '
        'YOUR TASK: Do NOT roleplay back as the other character. Instead, analyze what the user said. '
        '1. If their sentence is grammatically correct and natural, confirm it (e.g., "That was perfect!"). '
        '2. If their sentence is understandable but could be improved (grammar, tone, politeness), suggest a "Better Way" to say it. '
        '3. If they make a mistake, gently correct it. '
        'Always provide the corrected or improved phrase clearly. '
        'Keep your feedback concise and encouraging. '
        'IMPORTANT: Respond in the SAME LANGUAGE that the user speaks to you (or the target language "$language").';

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

  // Improved Assistant Response (JSON)
  Future<Map<String, dynamic>> getAssistantResponse(
    String text,
    String situationalContext,
    String language,
  ) async {
    if (!_isInitialized) {
      throw Exception('Gemini service not initialized');
    }

    try {
      final String targetLanguageName = _getLanguageName(language);
      final prompt =
          'You are a helpful language assistant in a "$situationalContext" scenario. '
          'The user says/asks: "$text". '
          'YOUR TASK: Provide a helpful, concise response and linguistic guidance. '
          'Return a valid JSON object (no markdown) with these keys: '
          '{'
          '"response": "String - Direct, helpful answer in $targetLanguageName", '
          '"better_way": "String - A more natural, polite, or professional way to say the input phrase in $targetLanguageName (or null if not applicable)", '
          '"cultural_note": "String - A short cultural tip relevant to this $situationalContext situation in $targetLanguageName (or null)", '
          '"suggested_replies": ["String 1", "String 2"] - List of 2 short things the user can say next in $targetLanguageName'
          '} '
          'IMPORTANT: Your ENTIRE response MUST be in $targetLanguageName.';

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
      debugPrint('Error getting assistant response: $e');
      return {
        'response': 'I am sorry, I am having trouble understanding that right now.',
        'better_way': null,
        'cultural_note': null,
        'suggested_replies': ['Can you repeat that?', 'Help me with something else'],
      };
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
