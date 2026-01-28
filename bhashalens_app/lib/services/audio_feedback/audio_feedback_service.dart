import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../../models/accessibility_settings.dart';
import '../../../models/audio_feedback_config.dart';
import 'tts_engine.dart';

/// Priority levels for audio feedback
enum FeedbackPriority {
  low, // Background notifications, non-critical info
  normal, // Standard UI feedback, button presses
  high, // Important messages, errors, success notifications
  critical, // Emergency messages, system alerts
}

/// Types of audio feedback
enum FeedbackType {
  pageChange,
  buttonPress,
  uiElement,
  translation,
  error,
  success,
  systemMessage,
  help,
}

/// Audio feedback request
class FeedbackRequest {
  final String text;
  final FeedbackType type;
  final FeedbackPriority priority;
  final String? language;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  FeedbackRequest({
    required this.text,
    required this.type,
    this.priority = FeedbackPriority.normal,
    this.language,
    this.metadata,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'FeedbackRequest(text: $text, type: $type, priority: $priority, language: $language)';
  }
}

/// Abstract interface for audio feedback service
abstract class AudioFeedbackService {
  /// Current accessibility settings
  AccessibilitySettings get settings;

  /// Whether audio feedback is enabled
  bool get isEnabled;

  /// Whether TTS is currently speaking
  bool get isSpeaking;

  /// Stream of TTS state changes
  Stream<TtsState> get ttsStateStream;

  /// Initialize the service
  Future<void> initialize(AccessibilitySettings settings);

  /// Update settings
  Future<void> updateSettings(AccessibilitySettings settings);

  /// Dispose the service
  Future<void> dispose();

  // Core TTS functionality
  /// Speak text with optional language
  Future<void> speak(String text,
      {String? language, FeedbackPriority priority = FeedbackPriority.normal});

  /// Stop current speech
  Future<void> stopSpeech();

  /// Pause current speech
  Future<void> pauseSpeech();

  /// Resume paused speech
  Future<void> resumeSpeech();

  // UI Element Announcements
  /// Announce page change
  Future<void> announcePageChange(String pageName, {String? description});

  /// Announce button action
  Future<void> announceButtonAction(String buttonId,
      {String? customDescription});

  /// Announce UI element focus
  Future<void> announceUIElement(String elementDescription,
      {FeedbackPriority priority = FeedbackPriority.normal});

  /// Announce translation result
  Future<void> announceTranslation(String originalText, String translatedText,
      {String? sourceLanguage, String? targetLanguage});

  // System Messages
  /// Announce error message
  Future<void> announceError(String errorType, {String? customMessage});

  /// Announce success message
  Future<void> announceSuccess(String successType, {String? customMessage});

  /// Announce system message
  Future<void> announceSystemMessage(String message,
      {FeedbackPriority priority = FeedbackPriority.high});

  // Help and Guidance
  /// Announce help information
  Future<void> announceHelp(String helpText);

  /// Announce available commands or options
  Future<void> announceAvailableOptions(List<String> options);

  // Settings and Control
  /// Set speech rate
  Future<void> setSpeechRate(double rate);

  /// Set speech pitch
  Future<void> setSpeechPitch(double pitch);

  /// Set preferred voice
  Future<void> setVoice(String voiceName);

  /// Get available voices
  Future<List<Voice>> getAvailableVoices();

  /// Get available languages
  Future<List<String>> getAvailableLanguages();
}

/// Implementation of audio feedback service
class AudioFeedbackManager implements AudioFeedbackService {
  final TtsEngine _ttsEngine;
  final AudioFeedbackConfig _config;

  AccessibilitySettings _settings;
  final StreamController<String> _feedbackController =
      StreamController<String>.broadcast();
  final List<FeedbackRequest> _feedbackQueue = [];
  bool _isProcessingQueue = false;
  Timer? _queueTimer;

  AudioFeedbackManager({
    required TtsEngine ttsEngine,
    AudioFeedbackConfig? config,
    AccessibilitySettings? settings,
  })  : _ttsEngine = ttsEngine,
        _config = config ?? AudioFeedbackConfig.defaultConfig,
        _settings = settings ?? const AccessibilitySettings();

  @override
  AccessibilitySettings get settings => _settings;

  @override
  bool get isEnabled => _settings.audioFeedbackEnabled;

  @override
  bool get isSpeaking => _ttsEngine.state == TtsState.playing;

  @override
  Stream<TtsState> get ttsStateStream => _ttsEngine.stateStream;

  /// Stream of feedback messages for debugging
  Stream<String> get feedbackStream => _feedbackController.stream;

