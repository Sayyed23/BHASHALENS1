import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/accessibility_settings.dart';
import 'voice_navigation/voice_navigation_service.dart';
import 'audio_feedback/audio_feedback_service.dart' as audio;

// Re-export so consumers can use a single import
export 'voice_navigation/voice_navigation_service.dart'
    show VoiceNavigationService, VoiceNavigationController;

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
  final audio.AudioFeedbackService? _audioFeedback;
  final VisualAccessibilityController? _visualAccessibility;
  final SharedPreferences _preferences;

  AccessibilitySettings _settings = const AccessibilitySettings();
  ThemeMode _themeMode = ThemeMode.dark;

  AccessibilityController._({
    required SharedPreferences preferences,
    VoiceNavigationService? voiceNavigation,
    audio.AudioFeedbackService? audioFeedback,
    VisualAccessibilityController? visualAccessibility,
  })  : _preferences = preferences,
        _voiceNavigation = voiceNavigation,
        _audioFeedback = audioFeedback,
        _visualAccessibility = visualAccessibility;

  /// Async factory constructor that properly loads settings before returning
  static Future<AccessibilityController> create({
    required SharedPreferences preferences,
    VoiceNavigationService? voiceNavigation,
    audio.AudioFeedbackService? audioFeedback,
    VisualAccessibilityController? visualAccessibility,
  }) async {
    final controller = AccessibilityController._(
      preferences: preferences,
      voiceNavigation: voiceNavigation,
      audioFeedback: audioFeedback,
      visualAccessibility: visualAccessibility,
    );
    
    await controller._loadSettings();
    return controller;
  }

  /// Current accessibility settings
  AccessibilitySettings get settings => _settings;

  /// Voice navigation service getter
  VoiceNavigationService? get voiceNavigation => _voiceNavigation;

  /// Audio feedback service getter
  audio.AudioFeedbackService? get audioFeedback => _audioFeedback;

  /// Visual accessibility controller getter
  VisualAccessibilityController? get visualAccessibility =>
      _visualAccessibility;

  /// Check if voice navigation is enabled
  bool get isVoiceNavigationEnabled => _settings.voiceNavigationEnabled;

  /// Check if audio feedback is enabled
  bool get isAudioFeedbackEnabled => _settings.audioFeedbackEnabled;

  /// Check if visual accessibility is enabled
  bool get isVisualAccessibilityEnabled => _settings.highContrastEnabled;

  /// Backwards compatibility with old AccessibilityService
  double get textSizeFactor => _settings.textScale;
  ThemeMode get themeMode => _themeMode;

  void setTextSizeFactor(double factor) {
    if (factor > 0) {
      updateSettings(_settings.copyWith(textScale: factor));
    }
  }

  void toggleThemeMode() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _preferences.setString('theme_mode', _themeMode.toString());
    notifyListeners();
  }

  /// Enable voice navigation — delegates to the actual service
  Future<void> enableVoiceNavigation() async {
    try {
      final voiceNav = _voiceNavigation;
      if (voiceNav != null) {
        await voiceNav.enableVoiceNavigation();
        // Wire audio feedback so voice nav commands produce TTS output
        final feedback = _audioFeedback;
        if (feedback != null && voiceNav is VoiceNavigationController) {
          voiceNav.setAudioFeedbackCallback(
            (message, {String? language}) async {
              await feedback.speak(message, language: language);
            },
          );
        }
      }
      _settings = _settings.copyWith(voiceNavigationEnabled: true);
      await _saveSettings();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to enable voice navigation: $e');
      rethrow;
    }
  }

  /// Disable voice navigation — delegates to the actual service
  Future<void> disableVoiceNavigation() async {
    try {
      final voiceNav = _voiceNavigation;
      if (voiceNav != null) {
        await voiceNav.disableVoiceNavigation();
      }
    } catch (e) {
      debugPrint('Failed to disable voice navigation: $e');
    }
    _settings = _settings.copyWith(voiceNavigationEnabled: false);
    await _saveSettings();
    notifyListeners();
  }

  /// Enable audio feedback — initializes the TTS service
  Future<void> enableAudioFeedback() async {
    try {
      final feedback = _audioFeedback;
      if (feedback != null) {
        await feedback.initialize(_settings);
      }
    } catch (e) {
      debugPrint('Failed to initialize audio feedback: $e');
    }
    _settings = _settings.copyWith(audioFeedbackEnabled: true);
    await _saveSettings();
    notifyListeners();
  }

  /// Disable audio feedback — stops TTS
  Future<void> disableAudioFeedback() async {
    try {
      final feedback = _audioFeedback;
      if (feedback != null) {
        await feedback.stopSpeech();
      }
    } catch (e) {
      debugPrint('Failed to stop audio feedback: $e');
    }
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

  /// Load settings from SharedPreferences and restore services
  Future<void> _loadSettings() async {
    try {
      final settingsJson = _preferences.getString('accessibility_settings');
      if (settingsJson != null) {
        _settings = AccessibilitySettings.fromJson(settingsJson);
      }
      final themeStr = _preferences.getString('theme_mode');
      if (themeStr != null) {
        _themeMode = themeStr == ThemeMode.light.toString() ? ThemeMode.light : ThemeMode.dark;
      }
    } catch (e) {
      // If loading fails, use default settings
      _settings = const AccessibilitySettings();
    }

    // Restore services that were previously enabled
    await _restoreServices();
  }

  /// Re-enable services that were enabled in persisted settings
  Future<void> _restoreServices() async {
    try {
      final feedback = _audioFeedback;
      if (_settings.audioFeedbackEnabled && feedback != null) {
        await feedback.initialize(_settings);
        debugPrint('Audio feedback service restored from saved settings');
      }
      final voiceNav = _voiceNavigation;
      if (_settings.voiceNavigationEnabled && voiceNav != null) {
        await voiceNav.enableVoiceNavigation();
        // Wire audio feedback callback
        if (feedback != null && voiceNav is VoiceNavigationController) {
          voiceNav.setAudioFeedbackCallback(
            (message, {String? language}) async {
              await feedback.speak(message, language: language);
            },
          );
        }
        debugPrint('Voice navigation service restored from saved settings');
      }
    } catch (e) {
      debugPrint('Error restoring accessibility services: $e');
    }
  }

  /// Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      await _preferences.setString(
          'accessibility_settings', _settings.toJson());
    } catch (e) {
      // Handle save errors gracefully
      debugPrint('Failed to save accessibility settings: $e');
    }
  }
}

