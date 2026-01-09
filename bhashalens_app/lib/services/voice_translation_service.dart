import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:bhashalens_app/services/gemini_service.dart';
import 'package:bhashalens_app/services/ml_kit_translation_service.dart';

class VoiceTranslationService extends ChangeNotifier {
  // Speech recognition
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  // API configuration
  String? _geminiApiKey;
  final bool _useOpenAI = false; // This will now control online/offline

  late GeminiService _geminiService;

  // ML Kit for offline translation
  final MlKitTranslationService _mlKitService = MlKitTranslationService();
  bool _isOfflineMode = false;

  // Speech recognition state
  bool _isListening = false;
  bool _speechEnabled = false;
  String _lastWords = '';
  String _currentTranscript = '';
  String _currentTranslatedText = '';
  bool _isTranslating = false; // New state for translation status

  // Translation state
  String _userALanguage = 'en'; // Default to English
  String _userBLanguage = 'hi'; // Default to Hindi
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
  bool get useOpenAI => _useOpenAI; // This now refers to online/offline toggle
  bool get isTranslating => _isTranslating; // New getter
  bool get isOfflineMode => _isOfflineMode; // Offline mode getter

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
    debugPrint(
      'VoiceTranslationService: Loaded GEMINI_API_KEY: \\$_geminiApiKey',
    );

    if (_geminiApiKey == null || _geminiApiKey!.isEmpty) {
      debugPrint('GEMINI_API_KEY not found in .env');
    } else {
      _geminiService = GeminiService(apiKey: _geminiApiKey);
      await _geminiService.initialize();
    }

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
    if (!_speechEnabled) {
      debugPrint('Speech recognition not enabled');
      return;
    }

    _currentSpeaker = speaker;
    _currentTranscript = '';
    _currentTranslatedText = '';
    _lastWords = '';

    String localeId = _getLanguageCode(
      _currentSpeaker == 'A' ? _userALanguage : _userBLanguage,
    );

    debugPrint(
      'Starting listening for speaker: $_currentSpeaker with locale: $localeId',
    );

