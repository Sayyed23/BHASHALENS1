import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/accessibility_settings.dart';
import '../models/voice_command.dart';
import '../models/audio_feedback_config.dart';

/// Abstract interface for voice navigation functionality
abstract class VoiceNavigationService {
  /// Stream of voice commands being processed
  Stream<VoiceCommand> get commandStream;
  
  /// Start listening for voice commands
  Future<void> startListening();
  
  /// Stop listening for voice commands
  Future<void> stopListening();
  
  /// Execute a navigation command
  Future<void> executeNavigationCommand(VoiceCommand command);
  
  /// Execute page-specific commands
  Future<void> executePageSpecificCommand(VoiceCommand command, String currentPage);
  
  /// Provide audio feedback for commands
  Future<void> provideCommandFeedback(String message);
  
  /// List available commands for current context
  Future<void> listAvailableCommands(String context);
}

/// Abstract interface for audio feedback functionality
abstract class AudioFeedbackService {
  /// Speak text using TTS
  Future<void> speak(String text, {String? language});
  
  /// Announce page changes
  Future<void> announcePageChange(String pageName, String description);
  
  /// Announce button actions
  Future<void> announceButtonAction(String buttonName, String action);
  
  /// Announce error messages
  Future<void> announceError(String errorMessage);
  
  /// Announce success messages
  Future<void> announceSuccess(String successMessage);
  
  /// Control speech playback
  Future<void> pauseSpeech();
  Future<void> resumeSpeech();
  Future<void> stopSpeech();
  
  /// Configure TTS settings
  Future<void> setSpeechRate(double rate);
  Future<void> setSpeechPitch(double pitch);
  Future<void> setVoice(String voiceId);
  
  /// Get available voices
  List<dynamic> getAvailableVoices();
}

/// Abstract interface for visual accessibility functionality
abstract class VisualAccessibilityController {
  /// High contrast theme management
  Future<void> enableHighContrastMode();
  Future<void> disableHighContrastMode();
  ThemeData getHighContrastTheme();
  
  /// Text and sizing controls
  Future<void> setTextScale(double scale);
  Future<void> enableBoldText();
  Future<void> setTouchTargetSize(double minSize);
  
  /// Visual enhancement features
  Future<void> enableSimplifiedUI();
  Future<void> enableFocusIndicators();
  Future<void> enableColorBlindSupport();
  Future<void> reduceMotion();
}

/// Core accessibility controller that coordinates all accessibility features
class AccessibilityController extends ChangeNotifier {
  final VoiceNavigationService? _voiceNavigation;
  final AudioFeedbackService? _audioFeedback;
  final VisualAccessibilityController? _visualAccessibility;
  final SharedPreferences _preferences;
  
  AccessibilitySettings _settings = const AccessibilitySettings();
  
  AccessibilityController({
    required SharedPreferences preferences,
    VoiceNavigationService? voiceNavigation,
    AudioFeedbackService? audioFeedback,
    VisualAccessibilityController? visualAccessibility,
  }) : _preferences = preferences,
       _voiceNavigation = voiceNavigation,
       _audioFeedback = audioFeedback,
       _visualAccessibility = visualAccessibility {
    _loadSettings();
  }
  
  /// Current accessibility settings
  AccessibilitySettings get settings => _settings;
  
  /// Voice navigation service getter
  VoiceNavigationService? get voiceNavigation => _voiceNavigation;
  
  /// Audio feedback service getter
  AudioFeedbackService? get audioFeedback => _audioFeedback;
  
  /// Visual accessibility controller getter
  VisualAccessibilityController? get visualAccessibility => _visualAccessibility;
  
  /// Check if voice navigation is enabled
  bool get isVoiceNavigationEnabled => _settings.voiceNavigationEnabled;
  
  /// Check if audio feedback is enabled
  bool get isAudioFeedbackEnabled => _settings.audioFeedbackEnabled;
  
  /// Check if visual accessibility is enabled
  bool get isVisualAccessibilityEnabled => _settings.highContrastEnabled;
  
