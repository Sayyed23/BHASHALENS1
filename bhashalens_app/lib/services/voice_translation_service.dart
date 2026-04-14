import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:bhashalens_app/services/ml_kit_translation_service.dart';
import 'package:bhashalens_app/services/local_storage_service.dart';
import 'package:bhashalens_app/services/hybrid_translation_service.dart';

/// Offline readiness status for a language
class LanguageOfflineStatus {
  final bool sttAvailable;
  final bool translationModelReady;
  final bool ttsAvailable;

  const LanguageOfflineStatus({
    required this.sttAvailable,
    required this.translationModelReady,
    required this.ttsAvailable,
  });

  bool get isFullyReady => sttAvailable && translationModelReady && ttsAvailable;
  bool get canTranslateOnly => translationModelReady; // text works even w/o STT/TTS
}

class VoiceTranslationService extends ChangeNotifier {
  // Speech recognition
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // API configuration
  final bool _useOpenAI = false;

  HybridTranslationService? _hybridService;

  set hybridService(HybridTranslationService? service) =>
      _hybridService = service;

  final LocalStorageService localStorageService;

  // ML Kit for offline translation
  final MlKitTranslationService _mlKitService = MlKitTranslationService();
  bool _isOfflineMode = false;

  // Available speech locales (populated after init)
  List<LocaleName> _availableLocales = [];

  // Offline readiness per language (cached)
  final Map<String, LanguageOfflineStatus> _offlineStatus = {};