/// Dependency injection container for accessibility services
class AccessibilityServiceContainer {
  static AccessibilityServiceContainer? _instance;
  static AccessibilityServiceContainer get instance =>
      _instance ??= AccessibilityServiceContainer._();

  AccessibilityServiceContainer._();

  VoiceNavigationService? _voiceNavigationService;
  audio.AudioFeedbackService? _audioFeedbackService;
  VisualAccessibilityController? _visualAccessibilityController;
  AccessibilityController? _accessibilityController;
  Completer<AccessibilityController>? _accessibilityControllerCompleter;

  /// Register voice navigation service
  void registerVoiceNavigationService(VoiceNavigationService service) {
    _voiceNavigationService = service;
  }

  /// Register audio feedback service
  void registerAudioFeedbackService(audio.AudioFeedbackService service) {
    _audioFeedbackService = service;
  }

  /// Register visual accessibility controller
  void registerVisualAccessibilityController(
      VisualAccessibilityController controller) {
    _visualAccessibilityController = controller;
  }

  /// Get or create accessibility controller
  Future<AccessibilityController> getAccessibilityController() async {
    // If already created, return it immediately
    if (_accessibilityController != null) {
      return _accessibilityController!;
    }

    // If creation is in progress, wait for it
    if (_accessibilityControllerCompleter != null) {
      return _accessibilityControllerCompleter!.future;
    }

    // Start creation process
    _accessibilityControllerCompleter = Completer<AccessibilityController>();
    final completer = _accessibilityControllerCompleter!;

    try {
      final preferences = await SharedPreferences.getInstance();
      final controller = await AccessibilityController.create(
        preferences: preferences,
        voiceNavigation: _voiceNavigationService,
        audioFeedback: _audioFeedbackService,
        visualAccessibility: _visualAccessibilityController,
      );

      _accessibilityController = controller;
      completer.complete(controller);
      return controller;
    } catch (error) {
      completer.completeError(error);
      _accessibilityControllerCompleter = null;
      rethrow;
    }
  }

  /// Clear all registered services (for testing)
  void clear() {
    _voiceNavigationService = null;
    _audioFeedbackService = null;
    _visualAccessibilityController = null;
    _accessibilityController?.dispose();
    _accessibilityController = null;
    _accessibilityControllerCompleter = null;
  }
}
