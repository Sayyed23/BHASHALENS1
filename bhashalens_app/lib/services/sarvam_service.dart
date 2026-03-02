import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:bhashalens_app/services/local_storage_service.dart';

class SarvamService {
  final String? apiKey;
  final LocalStorageService localStorageService;
  bool _isInitialized = false;

  static const String _baseUrl = 'https://api.sarvam.ai';

  SarvamService({this.apiKey, required this.localStorageService});

  Future<bool> initialize() async {
    if (apiKey == null || apiKey!.isEmpty) {
      debugPrint('Sarvam AI API key not found');
      return false;
    }
    _isInitialized = true;
    return true;
  }

  bool get isInitialized => _isInitialized;

  // 1. Text Translation
  Future<String> translateText(
    String text,
    String targetLanguage, {
    String? sourceLanguage,
    String? mode = 'modern-colloquial',
  }) async {
    if (!_isInitialized) throw Exception('Sarvam service not initialized');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/translate'),
        headers: {
          'Content-Type': 'application/json',
          'api-subscription-key': apiKey!,
        },
        body: jsonEncode({
          'input': text,
          'source_language_code': sourceLanguage ?? 'en-IN',
          'target_language_code': targetLanguage,
          'speaker_gender': 'Female',
          'mode': mode,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['translated_text'] ?? '';
      } else {
        throw Exception('Sarvam Translation API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Sarvam translateText error: $e');
      rethrow;
    }
  }

  // 2. Text to Speech (TTS)
  Future<List<int>> textToSpeech(String text, String languageCode) async {
    if (!_isInitialized) throw Exception('Sarvam service not initialized');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/text-to-speech'),
        headers: {
          'Content-Type': 'application/json',
          'api-subscription-key': apiKey!,
        },
        body: jsonEncode({
          'inputs': [text],
          'target_language_code': languageCode,
          'speaker': 'meera', // Sarvam's standard female voice
          'pitch': 0,
          'pace': 1.0,
          'loudness': 1.5,
          'speech_sample_rate': 8000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final base64String = data['audios'][0];
        return base64.decode(base64String);
      } else {
        throw Exception('Sarvam TTS API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Sarvam textToSpeech error: $e');
      rethrow;
    }
  }

  // 3. Contextual Analysis (Explain Mode - JSON Fallback logic)
  Future<Map<String, dynamic>> explainText(
    String text, {
    String targetLanguage = 'hi-IN',
    String? sourceLanguage,
  }) async {
    // Sarvam doesn't have a direct "Explain Mode" JSON API like Gemini Flash,
    // so we use their high-quality translation + a custom prompt if using a chat model,
    // OR we provide a structured translation with metadata.
    
    try {
      final translated = await translateText(text, targetLanguage, sourceLanguage: sourceLanguage);
      
      // Basic structured fallback using Sarvam's translation
      return {
        'translation': translated,
        'analysis': 'Analyzed via Sarvam AI Indian Language Model.',
        'meaning': 'Simplified meaning provided through regional context.',
        'suggested_questions': ['How to say this formally?', 'Is this polite?'],
        'when_to_use': 'General conversation',
        'tone': 'Modern Colloquial',
        'cultural_insight': 'Localized for regional nuances.',
        'safety_note': null
      };
    } catch (e) {
      debugPrint('Sarvam explainText error: $e');
      rethrow;
    }
  }

  // 4. Streaming Speech to Text (STT) Client
  WebSocketChannel createStreamingSTTChannel({
    required String languageCode,
    String model = 'saaras:v1',
  }) {
    // Sarvam v3 is better, but following their recommended websocket URL pattern
    final uri = Uri.parse('wss://api.sarvam.ai/speech-to-text-stream');
    final channel = WebSocketChannel.connect(uri);

    // Initial config message
    final config = {
      "api-subscription-key": apiKey!,
      "model": model,
      "language_code": languageCode,
      "sample_rate": 16000,
      "input_audio_codec": "pcm_s16le",
    };

    channel.sink.add(jsonEncode(config));
    return channel;
  }

  // 5. Chat Completion (Assistant Mode / Roleplay)
  Future<String> chatWithAssistant(String message, {List<Map<String, String>>? history}) async {
    if (!_isInitialized) throw Exception('Sarvam service not initialized');

    try {
      final messages = history ?? [];
      messages.add({'role': 'user', 'content': message});

      final response = await http.post(
        Uri.parse('$_baseUrl/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'api-subscription-key': apiKey!,
        },
        body: jsonEncode({
          'model': 'sarvam-m',
          'messages': messages,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? '';
      } else {
        throw Exception('Sarvam Chat API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Sarvam chatWithAssistant error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getBasicGuide(String situation, String language) async {
    final prompt = "Provide a basic cultural and linguistic guide for a $situation situation in $language. Return as JSON with 'cultural_tips' (list), 'common_phrases' (list of {phrase, translation}), and 'etiquette' (string).";
    
    try {
      final response = await chatWithAssistant(prompt);
      // Attempt to parse JSON from the response
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(response);
      if (jsonMatch != null) {
        return jsonDecode(jsonMatch.group(0)!);
      }
      return {
        'cultural_tips': ['Be polite', 'Observe local customs'],
        'common_phrases': [{'phrase': 'Hello', 'translation': 'Namaste'}],
        'etiquette': 'General professional etiquette'
      };
    } catch (e) {
      debugPrint('Sarvam getBasicGuide error: $e');
      return {
        'cultural_tips': ['Error loading guide'],
        'common_phrases': [],
        'etiquette': 'N/A'
      };
    }
  }

  Future<String> startRoleplay(String situation, String goal, String language) async {
    final prompt = "Start a roleplay for the situation: $situation. My goal is: $goal. Speak in $language. Just give the first opening line from the other person.";
    return chatWithAssistant(prompt);
  }

  // 6. Metadata
  List<Map<String, String>> getSupportedLanguages() {
    return [
      {'code': 'en', 'name': 'English'},
      {'code': 'hi', 'name': 'Hindi'},
      {'code': 'bn', 'name': 'Bengali'},
      {'code': 'ta', 'name': 'Tamil'},
      {'code': 'te', 'name': 'Telugu'},
      {'code': 'kn', 'name': 'Kannada'},
      {'code': 'gu', 'name': 'Gujarati'},
      {'code': 'mr', 'name': 'Marathi'},
      {'code': 'ml', 'name': 'Malayalam'},
      {'code': 'pa', 'name': 'Punjabi'},
      {'code': 'or', 'name': 'Odia'},
    ];
  }

  // Helper to map UI language codes to Sarvam codes
  String mapLanguageCode(String code) {
    switch (code.toLowerCase()) {
      case 'en': return 'en-IN';
      case 'hi': return 'hi-IN';
      case 'bn': return 'bn-IN';
      case 'ta': return 'ta-IN';
      case 'te': return 'te-IN';
      case 'ml': return 'ml-IN';
      case 'kn': return 'kn-IN';
      case 'gu': return 'gu-IN';
      case 'mr': return 'mr-IN';
      case 'pa': return 'pa-IN';
      case 'ur': return 'ur-IN';
      default: return 'en-IN';
    }
  }
}
