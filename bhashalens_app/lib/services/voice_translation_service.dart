import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceTranslationService extends ChangeNotifier {
  // Speech recognition
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  // API configuration
  String? _geminiApiKey;
  String? _openaiApiKey;
  bool _useOpenAI = false; // Toggle between Gemini and OpenAI

  // Speech recognition state
  bool _isListening = false;
  bool _speechEnabled = false;
  String _lastWords = '';
  String _currentTranscript = '';

  // Translation state
  String _userALanguage = 'en';
  String _userBLanguage = 'es';
  String _currentSpeaker = 'A'; // 'A' or 'B'

  // Conversation history
  final List<ConversationMessage> _conversationHistory = [];

  // Getters
  bool get isListening => _isListening;
  bool get speechEnabled => _speechEnabled;
  String get lastWords => _lastWords;
  String get currentTranscript => _currentTranscript;
  String get userALanguage => _userALanguage;
  String get userBLanguage => _userBLanguage;
  String get currentSpeaker => _currentSpeaker;
  List<ConversationMessage> get conversationHistory => _conversationHistory;
  bool get useOpenAI => _useOpenAI;

  // Language options
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'it': 'Italian',
    'pt': 'Portuguese',
    'ru': 'Russian',
    'ja': 'Japanese',
    'ko': 'Korean',
    'zh': 'Chinese',
    'ar': 'Arabic',
    'hi': 'Hindi',
    'bn': 'Bengali',
    'ta': 'Tamil',
    'te': 'Telugu',
    'ml': 'Malayalam',
    'kn': 'Kannada',
    'gu': 'Gujarati',
    'mr': 'Marathi',
    'pa': 'Punjabi',
  };

  VoiceTranslationService() {
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Load API keys
    _geminiApiKey = dotenv.env['GEMINI_API_KEY'];
    _openaiApiKey = dotenv.env['OPENAI_API_KEY'];

    // Initialize speech recognition
    _speechEnabled = await _speechToText.initialize(
      onStatus: (status) {
        _isListening = status == 'listening';
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Speech recognition error: $error');
        _isListening = false;
        notifyListeners();
      },
    );

    // Initialize text-to-speech
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    notifyListeners();
  }

  // Toggle between Gemini and OpenAI
  void toggleApiProvider() {
    _useOpenAI = !_useOpenAI;
    notifyListeners();
  }

  // Set API provider
  void setApiProvider(bool useOpenAI) {
    _useOpenAI = useOpenAI;
    notifyListeners();
  }

  // Language management
  void setUserALanguage(String languageCode) {
    _userALanguage = languageCode;
    notifyListeners();
  }

  void setUserBLanguage(String languageCode) {
    _userBLanguage = languageCode;
    notifyListeners();
  }

  void swapLanguages() {
    final temp = _userALanguage;
    _userALanguage = _userBLanguage;
    _userBLanguage = temp;
    notifyListeners();
  }

  // Speech recognition
  Future<void> startListening(String speaker) async {
    if (!_speechEnabled) return;

    _currentSpeaker = speaker;
    _currentTranscript = '';

    await _speechToText.listen(
      onResult: (result) {
        _currentTranscript = result.recognizedWords;
        notifyListeners();
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: _getLanguageCode(
        _currentSpeaker == 'A' ? _userALanguage : _userBLanguage,
      ),
      onSoundLevelChange: (level) {
        // Handle sound level changes if needed
      },
    );
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    _isListening = false;
    notifyListeners();
  }

  // Translation
  Future<String> translateText(
    String text,
    String fromLanguage,
    String toLanguage,
  ) async {
    if (text.trim().isEmpty) return '';

    try {
      if (_useOpenAI && _openaiApiKey != null) {
        return await _translateWithOpenAI(text, fromLanguage, toLanguage);
      } else if (_geminiApiKey != null) {
        return await _translateWithGemini(text, fromLanguage, toLanguage);
      } else {
        throw Exception('No API key available');
      }
    } catch (e) {
      debugPrint('Translation error: $e');
      return 'Translation failed: $e';
    }
  }

  Future<String> _translateWithGemini(
    String text,
    String fromLanguage,
    String toLanguage,
  ) async {
    final fromLangName = supportedLanguages[fromLanguage] ?? fromLanguage;
    final toLangName = supportedLanguages[toLanguage] ?? toLanguage;

    final prompt =
        '''
Translate the following text from $fromLangName to $toLangName. 
Only return the translated text, nothing else.

Text to translate: "$text"
''';

    final response = await http.post(
      Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$_geminiApiKey',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.1,
          'topK': 1,
          'topP': 1,
          'maxOutputTokens': 1000,
        },
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final translatedText =
          data['candidates'][0]['content']['parts'][0]['text'];
      return translatedText.trim();
    } else {
      throw Exception('Gemini API error: ${response.statusCode}');
    }
  }

  Future<String> _translateWithOpenAI(
    String text,
    String fromLanguage,
    String toLanguage,
  ) async {
    final fromLangName = supportedLanguages[fromLanguage] ?? fromLanguage;
    final toLangName = supportedLanguages[toLanguage] ?? toLanguage;

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_openaiApiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a professional translator. Translate the given text accurately from $fromLangName to $toLangName. Only return the translated text, nothing else.',
          },
          {'role': 'user', 'content': text},
        ],
        'max_tokens': 1000,
        'temperature': 0.1,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final translatedText = data['choices'][0]['message']['content'];
      return translatedText.trim();
    } else {
      throw Exception('OpenAI API error: ${response.statusCode}');
    }
  }

  // Process conversation turn
  Future<void> processConversationTurn() async {
    if (_currentTranscript.trim().isEmpty) return;

    final speaker = _currentSpeaker;
    final speakerLanguage = speaker == 'A' ? _userALanguage : _userBLanguage;
    final targetLanguage = speaker == 'A' ? _userBLanguage : _userALanguage;

    // Translate the text
    final translatedText = await translateText(
      _currentTranscript,
      speakerLanguage,
      targetLanguage,
    );

    // Add to conversation history
    final message = ConversationMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      speaker: speaker,
      originalText: _currentTranscript,
      translatedText: translatedText,
      timestamp: DateTime.now(),
      speakerLanguage: speakerLanguage,
      targetLanguage: targetLanguage,
    );

    _conversationHistory.add(message);

    // Clear current transcript
    _currentTranscript = '';
    _lastWords = '';

    notifyListeners();
  }

  // Text-to-speech
  Future<void> speakText(String text, String languageCode) async {
    await _flutterTts.setLanguage(_getLanguageCode(languageCode));
    await _flutterTts.speak(text);
  }

  // Helper methods
  String _getLanguageCode(String languageCode) {
    // Convert language codes to speech recognition format
    switch (languageCode) {
      case 'en':
        return 'en_US';
      case 'es':
        return 'es_ES';
      case 'fr':
        return 'fr_FR';
      case 'de':
        return 'de_DE';
      case 'it':
        return 'it_IT';
      case 'pt':
        return 'pt_PT';
      case 'ru':
        return 'ru_RU';
      case 'ja':
        return 'ja_JP';
      case 'ko':
        return 'ko_KR';
      case 'zh':
        return 'zh_CN';
      case 'ar':
        return 'ar_SA';
      case 'hi':
        return 'hi_IN';
      default:
        return 'en_US';
    }
  }

  // Conversation management
  void clearConversation() {
    _conversationHistory.clear();
    notifyListeners();
  }

  String getConversationTranscript() {
    return _conversationHistory
        .map(
          (msg) =>
              '${msg.speaker}: ${msg.originalText}\nTranslated: ${msg.translatedText}',
        )
        .join('\n\n');
  }

  // Dispose
  @override
  void dispose() {
    _speechToText.cancel();
    _flutterTts.stop();
    super.dispose();
  }
}

class ConversationMessage {
  final String id;
  final String speaker;
  final String originalText;
  final String translatedText;
  final DateTime timestamp;
  final String speakerLanguage;
  final String targetLanguage;

  ConversationMessage({
    required this.id,
    required this.speaker,
    required this.originalText,
    required this.translatedText,
    required this.timestamp,
    required this.speakerLanguage,
    required this.targetLanguage,
  });
}
