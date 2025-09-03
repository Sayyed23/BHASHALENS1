import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:bhashalens_app/services/gemini_service.dart';

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
  String _currentTranslatedText = '';

  // Translation state
  String _userALanguage = 'auto';
  String _userBLanguage = 'es';
  String _currentSpeaker = 'A'; // 'A' or 'B'

  // Conversation history
  final List<ConversationMessage> _conversationHistory = [];

  // Getters
  bool get isListening => _isListening;
  bool get speechEnabled => _speechEnabled;
  String get lastWords => _lastWords;
  String get currentTranscript => _currentTranscript;
  String get currentTranslatedText => _currentTranslatedText;
  String get userALanguage => _userALanguage;
  String get userBLanguage => _userBLanguage;
  String get currentSpeaker => _currentSpeaker;
  List<ConversationMessage> get conversationHistory => _conversationHistory;
  bool get useOpenAI => _useOpenAI;

  // Language options
  static const Map<String, String> supportedLanguages = {
    'auto': 'Auto Detect',
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
    _currentTranslatedText = '';

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
      } else {
        // Use GeminiService for translation
        if (_geminiApiKey == null || _geminiApiKey!.isEmpty) {
          throw Exception('Gemini API key not found');
        }

        final geminiService = GeminiService(apiKey: _geminiApiKey);
        final initialized = await geminiService.initialize();

        if (!initialized) {
          throw Exception('Failed to initialize Gemini service');
        }

        // If source language is 'auto', detect it first
        String actualSourceLanguage = fromLanguage;
        if (fromLanguage == 'auto') {
          try {
            final detectedLanguage = await geminiService.detectLanguage(text);
            // Convert detected language name to language code
            actualSourceLanguage = _convertLanguageNameToCode(detectedLanguage);
            debugPrint(
              'Detected language: $detectedLanguage -> $actualSourceLanguage',
            );
          } catch (e) {
            debugPrint('Language detection failed, using default: $e');
            actualSourceLanguage = 'en'; // fallback to English
          }
        }

        return await geminiService.translateText(
          text,
          toLanguage,
          sourceLanguage: actualSourceLanguage,
        );
      }
    } catch (e) {
      debugPrint('Translation error: $e');
      return 'Translation failed: $e';
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
        'model': 'gpt-3.5-tbo',
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

    // Show loading state
    _currentTranslatedText = 'Translating...';
    notifyListeners();

    try {
      // Translate the text
      final translatedText = await translateText(
        _currentTranscript,
        speakerLanguage,
        targetLanguage,
      );

      // Update current translated text
      _currentTranslatedText = translatedText;

      // Track detected language if using auto-detection
      String? detectedLanguage;
      if (speakerLanguage == 'auto') {
        try {
          final geminiService = GeminiService(apiKey: _geminiApiKey);
          await geminiService.initialize();
          detectedLanguage = await geminiService.detectLanguage(
            _currentTranscript,
          );
        } catch (e) {
          debugPrint('Failed to detect language: $e');
        }
      }

      // Add to conversation history
      final message = ConversationMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        speaker: speaker,
        originalText: _currentTranscript,
        translatedText: translatedText,
        timestamp: DateTime.now(),
        speakerLanguage: speakerLanguage,
        targetLanguage: targetLanguage,
        detectedLanguage: detectedLanguage,
      );

      _conversationHistory.add(message);

      // Speak the translated text
      await speakText(translatedText, targetLanguage);

      notifyListeners();
    } catch (e) {
      debugPrint('Error processing conversation turn: $e');
      _currentTranslatedText = 'Translation failed. Please try again.';
      notifyListeners();
    }
  }

  // Text-to-speech
  Future<void> speakText(String text, String languageCode) async {
    try {
      await _flutterTts.setLanguage(_getLanguageCode(languageCode));
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS error: $e');
    }
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
      case 'bn':
        return 'bn_IN';
      case 'ta':
        return 'ta_IN';
      case 'te':
        return 'te_IN';
      case 'ml':
        return 'ml_IN';
      case 'kn':
        return 'kn_IN';
      case 'gu':
        return 'gu_IN';
      case 'mr':
        return 'mr_IN';
      case 'pa':
        return 'pa_IN';
      default:
        return 'en_US';
    }
  }

  // Conversation management
  void clearConversation() {
    _conversationHistory.clear();
    _currentTranscript = '';
    _currentTranslatedText = '';
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

  String _convertLanguageNameToCode(String languageName) {
    // Convert language names to language codes
    final lowerName = languageName.toLowerCase();

    if (lowerName.contains('english')) return 'en';
    if (lowerName.contains('spanish')) return 'es';
    if (lowerName.contains('french')) return 'fr';
    if (lowerName.contains('german')) return 'de';
    if (lowerName.contains('italian')) return 'it';
    if (lowerName.contains('portuguese')) return 'pt';
    if (lowerName.contains('russian')) return 'ru';
    if (lowerName.contains('japanese')) return 'ja';
    if (lowerName.contains('korean')) return 'ko';
    if (lowerName.contains('chinese')) return 'zh';
    if (lowerName.contains('arabic')) return 'ar';
    if (lowerName.contains('hindi')) return 'hi';
    if (lowerName.contains('bengali')) return 'bn';
    if (lowerName.contains('tamil')) return 'ta';
    if (lowerName.contains('telugu')) return 'te';
    if (lowerName.contains('malayalam')) return 'ml';
    if (lowerName.contains('kannada')) return 'kn';
    if (lowerName.contains('gujarati')) return 'gu';
    if (lowerName.contains('marathi')) return 'mr';
    if (lowerName.contains('punjabi')) return 'pa';

    // Default to English if no match found
    return 'en';
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
  final String? detectedLanguage; // For auto-detection

  ConversationMessage({
    required this.id,
    required this.speaker,
    required this.originalText,
    required this.translatedText,
    required this.timestamp,
    required this.speakerLanguage,
    required this.targetLanguage,
    this.detectedLanguage,
  });
}