  @override
  Future<void> initialize(AccessibilitySettings settings) async {
    try {
      _settings = settings;
      await _ttsEngine.initialize();
      await _applyTtsSettings();

      // Start queue processing
      _startQueueProcessing();

      if (kDebugMode) {
        print('AudioFeedbackManager initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AudioFeedbackManager initialization failed: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> updateSettings(AccessibilitySettings settings) async {
    _settings = settings;
    await _applyTtsSettings();

    if (kDebugMode) {
      print('AudioFeedbackManager settings updated');
    }
  }

  @override
  Future<void> dispose() async {
    _queueTimer?.cancel();
    await _feedbackController.close();
    await _ttsEngine.dispose();

    if (kDebugMode) {
      print('AudioFeedbackManager disposed');
    }
  }

  @override
  Future<void> speak(String text,
      {String? language,
      FeedbackPriority priority = FeedbackPriority.normal}) async {
    if (!isEnabled || text.trim().isEmpty) return;

    final request = FeedbackRequest(
      text: text,
      type: FeedbackType.systemMessage,
      priority: priority,
      language: language,
    );

    await _queueFeedback(request);
  }

  @override
  Future<void> stopSpeech() async {
    await _ttsEngine.stop();
    _feedbackQueue.clear();
  }

  @override
  Future<void> pauseSpeech() async {
    await _ttsEngine.pause();
  }

  @override
  Future<void> resumeSpeech() async {
    await _ttsEngine.resume();
  }

  @override
  Future<void> announcePageChange(String pageName,
      {String? description}) async {
    if (!isEnabled) return;

    String announcement = description ??
        _config.getPageAnnouncement(pageName) ??
        'Page changed to $pageName';

    final request = FeedbackRequest(
      text: announcement,
      type: FeedbackType.pageChange,
      priority: FeedbackPriority.high,
      metadata: {'pageName': pageName},
    );

    await _queueFeedback(request);
  }

  @override
  Future<void> announceButtonAction(String buttonId,
      {String? customDescription}) async {
    if (!isEnabled) return;

    String announcement = customDescription ??
        _config.getButtonDescription(buttonId) ??
        'Button $buttonId activated';

    final request = FeedbackRequest(
      text: announcement,
      type: FeedbackType.buttonPress,
      priority: FeedbackPriority.normal,
      metadata: {'buttonId': buttonId},
    );

    await _queueFeedback(request);
  }

  @override
  Future<void> announceUIElement(String elementDescription,
      {FeedbackPriority priority = FeedbackPriority.normal}) async {
    if (!isEnabled) return;

    final request = FeedbackRequest(
      text: elementDescription,
      type: FeedbackType.uiElement,
      priority: priority,
    );

    await _queueFeedback(request);
  }

  @override
  Future<void> announceTranslation(String originalText, String translatedText,
      {String? sourceLanguage, String? targetLanguage}) async {
    if (!isEnabled || !_settings.autoReadTranslations) return;

    String announcement;
    if (sourceLanguage != null && targetLanguage != null) {
      announcement =
          'Translation from $sourceLanguage to $targetLanguage: $translatedText';
    } else {
      announcement = 'Translation: $translatedText';
    }

    final request = FeedbackRequest(
      text: announcement,
      type: FeedbackType.translation,
      priority: FeedbackPriority.high,
      language: targetLanguage,
      metadata: {
        'originalText': originalText,
        'translatedText': translatedText,
        'sourceLanguage': sourceLanguage,
        'targetLanguage': targetLanguage,
      },
    );

    await _queueFeedback(request);
  }

  @override
  Future<void> announceError(String errorType, {String? customMessage}) async {
    if (!isEnabled || !_settings.autoReadErrors) return;

    String announcement = customMessage ??
        _config.getErrorMessage(errorType) ??
        'Error: $errorType';

    final request = FeedbackRequest(
      text: announcement,
      type: FeedbackType.error,
      priority: FeedbackPriority.high,
      metadata: {'errorType': errorType},
    );

    await _queueFeedback(request);
  }

  @override
  Future<void> announceSuccess(String successType,
      {String? customMessage}) async {
    if (!isEnabled) return;

    String announcement = customMessage ??
        _config.getSuccessMessage(successType) ??
        'Success: $successType';

    final request = FeedbackRequest(
      text: announcement,
      type: FeedbackType.success,
      priority: FeedbackPriority.normal,
      metadata: {'successType': successType},
    );

    await _queueFeedback(request);
  }

  @override
  Future<void> announceSystemMessage(String message,
      {FeedbackPriority priority = FeedbackPriority.high}) async {
    if (!isEnabled) return;

    final request = FeedbackRequest(
      text: message,
      type: FeedbackType.systemMessage,
      priority: priority,
    );

    await _queueFeedback(request);
  }

  @override
  Future<void> announceHelp(String helpText) async {
    if (!isEnabled) return;

    final request = FeedbackRequest(
      text: helpText,
      type: FeedbackType.help,
      priority: FeedbackPriority.high,
    );

    await _queueFeedback(request);
  }

  @override
  Future<void> announceAvailableOptions(List<String> options) async {
    if (!isEnabled || options.isEmpty) return;

    String announcement;
    if (options.length == 1) {
      announcement = 'Available option: ${options.first}';
    } else {
      announcement = 'Available options: ${options.join(', ')}';
    }

    final request = FeedbackRequest(
      text: announcement,
      type: FeedbackType.help,
      priority: FeedbackPriority.normal,
      metadata: {'options': options},
    );

    await _queueFeedback(request);
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    await _ttsEngine.setSpeechRate(rate);
    _settings = _settings.copyWith(speechRate: rate);
  }

  @override
  Future<void> setSpeechPitch(double pitch) async {
    await _ttsEngine.setSpeechPitch(pitch);
    _settings = _settings.copyWith(speechPitch: pitch);
  }

  @override
  Future<void> setVoice(String voiceName) async {
    await _ttsEngine.setVoice(voiceName);
    _settings = _settings.copyWith(preferredVoice: voiceName);
  }

  @override
  Future<List<Voice>> getAvailableVoices() async {
    return await _ttsEngine.getVoices();
  }

  @override
  Future<List<String>> getAvailableLanguages() async {
    return await _ttsEngine.getLanguages();
  }

  /// Apply TTS settings from accessibility settings
  Future<void> _applyTtsSettings() async {
    try {
      await _ttsEngine.setSpeechRate(_settings.speechRate);
      await _ttsEngine.setSpeechPitch(_settings.speechPitch);

      if (_settings.preferredVoice != 'default') {
        await _ttsEngine.setVoice(_settings.preferredVoice);
      }

      if (kDebugMode) {
        print(
            'TTS settings applied: rate=${_settings.speechRate}, pitch=${_settings.speechPitch}, voice=${_settings.preferredVoice}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to apply TTS settings: $e');
      }
    }
  }

  /// Queue feedback request for processing
  Future<void> _queueFeedback(FeedbackRequest request) async {
    // Handle critical priority immediately
    if (request.priority == FeedbackPriority.critical) {
      await _processFeedback(request);
      return;
    }

    // Add to queue based on priority
    if (request.priority == FeedbackPriority.high) {
      // Insert high priority items at the beginning
      _feedbackQueue.insert(0, request);
    } else {
      // Add normal and low priority items at the end
      _feedbackQueue.add(request);
    }

    // Limit queue size to prevent memory issues
    if (_feedbackQueue.length > 50) {
      // Remove excess low-priority items from the end
      _feedbackQueue.removeRange(50, _feedbackQueue.length);
    }
    _feedbackController.add('Queued: ${request.text}');
  }

  /// Start processing the feedback queue
  void _startQueueProcessing() {
    _queueTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _processQueue();
    });
  }

  /// Process the feedback queue
  Future<void> _processQueue() async {
    if (_isProcessingQueue || _feedbackQueue.isEmpty || isSpeaking) {
      return;
    }

    _isProcessingQueue = true;

    try {
      final request = _feedbackQueue.removeAt(0);
      await _processFeedback(request);
    } catch (e) {
      if (kDebugMode) {
        print('Error processing feedback queue: $e');
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  /// Process a single feedback request
  Future<void> _processFeedback(FeedbackRequest request) async {
    try {
      // Determine language for TTS
      String? language = request.language;
      if (language == null && request.type == FeedbackType.translation) {
        // Try to detect language from the text
        if (_ttsEngine is FlutterTtsEngine) {
          language = (_ttsEngine).detectLanguage(request.text);
        }
      }

      // Speak the text
      await _ttsEngine.speak(request.text, language: language);

      _feedbackController.add('Spoken: ${request.text}');

      if (kDebugMode) {
        print(
            'Audio feedback: ${request.text} (${request.type}, ${request.priority})');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error processing feedback: $e');
      }
      _feedbackController.add('Error: ${request.text}');
    }
  }

  /// Clear the feedback queue
  void clearQueue() {
    _feedbackQueue.clear();
    _feedbackController.add('Queue cleared');
  }

  /// Get current queue size
  int get queueSize => _feedbackQueue.length;

  /// Get queue contents for debugging
  List<FeedbackRequest> get queueContents => List.unmodifiable(_feedbackQueue);
}

/// Audio feedback service factory
class AudioFeedbackServiceFactory {
  static AudioFeedbackService create({
    TtsEngine? ttsEngine,
    AudioFeedbackConfig? config,
    AccessibilitySettings? settings,
  }) {
    return AudioFeedbackManager(
      ttsEngine: ttsEngine ?? FlutterTtsEngine(),
      config: config,
      settings: settings,
    );
  }
}