  /// Enable voice navigation
  Future<void> enableVoiceNavigation() async {
    _settings = _settings.copyWith(voiceNavigationEnabled: true);
    await _saveSettings();
    notifyListeners();
  }
  
  /// Disable voice navigation
  Future<void> disableVoiceNavigation() async {
    _settings = _settings.copyWith(voiceNavigationEnabled: false);
    await _saveSettings();
    notifyListeners();
  }
  
  /// Enable audio feedback
  Future<void> enableAudioFeedback() async {
    _settings = _settings.copyWith(audioFeedbackEnabled: true);
    await _saveSettings();
    notifyListeners();
  }
  
  /// Disable audio feedback
  Future<void> disableAudioFeedback() async {
    _settings = _settings.copyWith(audioFeedbackEnabled: false);
    await _saveSettings();
    notifyListeners();
  }
  
  /// Enable visual accessibility
  Future<void> enableVisualAccessibility() async {
    _settings = _settings.copyWith(highContrastEnabled: true);
    await _saveSettings();
    notifyListeners();
  }
  
  /// Disable visual accessibility
  Future<void> disableVisualAccessibility() async {
    _settings = _settings.copyWith(highContrastEnabled: false);
    await _saveSettings();
    notifyListeners();
  }
  
  /// Update accessibility settings
  Future<void> updateSettings(AccessibilitySettings newSettings) async {
    _settings = newSettings;
    await _saveSettings();
    notifyListeners();
  }
  
  /// Integration with existing themes
  void integrateWithExistingThemes() {
    // This method will be implemented to work with existing theme system
    // Preserving current theme preferences while adding accessibility enhancements
  }
  
  /// Preserve user preferences during migration
  void preserveUserPreferences() {
    // This method will handle migration from existing accessibility service
    // Ensuring user settings are maintained during the upgrade
  }
  
  /// Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final settingsJson = _preferences.getString('accessibility_settings');
      if (settingsJson != null) {
        _settings = AccessibilitySettings.fromJson(settingsJson);
      }
    } catch (e) {
      // If loading fails, use default settings
      _settings = const AccessibilitySettings();
    }
  }
  
  /// Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      await _preferences.setString('accessibility_settings', _settings.toJson());
    } catch (e) {
      // Handle save errors gracefully
      debugPrint('Failed to save accessibility settings: $e');
    }
  }
}

/// Dependency injection container for accessibility services
class AccessibilityServiceContainer {
  static AccessibilityServiceContainer? _instance;
  static AccessibilityServiceContainer get instance => _instance ??= AccessibilityServiceContainer._();
  
  AccessibilityServiceContainer._();
  
  VoiceNavigationService? _voiceNavigationService;
  AudioFeedbackService? _audioFeedbackService;
  VisualAccessibilityController? _visualAccessibilityController;
  AccessibilityController? _accessibilityController;
  
  /// Register voice navigation service
  void registerVoiceNavigationService(VoiceNavigationService service) {
    _voiceNavigationService = service;
  }
  
  /// Register audio feedback service
  void registerAudioFeedbackService(AudioFeedbackService service) {
    _audioFeedbackService = service;
  }
  
  /// Register visual accessibility controller
  void registerVisualAccessibilityController(VisualAccessibilityController controller) {
    _visualAccessibilityController = controller;
  }
  
  /// Get or create accessibility controller
  Future<AccessibilityController> getAccessibilityController() async {
    if (_accessibilityController == null) {
      final preferences = await SharedPreferences.getInstance();
      _accessibilityController = AccessibilityController(
        preferences: preferences,
        voiceNavigation: _voiceNavigationService,
        audioFeedback: _audioFeedbackService,
        visualAccessibility: _visualAccessibilityController,
      );
    }
    return _accessibilityController!;
  }
  
  /// Clear all registered services (for testing)
  void clear() {
    _voiceNavigationService = null;
    _audioFeedbackService = null;
    _visualAccessibilityController = null;
    _accessibilityController = null;
  }
}