  // Speech recognition state
  bool _isListening = false;
  bool _speechEnabled = false;
  String _lastWords = '';
  String _currentTranscript = '';
  String _currentTranslatedText = '';
  bool _isTranslating = false;
  String? _errorMessage; // User-facing error message

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
  String? get errorMessage => _errorMessage;
  MlKitTranslationService get mlKitService => _mlKitService;
  List<LocaleName> get availableLocales => _availableLocales;
  Map<String, LanguageOfflineStatus> get offlineStatus => _offlineStatus;

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
    HybridTranslationService? hybridService,
  }) : _hybridService = hybridService {
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Initialize speech recognition
    _speechEnabled = await _speechToText.initialize(
      onStatus: (status) {
        _isListening = status == 'listening';
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Speech recognition error: $error');
        _isListening = false;
        _errorMessage = 'Speech recognition error. Please try again.';
        notifyListeners();
      },
    );

    // Cache available locales for later checks
    if (_speechEnabled) {
      _availableLocales = await _speechToText.locales();
      debugPrint(
          'Available speech locales: ${_availableLocales.map((l) => l.localeId).toList()}');
    }

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
    _refreshOfflineStatus(languageCode);
    notifyListeners();
  }

  void setUserBLanguage(String languageCode) {
    _userBLanguage = languageCode;
    _refreshOfflineStatus(languageCode);
    notifyListeners();
  }

  void swapLanguages() {
    final temp = _userALanguage;
    _userALanguage = _userBLanguage;
    _userBLanguage = temp;
    notifyListeners();
  }

  /// Refresh offline readiness status for a language (async, updates UI when done)
  Future<void> _refreshOfflineStatus(String languageCode) async {
    final status = await checkLanguageReadiness(languageCode);
    _offlineStatus[languageCode] = status;
    notifyListeners();
  }

  /// Check offline readiness for all three components: STT, Translation, TTS
  Future<LanguageOfflineStatus> checkLanguageReadiness(String languageCode) async {
    final stt = isLocaleAvailable(languageCode);
    final translation = await _mlKitService.isModelDownloaded(languageCode);
    final tts = await isTtsAvailable(languageCode);
    return LanguageOfflineStatus(
      sttAvailable: stt,
      translationModelReady: translation,
      ttsAvailable: tts,
    );
  }

  /// Check if TTS can speak a given language
  Future<bool> isTtsAvailable(String languageCode) async {
    try {
      final localeCode = _getLanguageCode(languageCode);
      final result = await _flutterTts.isLanguageAvailable(localeCode);
      return result == 1 || result == true;
    } catch (e) {
      debugPrint('TTS availability check failed for $languageCode: $e');
      return false;
    }
  }

  /// Check if a speech locale is available on this device
  bool isLocaleAvailable(String languageCode) {
    final localeId = _getLanguageCode(languageCode);
    // Check both exact match and prefix match (e.g., 'mr' matches 'mr-IN')
    return _availableLocales.any((locale) =>
        locale.localeId == localeId ||
        locale.localeId.startsWith('${languageCode}_') ||
        locale.localeId.startsWith('$languageCode-'));
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Check if offline translation models are ready for a language pair
  Future<bool> areOfflineModelsReady(String langA, String langB) async {
    final aReady = await _mlKitService.isModelDownloaded(langA);
    final bReady = await _mlKitService.isModelDownloaded(langB);
    // English is needed as intermediate for non-English pairs
    if (langA != 'en' && langB != 'en') {
      final enReady = await _mlKitService.isModelDownloaded('en');
      return aReady && bReady && enReady;
    }
    return aReady && bReady;
  }

  /// Download offline model for a language
  Future<bool> downloadOfflineModel(String languageCode) async {
    return await _mlKitService.downloadModel(languageCode);
  }

  // Speech recognition
  Future<void> startListening(String speaker) async {
    _currentSpeaker = speaker;
    _currentTranscript = '';
    _currentTranslatedText = '';
    _lastWords = '';
    _errorMessage = null;

    await checkConnectivity();

    if (!_speechEnabled) {
      _errorMessage = 'Speech recognition is not available on this device.';
      notifyListeners();
      return;
    }

    final langCode = _currentSpeaker == 'A' ? _userALanguage : _userBLanguage;
    String localeId = _getLanguageCode(langCode);

    // Check if locale is available on device
    if (!isLocaleAvailable(langCode)) {
      // Try a fallback: find any matching locale prefix
      final fallback = _availableLocales.where((locale) =>
          locale.localeId.startsWith('${langCode}_') ||
          locale.localeId.startsWith('$langCode-'));
      if (fallback.isNotEmpty) {
        localeId = fallback.first.localeId;
        debugPrint('Using fallback locale: $localeId for $langCode');
      } else {
        final langName = supportedLanguages[langCode] ?? langCode;
        _errorMessage =
            '$langName speech recognition is not installed on your device. '
            'Please add $langName in your device\'s language settings.';
        notifyListeners();
        return;
      }
    }

    try {
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
          onDevice: _isOfflineMode, // Force on-device when offline
          cancelOnError: false, // Don't silently cancel
        ),
      );

      _isListening = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to start listening: $e');
      final langName = supportedLanguages[langCode] ?? langCode;
      _errorMessage = 'Could not start $langName speech recognition. '
          'Please check your device language settings.';
      _isListening = false;
      notifyListeners();
    }
  }

  // Removed Sarvam streaming STT logic as it is being decommissioned in favor of Hybrid/AWS stack.
  // Future<void> _startSarvamStreamingSTT() async { ... }

  Future<void> stopListening() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
      if (_currentTranscript.trim().isNotEmpty && !_isTranslating) {
        processConversationTurn();
      }
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

  // Translation using Gemini AI for online
  Future<String> translateText(String text, String toLanguage,
      {String? fromLanguage}) async {
    if (text.trim().isEmpty) return '';

    try {
      await checkConnectivity();

      String actualSourceLanguage = fromLanguage ?? 'en';

      if (_isOfflineMode && !kIsWeb) {
        if (fromLanguage == 'auto') {
          actualSourceLanguage = await _mlKitService.identifyLanguage(text);
          if (actualSourceLanguage == 'und') {
            return 'Offline: Language detection failed.';
          }
        }

        // Check if models are available before attempting translation
        final missingModels = await _mlKitService
            .getMissingModelsForTranslation(actualSourceLanguage, toLanguage);
        if (missingModels.isNotEmpty) {
          final names = missingModels
              .map((code) => supportedLanguages[code] ?? code)
              .join(', ');
          return 'Offline models needed: $names. '
              'Go to Settings → Offline Models to download.';
        }

        final result = await _mlKitService.translate(
          text: text,
          sourceLanguage: actualSourceLanguage,
          targetLanguage: toLanguage,
        );
        return result ?? 'Offline translation failed. Models may be corrupted.';
      } else {
        // Online: Use Hybrid Translation Service (chains to Gemini API)
        if (_hybridService == null) {
          return 'Translation Service not initialized';
        }

        debugPrint(
            'VoiceTranslationService: Using Gemini API (Online) - $actualSourceLanguage → $toLanguage');
        final result = await _hybridService!.translateText(
          sourceText: text,
          sourceLang: actualSourceLanguage,
          targetLang: toLanguage,
        );
        if (!result.success) {
          return result.error ?? 'Translation failed. Please try again.';
        }
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
      _currentTranscript = ''; // Clear to prevent duplicate processing
      notifyListeners();
    } catch (e) {
      _currentTranslatedText = 'Translation failed';
      _isTranslating = false;
      _currentTranscript = ''; // Clear to prevent duplicate processing
      notifyListeners();
    }
  }

  Future<void> speakText(String text, String languageCode,
      {bool slow = false}) async {
    try {
      final ttsLocale = _getLanguageCode(languageCode);
      final available = await isTtsAvailable(languageCode);
      if (!available) {
        final langName = supportedLanguages[languageCode] ?? languageCode;
        debugPrint('TTS not available for $langName ($ttsLocale)');
        _errorMessage = '$langName text-to-speech is not installed. '
            'Translation text is shown above. '
            'Install $langName TTS in your device settings to hear it spoken.';
        notifyListeners();
        return;
      }
      await _flutterTts.setLanguage(ttsLocale);
      await _flutterTts.setSpeechRate(slow ? 0.3 : 0.5);
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS error: $e');
    }
  }

  String _getLanguageCode(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'en-US';
      case 'es':
        return 'es-ES';
      case 'fr':
        return 'fr-FR';
      case 'de':
        return 'de-DE';
      case 'it':
        return 'it-IT';
      case 'pt':
        return 'pt-BR';
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
      case 'ur':
        return 'ur-PK';
      default:
        return 'en-US';
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