    await _speechToText.listen(
      onResult: (result) {
        _currentTranscript = result.recognizedWords;
        _lastWords = result.recognizedWords;
        notifyListeners();
        if (result.finalResult) {
          processConversationTurn();
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: localeId,
      onSoundLevelChange: (level) {
        // Handle sound level changes if needed
      },
    );
    _isListening = true;
    notifyListeners();
  }

  Future<void> stopListening() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
      _isListening = false;
      notifyListeners();
      debugPrint('Stopped listening');
      // Translation will be triggered in the onResult callback when speech ends
    }
  }

  // Translation
  Future<String> translateText(
    String text,
    String toLanguage, {
    String? fromLanguage,
  }) async {
    if (text.trim().isEmpty) return '';

    try {
      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      _isOfflineMode = connectivityResult.contains(ConnectivityResult.none);
      notifyListeners();

      debugPrint('VoiceTranslation: isOfflineMode=$_isOfflineMode');

      String actualSourceLanguage =
          fromLanguage ?? 'en'; // Default to English if not provided

      if (_isOfflineMode) {
        // Use ML Kit for offline translation
        debugPrint(
          'Using ML Kit for offline translation: $actualSourceLanguage -> $toLanguage',
        );

        final mlKitResult = await _mlKitService.translate(
          text: text,
          sourceLanguage: actualSourceLanguage,
          targetLanguage: toLanguage,
        );

        if (mlKitResult != null && mlKitResult.isNotEmpty) {
          return mlKitResult;
        } else {
          // Check if models are available
          final sourceModelReady = await _mlKitService.isModelDownloaded(
            actualSourceLanguage,
          );
          final targetModelReady = await _mlKitService.isModelDownloaded(
            toLanguage,
          );

          if (!sourceModelReady || !targetModelReady) {
            return 'Offline translation unavailable. Please download language models in Settings → Offline Models.';
          }
          return 'Translation failed. Please try again.';
        }
      } else {
        // Use Gemini for online translation (better quality)
        if (_geminiApiKey == null ||
            _geminiApiKey!.isEmpty ||
            !_geminiService.isInitialized) {
          // Fall back to ML Kit if Gemini is not available
          debugPrint('Gemini not available, falling back to ML Kit');
          final mlKitResult = await _mlKitService.translate(
            text: text,
            sourceLanguage: actualSourceLanguage,
            targetLanguage: toLanguage,
          );
          return mlKitResult ?? 'Translation failed';
        }

        if (fromLanguage == 'auto') {
          try {
            final detectedLanguage = await _geminiService.detectLanguage(text);
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

        // Use GeminiService for translation
        return await _geminiService.translateText(
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

  // Process conversation turn
  Future<void> processConversationTurn() async {
    debugPrint('processConversationTurn called.');
    if (_currentTranscript.trim().isEmpty) {
      debugPrint('No transcript to process.');
      return;
    }

    final speaker = _currentSpeaker;
    final originalText = _currentTranscript;
    final speakerLanguage = speaker == 'A' ? _userALanguage : _userBLanguage;
    final targetLanguage = speaker == 'A' ? _userBLanguage : _userALanguage;

    debugPrint(
      'Processing turn: Speaker: $speaker, Lang: $speakerLanguage, Target: $targetLanguage, Text: $originalText',
    );

    // Show loading state
    _currentTranslatedText = 'Translating...';
    _isTranslating = true; // Set translating state to true
    notifyListeners();

    try {
      String actualSourceLanguage = speakerLanguage;

      // If source language is 'auto', detect it first (only with Gemini)
      if (speakerLanguage == 'auto') {
        if (!_geminiService.isInitialized) {
          throw Exception(
            'Gemini service not initialized for language detection',
          );
        }
        try {
          final detectedLanguage = await _geminiService.detectLanguage(
            originalText,
          );
          actualSourceLanguage = _convertLanguageNameToCode(detectedLanguage);
          debugPrint(
            'Detected language: $detectedLanguage -> $actualSourceLanguage',
          );
        } catch (e) {
          debugPrint('Language detection failed, using default: $e');
          actualSourceLanguage = 'en'; // fallback to English
        }
      }

      // Translate the text
      final translatedText = await translateText(
        originalText,
        targetLanguage,
        fromLanguage: actualSourceLanguage,
      );

      // Update current translated text
      _currentTranslatedText = translatedText;

      // Add to conversation history
      final message = ConversationMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        speaker: speaker,
        originalText: originalText,
        translatedText: translatedText,
        timestamp: DateTime.now(),
        speakerLanguage: actualSourceLanguage, // Use actual detected language
        targetLanguage: targetLanguage,
        detectedLanguage: (speakerLanguage == 'auto')
            ? actualSourceLanguage
            : null,
      );

      _conversationHistory.add(message);

      // Speak the translated text
      await speakText(translatedText, targetLanguage);

      _isTranslating = false; // Set translating state to false after completion
      notifyListeners();
    } catch (e) {
      debugPrint('Error processing conversation turn: $e');
      _currentTranslatedText = 'Translation failed: ${e.toString()}';
      _isTranslating = false; // Set translating state to false on error
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
        return 'en-US'; // For FlutterTts, use BCP-47 codes
      case 'es':
        return 'es-ES';
      case 'fr':
        return 'fr-FR';
      case 'de':
        return 'de-DE';
      case 'it':
        return 'it-IT';
      case 'pt':
        return 'pt-PT';
      case 'ru':
        return 'ru-RU';
      case 'ja':
        return 'ja-JP';
      case 'ko':
        return 'ko-KR';
      case 'zh':
        return 'zh-CN';
      case 'ar':
        return 'ar-SA';
      case 'hi':
        return 'hi-IN';
      case 'bn':
        return 'bn-IN';
      case 'ta':
        return 'ta-IN';
      case 'te':
        return 'te-IN';
      case 'ml':
        return 'ml-IN';
      case 'kn':
        return 'kn-IN';
      case 'gu':
        return 'gu-IN';
      case 'mr':
        return 'mr-IN';
      case 'pa':
        return 'pa-IN';
      default:
        return 'en-US';
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

  String convertLanguageCodeToName(String languageCode) {
    return supportedLanguages[languageCode] ?? languageCode;
  }

  /// Check if offline translation models are downloaded for current language pair
  Future<bool> areOfflineModelsReady() async {
    final sourceReady = await _mlKitService.isModelDownloaded(_userALanguage);
    final targetReady = await _mlKitService.isModelDownloaded(_userBLanguage);
    return sourceReady && targetReady;
  }

  /// Manually check and update connectivity status
  Future<void> checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    _isOfflineMode = connectivityResult.contains(ConnectivityResult.none);
    notifyListeners();
  }

  /// Get the ML Kit service for model management
  MlKitTranslationService get mlKitService => _mlKitService;

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
