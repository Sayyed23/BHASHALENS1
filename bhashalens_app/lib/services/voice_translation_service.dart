import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:bhashalens_app/services/sarvam_service.dart';
import 'package:bhashalens_app/services/ml_kit_translation_service.dart';
import 'package:bhashalens_app/services/local_storage_service.dart';
import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:bhashalens_app/services/hybrid_translation_service.dart';
import 'dart:convert';
import 'dart:io';

class VoiceTranslationService extends ChangeNotifier {
  // Speech recognition
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final AudioRecorder _audioRecorder = AudioRecorder();
  WebSocketChannel? _sarvamSTTChannel;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // API configuration
  String? _sarvamApiKey;
  final bool _useOpenAI = false; 

  SarvamService? _sarvamService;
  HybridTranslationService? _hybridService;
  
  set hybridService(HybridTranslationService? service) => _hybridService = service;
  
  final LocalStorageService localStorageService;

  // ML Kit for offline translation
  final MlKitTranslationService _mlKitService = MlKitTranslationService();
  bool _isOfflineMode = false;

  // Speech recognition state
  bool _isListening = false;
  bool _speechEnabled = false;
  String _lastWords = '';
  String _currentTranscript = '';
  String _currentTranslatedText = '';
  bool _isTranslating = false; 

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
  bool get useOpenAI => _useOpenAI; 
  bool get isTranslating => _isTranslating; 
  bool get isOfflineMode => _isOfflineMode; 

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
    'ur': 'Urdu',
  };

  VoiceTranslationService({
    required this.localStorageService,
    String? sarvamApiKey,
    HybridTranslationService? hybridService,
  }) : _sarvamApiKey = sarvamApiKey,
       _hybridService = hybridService {
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _sarvamApiKey ??= dotenv.env['SARVAM_AI_API_KEY'];

    debugPrint(
      'VoiceTranslationService: Loaded SARVAM_AI_API_KEY: ${_sarvamApiKey != null ? "Present" : "Missing"}',
    );

    if (_sarvamApiKey != null && _sarvamApiKey!.isNotEmpty) {
      _sarvamService = SarvamService(
        apiKey: _sarvamApiKey,
        localStorageService: localStorageService,
      );
      await _sarvamService!.initialize();
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

    // Initial connectivity check
    await checkConnectivity();

    // Listen to connectivity changes
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      _isOfflineMode = results.contains(ConnectivityResult.none);
      notifyListeners();
    });

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
    _currentSpeaker = speaker;
    _currentTranscript = '';
    _currentTranslatedText = '';
    _lastWords = '';

    await checkConnectivity();

    if (_isOfflineMode) {
      if (!_speechEnabled) return;
      String localeId = _getLanguageCode(
        _currentSpeaker == 'A' ? _userALanguage : _userBLanguage,
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
        pauseFor: const Duration(seconds: 5),
        localeId: localeId,
        listenOptions: SpeechListenOptions(
          onDevice: true,
          cancelOnError: true,
        ),
      );
    } else {
      // Online: Use Sarvam Streaming STT
      await _startSarvamStreamingSTT();
    }
    
    _isListening = true;
    notifyListeners();
  }

  Future<void> _startSarvamStreamingSTT() async {
    if (_sarvamService == null) return;

    try {
      final langCode = _getLanguageCode(
        _currentSpeaker == 'A' ? _userALanguage : _userBLanguage,
      );
      
      _sarvamSTTChannel = _sarvamService!.createStreamingSTTChannel(
        languageCode: _sarvamService!.mapLanguageCode(langCode.substring(0, 2)),
      );

      _sarvamSTTChannel!.stream.listen((event) {
        final data = jsonDecode(event);
        if (data['transcript'] != null) {
          _currentTranscript = data['transcript'];
          _lastWords = data['transcript'];
          notifyListeners();
        }
        if (data['is_final'] == true) {
          processConversationTurn();
          stopListening();
        }
      }, onError: (err) {
        debugPrint('Sarvam STT Stream error: $err');
      });

      // Start recording and streaming audio
      if (await _audioRecorder.hasPermission()) {
        const config = RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        );

        final stream = await _audioRecorder.startStream(config);
        stream.listen((data) {
          _sarvamSTTChannel?.sink.add(data);
        });
      }
    } catch (e) {
      debugPrint('Error starting Sarvam streaming: $e');
    }
  }

  Future<void> stopListening() async {
    if (_isOfflineMode) {
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }
    } else {
      await _audioRecorder.stop();
      _sarvamSTTChannel?.sink.close();
      _sarvamSTTChannel = null;
    }
    _isListening = false;
    notifyListeners();
  }

  Future<void> listenOnce(Function(String) onResult, {String? localeId}) async {
    if (!_speechEnabled) return;

    _isListening = true;
    notifyListeners();

    await _speechToText.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
        if (result.finalResult) {
          _isListening = false;
          notifyListeners();
        }
      },
      listenFor: const Duration(seconds: 30),
      localeId: localeId ?? 'en-US',
      listenOptions: SpeechListenOptions(
        onDevice: _isOfflineMode,
        cancelOnError: true,
      ),
    );
  }

  // Translation using Sarvam AI for online
  Future<String> translateText(String text, String toLanguage, {String? fromLanguage}) async {
    if (text.trim().isEmpty) return '';

    try {
      await checkConnectivity();

      String actualSourceLanguage = fromLanguage ?? 'en';

      if (_isOfflineMode) {
        if (fromLanguage == 'auto') {
          actualSourceLanguage = await _mlKitService.identifyLanguage(text);
          if (actualSourceLanguage == 'und') return 'Offline: Language detection failed.';
        }
        return await _mlKitService.translate(
          text: text,
          sourceLanguage: actualSourceLanguage,
          targetLanguage: toLanguage,
        ) ?? 'Offline translation failed';
      } else {
        // Online: Use Hybrid Translation Service
        if (_hybridService == null) {
          debugPrint('Hybrid Service not available, falling back to Sarvam direct');
          return await _sarvamService!.translateText(
            text,
            _sarvamService!.mapLanguageCode(toLanguage),
            sourceLanguage: fromLanguage == 'auto' ? null : _sarvamService!.mapLanguageCode(actualSourceLanguage),
          );
        }

        final result = await _hybridService!.translateText(
          sourceText: text,
          sourceLang: actualSourceLanguage,
          targetLang: toLanguage,
        );
        return result.translatedText;
      }
    } catch (e) {
      debugPrint('Translation error: $e');
      return 'Translation error: $e';
    }
  }

  Future<void> processConversationTurn() async {
    if (_currentTranscript.trim().isEmpty) return;

    await checkConnectivity();

    final speaker = _currentSpeaker;
    final originalText = _currentTranscript;
    final targetLanguage = speaker == 'A' ? _userBLanguage : _userALanguage;

    _currentTranslatedText = 'Translating...';
    _isTranslating = true;
    notifyListeners();

    try {
      final translatedText = await translateText(
        originalText,
        targetLanguage,
        fromLanguage: speaker == 'A' ? _userALanguage : _userBLanguage,
      );

      _currentTranslatedText = translatedText;

      final message = ConversationMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        speaker: speaker,
        originalText: originalText,
        translatedText: translatedText,
        timestamp: DateTime.now(),
        speakerLanguage: speaker == 'A' ? _userALanguage : _userBLanguage,
        targetLanguage: targetLanguage,
      );

      _conversationHistory.add(message);
      await speakText(translatedText, targetLanguage);

      _isTranslating = false;
      notifyListeners();
    } catch (e) {
      _currentTranslatedText = 'Translation failed';
      _isTranslating = false;
      notifyListeners();
    }
  }

  Future<void> speakText(String text, String languageCode, {bool slow = false}) async {
    try {
      if (!_isOfflineMode && _sarvamService != null && _sarvamService!.isInitialized) {
        // Use Sarvam TTS for better quality in Indian languages
        final audioBytes = await _sarvamService!.textToSpeech(
          text, 
          _sarvamService!.mapLanguageCode(languageCode)
        );
        // Note: Playing raw bytes might require a specific plugin like audioplayers.
        // For now, falling back to flutter_tts until audioplayers is confirmed.
      }
      
      await _flutterTts.setLanguage(_getLanguageCode(languageCode));
      await _flutterTts.setSpeechRate(slow ? 0.3 : 0.5);
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS error: $e');
    }
  }

  String _getLanguageCode(String languageCode) {
    switch (languageCode) {
      case 'en': return 'en-US';
      case 'hi': return 'hi-IN';
      case 'bn': return 'bn-IN';
      case 'ta': return 'ta-IN';
      case 'te': return 'te-IN';
      case 'ml': return 'ml-IN';
      case 'kn': return 'kn-IN';
      case 'gu': return 'gu-IN';
      case 'mr': return 'mr-IN';
      case 'pa': return 'pa-IN';
      case 'ur': return 'ur-PK';
      default: return 'en-US';
    }
  }

  void clearConversation() {
    _conversationHistory.clear();
    _currentTranscript = '';
    _currentTranslatedText = '';
    notifyListeners();
  }

  Future<void> checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    _isOfflineMode = connectivityResult.contains(ConnectivityResult.none);
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _speechToText.cancel();
    _flutterTts.stop();
    _audioRecorder.dispose();
    _sarvamSTTChannel?.sink.close();
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

